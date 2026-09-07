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

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
STARTUP_SCRIPT="${ROOT_DIR}/build/bin/docker-startup.sh"
APPLICATION_PROPERTIES="${ROOT_DIR}/build/conf/application.properties"
TEST_DIR=$(mktemp -d)
trap 'rm -rf "${TEST_DIR}"' EXIT

assert_property() {
  local expected=$1
  if ! grep -Fqx "${expected}" "${APPLICATION_PROPERTIES}"; then
    echo "Expected ${APPLICATION_PROPERTIES} to contain: ${expected}" >&2
    exit 1
  fi
}

assert_property "nacos.core.auth.enabled=true"
assert_property "nacos.core.auth.admin.enabled=true"
assert_property "nacos.core.auth.console.enabled=true"

FAKE_JAVA="${TEST_DIR}/java"
JAVA_ARGS_FILE="${TEST_DIR}/java-args"

printf '%s\n' \
  '#!/usr/bin/env bash' \
  'if [[ "${1:-}" == "-version" ]]; then' \
  '  echo '\''openjdk version "17.0.0"'\'' >&2' \
  '  exit 0' \
  'fi' \
  'printf '\''%s\n'\'' "$@" > "${JAVA_ARGS_FILE}"' \
  > "${FAKE_JAVA}"
chmod +x "${FAKE_JAVA}"

run_startup() {
  local auth_value=${1-}
  : > "${JAVA_ARGS_FILE}"
  (
    export BASE_DIR="${TEST_DIR}/nacos"
    export JAVA="${FAKE_JAVA}"
    export JAVA_ARGS_FILE
    export MODE=standalone
    export NACOS_AUTH_TOKEN=test-token
    export NACOS_AUTH_IDENTITY_KEY=test-key
    export NACOS_AUTH_IDENTITY_VALUE=test-value
    if [[ $# -eq 0 ]]; then
      unset NACOS_AUTH_ENABLE
    else
      export NACOS_AUTH_ENABLE="${auth_value}"
    fi
    bash "${STARTUP_SCRIPT}" >/dev/null 2>&1
  )
}

run_startup
if grep -Fq -- "-Dnacos.core.auth.enabled=" "${JAVA_ARGS_FILE}"; then
  echo "Unset NACOS_AUTH_ENABLE must not add a JVM override" >&2
  exit 1
fi

for auth_value in true false; do
  run_startup "${auth_value}"
  if ! grep -Fqx -- "-Dnacos.core.auth.enabled=${auth_value}" "${JAVA_ARGS_FILE}"; then
    echo "NACOS_AUTH_ENABLE=${auth_value} must be preserved as a JVM override" >&2
    exit 1
  fi
done

echo "Auth defaults and NACOS_AUTH_ENABLE tri-state behavior are valid."
