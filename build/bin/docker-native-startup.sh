#!/bin/bash
# Copyright 1999-2026 Alibaba Group Holding Ltd.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Entrypoint of the Native Server image (build/Dockerfile.Native). It runs the Native executable of
# the archive in the foreground, as PID 1, so that docker stop reaches Nacos directly. The archive's
# bin/startup-native.sh starts the executable in the background and is not used.
#
# The datasource, the standalone or cluster choice, the deployment, the function mode and the
# embedded storage are fixed when the executable is built. They are recorded in
# target/aot-manifest.properties. This script takes them from the manifest and refuses an environment
# that disagrees with it, before the executable starts, so the reason is printed here.

set -euo pipefail

BASE_DIR="${BASE_DIR:-/home/nacos}"
NACOS_SERVER="${BASE_DIR}/target/nacos-server"
MANIFEST="${BASE_DIR}/target/aot-manifest.properties"

lower() {
  tr '[:upper:]' '[:lower:]' <<< "$1"
}

fail() {
  echo "$1" >&2
  exit 1
}

# manifest_value KEY prints the lower-cased value of KEY, or nothing when the key is absent.
manifest_value() {
  awk -v key="$1" 'index($0, key "=") == 1 { print substr($0, length(key) + 2); exit }' "${MANIFEST}" \
    | tr '[:upper:]' '[:lower:]'
}

add_property() {
  if [[ -n "$2" ]]; then
    COMMAND+=("-D$1=$2")
  fi
}

if [[ ! -x "${NACOS_SERVER}" || ! -f "${MANIFEST}" ]]; then
  fail "Missing Native executable or AOT manifest under ${BASE_DIR}/target. Build the image from a Native archive."
fi

for key in datasource standalone deployment embeddedStorage functionMode; do
  if [[ -z "$(manifest_value "${key}")" ]]; then
    fail "The AOT manifest has no ${key}. Build the archive with the Native profile of this Nacos version."
  fi
done

datasource=$(manifest_value datasource)
standalone=$(manifest_value standalone)
deployment=$(manifest_value deployment)
embedded=$(manifest_value embeddedStorage)
manifest_function=$(manifest_value functionMode)

#===========================================================================================
# Authentication: the same variables as docker-startup.sh
#===========================================================================================
if [[ -z "${NACOS_AUTH_TOKEN:-}" ]]; then
  echo "env NACOS_AUTH_TOKEN must be set with Base64 String." >&2
  exit 255
fi

if [[ -z "${NACOS_AUTH_IDENTITY_KEY:-}" ]]; then
  echo "env NACOS_AUTH_IDENTITY_KEY must be set." >&2
  exit 255
fi

if [[ -z "${NACOS_AUTH_IDENTITY_VALUE:-}" ]]; then
  echo "env NACOS_AUTH_IDENTITY_VALUE must be set." >&2
  exit 255
fi

#===========================================================================================
# Structural choices: taken from the manifest, and checked against the environment
#===========================================================================================
if [[ -n "${SPRING_DATASOURCE_PLATFORM:-}" && "$(lower "${SPRING_DATASOURCE_PLATFORM}")" != "${datasource}" ]]; then
  fail "SPRING_DATASOURCE_PLATFORM=${SPRING_DATASOURCE_PLATFORM} does not match this executable, which was built for datasource ${datasource}."
fi
# The datasource plugin reads the dialect from the environment; the manifest's value is the one the executable has.
export SPRING_DATASOURCE_PLATFORM="${datasource}"

case "$(lower "${MODE:-}")" in
  "")
    ;;
  standalone)
    [[ "${standalone}" == "true" ]] || fail "MODE=standalone does not match this executable, which was built for cluster mode."
    ;;
  cluster)
    [[ "${standalone}" == "false" ]] || fail "MODE=cluster does not match this executable, which was built for standalone mode."
    ;;
  *)
    fail "Invalid MODE=${MODE}; use standalone or cluster."
    ;;
esac

if [[ -n "${NACOS_DEPLOYMENT_TYPE:-}" && "$(lower "${NACOS_DEPLOYMENT_TYPE}")" != "${deployment}" ]]; then
  fail "NACOS_DEPLOYMENT_TYPE=${NACOS_DEPLOYMENT_TYPE} does not match this executable, which was built for ${deployment} deployment."
fi

function_mode="${manifest_function}"
if [[ -n "${FUNCTION_MODE:-}" && "$(lower "${FUNCTION_MODE}")" != "${manifest_function}" ]]; then
  fail "FUNCTION_MODE=${FUNCTION_MODE} does not match this executable, which was built for ${manifest_function} function mode."
fi

if [[ "${standalone}" == "true" ]]; then
  mode=standalone
else
  mode=cluster
fi

#===========================================================================================
# Command line: the arguments of the archive's bin/startup-native.sh, in the foreground
#===========================================================================================
mkdir -p "${BASE_DIR}/data" "${BASE_DIR}/logs"

# NACOS_NATIVE_OPTS holds whitespace-separated Native VM options, such as -Xmx1g.
read -r -a NATIVE_OPTIONS <<< "${NACOS_NATIVE_OPTS:-}"
COMMAND=("${NACOS_SERVER}" "${NATIVE_OPTIONS[@]}")
COMMAND+=(
  "-Dnacos.home=${BASE_DIR}"
  "-Dnacos.standalone=${standalone}"
  "-Dnacos.deployment.type=${deployment}"
  "-DembeddedStorage=${embedded}"
  "-Dspring.config.additional-location=file:${BASE_DIR}/conf/"
  "-Dlogging.config=${BASE_DIR}/conf/nacos-logback.xml"
)
case "${function_mode}" in
  config|naming|microservice|ai)
    COMMAND+=("-Dnacos.functionMode=${function_mode}")
    ;;
esac

if [[ "$(lower "${PREFER_HOST_MODE:-}")" == "hostname" ]]; then
  COMMAND+=("-Dnacos.preferHostnameOverIp=true")
fi
add_property nacos.server.ip "${NACOS_SERVER_IP:-}"
add_property nacos.inetutils.use-only-site-local-interfaces "${USE_ONLY_SITE_INTERFACES:-}"
add_property nacos.inetutils.preferred-networks "${PREFERRED_NETWORKS:-}"
add_property nacos.inetutils.ignored-interfaces "${IGNORED_INTERFACES:-}"
add_property nacos.core.auth.enabled "${NACOS_AUTH_ENABLE:-}"
add_property nacos.core.auth.admin.enabled "${NACOS_AUTH_ADMIN_ENABLE:-}"
add_property nacos.core.auth.console.enabled "${NACOS_AUTH_CONSOLE_ENABLE:-}"

echo "Native Nacos is starting: ${mode} mode, ${deployment} deployment, ${datasource} datasource."

# nacos.nacos is the program argument that the archive's launcher passes.
exec "${COMMAND[@]}" nacos.nacos
