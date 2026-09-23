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
TEST_DIR=$(mktemp -d)
trap 'rm -rf "${TEST_DIR}"' EXIT
mkdir -p "${TEST_DIR}/bin" "${TEST_DIR}/example"
cp "${ROOT_DIR}/example/mysql-init.sh" "${TEST_DIR}/example/"
cat > "${TEST_DIR}/bin/curl" <<'CURL'
#!/usr/bin/env bash
set -eu
url= output=
while [[ $# -gt 0 ]]; do
  case "$1" in
    https://*) url=$1 ;;
    -o) shift; output=$1 ;;
  esac
  shift
done
printf '%s\n' "$url" >> "$REQUEST_LOG"
if [[ "${FAIL_ALL:-false}" == true ]] || { [[ "${FALLBACK:-false}" == true ]] && [[ "$url" == *plugin-default-impl* ]]; }; then
  printf partial > "$output"
  exit 22
fi
if [[ "${EMPTY_DOWNLOAD:-false}" == true ]]; then
  : > "$output"
  exit 0
fi
printf '%s\n' "$url" > "$output"
CURL
chmod +x "${TEST_DIR}/bin/curl"
export PATH="${TEST_DIR}/bin:${PATH}"
export REQUEST_LOG="${TEST_DIR}/requests"
NEW_PATH=plugin-default-impl/nacos-default-datasource-plugin/nacos-datasource-plugin-mysql/src/main/resources/META-INF/mysql-schema.sql
OLD_PATH=distribution/conf/mysql-schema.sql

# .env must retain its original precedence over an inherited environment variable.
export NACOS_VERSION=v0.0.0
cases=0
while read -r tag expected; do
  printf 'NACOS_VERSION=%s\n' "$tag" > "${TEST_DIR}/example/.env"
  new_url="https://raw.githubusercontent.com/alibaba/nacos/${expected}/${NEW_PATH}"
  old_url="https://raw.githubusercontent.com/alibaba/nacos/${expected}/${OLD_PATH}"
  for fallback in false true; do
    : > "$REQUEST_LOG"
    # Invoke from another directory: paths must still resolve next to the script.
    (cd /; FALLBACK=$fallback bash "${TEST_DIR}/example/mysql-init.sh" >/dev/null)
    if [[ "$fallback" == true ]]; then
      printf '%s\n%s\n' "$new_url" "$old_url" > "${TEST_DIR}/expected-requests"
      printf '%s\n' "$old_url" > "${TEST_DIR}/expected-schema"
    else
      printf '%s\n' "$new_url" > "${TEST_DIR}/expected-requests"
      printf '%s\n' "$new_url" > "${TEST_DIR}/expected-schema"
    fi
    cmp "${TEST_DIR}/expected-requests" "$REQUEST_LOG"
    cmp "${TEST_DIR}/expected-schema" "${TEST_DIR}/example/mysql-init/mysql-schema.sql"
    cases=$((cases + 1))
  done
done <<'VERSIONS'
v3.3.0 3.3.0
3.3.0 3.3.0
v3.3.0-slim 3.3.0
v2.2.0.1 2.2.0.1
v2.4.2.1-slim 2.4.2.1
v3.3.0.a 3.3.0.a
v3.3.0.a-slim 3.3.0.a
v3.3.0-alpha 3.3.0-alpha
v2.0.0-ALPHA.1-slim 2.0.0-ALPHA.1
v3.3.0-beta 3.3.0-beta
v3.2.0-BETA-slim 3.2.0-BETA
v3.2.0-BETA.1-slim 3.2.0-BETA.1
v3.3.0-RC 3.3.0-RC
v3.3.0-RC-slim 3.3.0-RC
v3.3.0-rc.1-slim 3.3.0-rc.1
v3.1.0-bugfix 3.1.0-bugfix
v3.1.0-bugfix-slim 3.1.0-bugfix
v3.2.1-2026.03.30-slim 3.2.1-2026.03.30
v3.3.0-hotfix-2026.09.23 3.3.0-hotfix-2026.09.23
v3.3.0-hotfix-2026.09.23-slim 3.3.0-hotfix-2026.09.23
v3.3.0-lite 3.3.0-lite
VERSIONS

# Neither a failed download nor a successful but empty response may replace SQL.
printf 'NACOS_VERSION=v3.3.0-RC\n' > "${TEST_DIR}/example/.env"
cp "${TEST_DIR}/example/mysql-init/mysql-schema.sql" "${TEST_DIR}/previous.sql"
for failure in failed empty fallback-empty; do
  FAIL_ALL=false EMPTY_DOWNLOAD=false FALLBACK=false
  case "$failure" in
    failed) FAIL_ALL=true ;;
    empty) EMPTY_DOWNLOAD=true ;;
    fallback-empty) FALLBACK=true; EMPTY_DOWNLOAD=true ;;
  esac
  export FAIL_ALL EMPTY_DOWNLOAD FALLBACK
  if bash "${TEST_DIR}/example/mysql-init.sh" >/dev/null 2>&1; then
    echo "${failure} download must return an error" >&2
    exit 1
  fi
  cmp "${TEST_DIR}/previous.sql" "${TEST_DIR}/example/mysql-init/mysql-schema.sql"
done
shopt -s nullglob
leftovers=("${TEST_DIR}/example/mysql-init/".mysql-schema.*)
[[ ${#leftovers[@]} -eq 0 ]]
echo "${cases} version/path cases passed; .env precedence, download failure preservation and cleanup are valid."
