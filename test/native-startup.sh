#!/usr/bin/env bash
# Copyright 1999-2026 Alibaba Group Holding Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Tests build/bin/docker-native-startup.sh with stand-in Native layouts. The stand-in executable prints
# the arguments and the datasource it receives, so the checks cover what the entrypoint passes to the
# executable and which environments it refuses. The real Native executable is not run here.
# Usage: bash test/native-startup.sh

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ENTRYPOINT="${ROOT_DIR}/build/bin/docker-native-startup.sh"
TEST_DIR=$(mktemp -d)
trap 'rm -rf "${TEST_DIR}"' EXIT

# make_home DIR MANIFEST_LINE... writes a stand-in archive layout under DIR.
make_home() {
  local home=$1
  shift
  mkdir -p "${home}/target" "${home}/conf"
  printf '%s\n' "$@" > "${home}/target/aot-manifest.properties"
  cat > "${home}/target/nacos-server" <<'EOF'
#!/bin/bash
for argument in "$@"; do
  printf 'arg=%s\n' "${argument}"
done
printf 'env.SPRING_DATASOURCE_PLATFORM=%s\n' "${SPRING_DATASOURCE_PLATFORM:-}"
exit "${STUB_EXIT:-0}"
EOF
  chmod +x "${home}/target/nacos-server"
}

# run_entrypoint HOME [NAME=value...] runs the entrypoint with a clean environment and records its
# output in OUTPUT and its exit status in STATUS. The authentication variables are set unless overridden.
run_entrypoint() {
  local home=$1
  shift
  set +e
  OUTPUT=$(env -i PATH="${PATH}" BASE_DIR="${home}" \
    NACOS_AUTH_TOKEN=test-token \
    NACOS_AUTH_IDENTITY_KEY=test-key \
    NACOS_AUTH_IDENTITY_VALUE=test-value \
    "$@" bash "${ENTRYPOINT}" 2>&1)
  STATUS=$?
  set -e
}

fail() {
  echo "FAIL: $*" >&2
  echo "--- exit status ${STATUS:-unknown}, output:" >&2
  echo "${OUTPUT:-}" >&2
  exit 1
}

expect_line() {
  grep -qxF -- "$1" <<< "${OUTPUT}" || fail "expected output line: $1"
}

expect_status() {
  [[ "${STATUS}" == "$1" ]] || fail "expected exit status $1"
}

expect_message() {
  grep -qF -- "$1" <<< "${OUTPUT}" || fail "expected message: $1"
}

MERGED_MYSQL=(standalone=true deployment=merged datasource=mysql embeddedStorage=false functionMode=All)

# A standalone MySQL archive: the flags come from the manifest and reach the executable in order.
HOME_MYSQL="${TEST_DIR}/mysql"
make_home "${HOME_MYSQL}" "${MERGED_MYSQL[@]}"
run_entrypoint "${HOME_MYSQL}" NACOS_NATIVE_OPTS='-Xmx1g -Dsample=true' STUB_EXIT=0
expect_status 0
expect_line "arg=-Xmx1g"
expect_line "arg=-Dsample=true"
expect_line "arg=-Dnacos.home=${HOME_MYSQL}"
expect_line "arg=-Dnacos.standalone=true"
expect_line "arg=-Dnacos.deployment.type=merged"
expect_line "arg=-DembeddedStorage=false"
expect_line "arg=-Dspring.config.additional-location=file:${HOME_MYSQL}/conf/"
expect_line "arg=-Dlogging.config=${HOME_MYSQL}/conf/nacos-logback.xml"
expect_line "arg=nacos.nacos"
expect_line "env.SPRING_DATASOURCE_PLATFORM=mysql"
if grep -q 'functionMode' <<< "${OUTPUT}"; then
  fail "function mode All must not pass -Dnacos.functionMode"
fi

# Values that agree with the manifest are accepted, whatever their case.
run_entrypoint "${HOME_MYSQL}" SPRING_DATASOURCE_PLATFORM=MySQL MODE=Standalone FUNCTION_MODE=ALL
expect_status 0
expect_line "env.SPRING_DATASOURCE_PLATFORM=mysql"

# The exit status of the executable is the status of the container.
run_entrypoint "${HOME_MYSQL}" STUB_EXIT=7
expect_status 7

# A cluster PostgreSQL archive with a fixed function mode.
HOME_CLUSTER="${TEST_DIR}/cluster"
make_home "${HOME_CLUSTER}" standalone=false deployment=merged datasource=postgresql embeddedStorage=false functionMode=config
run_entrypoint "${HOME_CLUSTER}"
expect_status 0
expect_line "arg=-Dnacos.standalone=false"
expect_line "arg=-Dnacos.functionMode=config"
expect_line "env.SPRING_DATASOURCE_PLATFORM=postgresql"
run_entrypoint "${HOME_CLUSTER}" MODE=cluster NACOS_DEPLOYMENT_TYPE=MERGED FUNCTION_MODE=config
expect_status 0

# Optional environment variables become system properties.
run_entrypoint "${HOME_MYSQL}" PREFER_HOST_MODE=hostname NACOS_SERVER_IP=10.0.0.8 NACOS_AUTH_ENABLE=true
expect_status 0
expect_line "arg=-Dnacos.preferHostnameOverIp=true"
expect_line "arg=-Dnacos.server.ip=10.0.0.8"
expect_line "arg=-Dnacos.core.auth.enabled=true"

# Refusals, each before the executable starts.
run_entrypoint "${HOME_MYSQL}" NACOS_AUTH_TOKEN=
expect_status 255
expect_message "env NACOS_AUTH_TOKEN must be set"

run_entrypoint "${HOME_MYSQL}" NACOS_AUTH_IDENTITY_VALUE=
expect_status 255
expect_message "env NACOS_AUTH_IDENTITY_VALUE must be set"

run_entrypoint "${HOME_MYSQL}" SPRING_DATASOURCE_PLATFORM=postgresql
expect_status 1
expect_message "does not match this executable, which was built for datasource mysql"

run_entrypoint "${HOME_MYSQL}" MODE=cluster
expect_status 1
expect_message "MODE=cluster does not match this executable"

run_entrypoint "${HOME_CLUSTER}" MODE=standalone
expect_status 1
expect_message "MODE=standalone does not match this executable"

run_entrypoint "${HOME_MYSQL}" MODE=federation
expect_status 1
expect_message "Invalid MODE=federation"

run_entrypoint "${HOME_MYSQL}" FUNCTION_MODE=naming
expect_status 1
expect_message "FUNCTION_MODE=naming does not match this executable"

run_entrypoint "${HOME_MYSQL}" NACOS_DEPLOYMENT_TYPE=console
expect_status 1
expect_message "NACOS_DEPLOYMENT_TYPE=console does not match this executable"

HOME_PARTIAL="${TEST_DIR}/partial"
make_home "${HOME_PARTIAL}" standalone=true deployment=merged embeddedStorage=false functionMode=All
run_entrypoint "${HOME_PARTIAL}"
expect_status 1
expect_message "The AOT manifest has no datasource"

run_entrypoint "${TEST_DIR}/missing"
expect_status 1
expect_message "Missing Native executable or AOT manifest"

echo "native-startup tests passed"
