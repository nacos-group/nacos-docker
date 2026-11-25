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

# Builds build/Dockerfile.Native from a stand-in Native archive and checks the image: the entrypoint
# starts the executable as PID 1 under uid 1000, and the image refuses what the archive does not
# match. The stand-in executable prints what it receives; the real Native executable is not built here.
# The build runs in a temporary copy of the files it needs, so a real archive in build/native-dist/ is
# never touched. Requires Docker. Usage: bash test/native-image.sh

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
IMAGE="nacos-native-test:${RANDOM}${RANDOM}"
WORK=$(mktemp -d)
trap 'docker image rm -f "${IMAGE}" >/dev/null 2>&1 || true; rm -rf "${WORK}"' EXIT

CONTEXT="${WORK}/build"
mkdir -p "${CONTEXT}/bin" "${CONTEXT}/conf" "${CONTEXT}/native-dist" "${WORK}/stand-in/nacos/target" \
  "${WORK}/stand-in/nacos/conf" "${WORK}/stand-in/nacos/bin"
cp "${ROOT_DIR}/build/Dockerfile.Native" "${CONTEXT}/Dockerfile.Native"
cp "${ROOT_DIR}/build/bin/docker-native-startup.sh" "${CONTEXT}/bin/"
cp "${ROOT_DIR}/build/conf/application-native.properties" "${CONTEXT}/conf/"

cd "${WORK}/stand-in/nacos"
printf '%s\n' standalone=true deployment=merged datasource=mysql embeddedStorage=false functionMode=All \
  > target/aot-manifest.properties
cat > target/nacos-server <<'EOF'
#!/bin/bash
printf 'pid=%s uid=%s\n' "$$" "$(id -u)"
for argument in "$@"; do
  printf 'arg=%s\n' "${argument}"
done
printf 'env.SPRING_DATASOURCE_PLATFORM=%s\n' "${SPRING_DATASOURCE_PLATFORM:-}"
EOF
chmod 0755 target/nacos-server
echo "stand-in logback" > conf/nacos-logback.xml
echo "jvm template" > conf/application.properties
printf '#!/bin/bash\n' > bin/startup-native.sh
chmod 0755 bin/startup-native.sh
cd "${WORK}/stand-in"
tar -czf "${CONTEXT}/native-dist/nacos-native.tar.gz" nacos

docker build -q -f "${CONTEXT}/Dockerfile.Native" -t "${IMAGE}" "${CONTEXT}" >/dev/null

AUTH=(-e NACOS_AUTH_TOKEN=dGVzdC10b2tlbg== -e NACOS_AUTH_IDENTITY_KEY=test-key -e NACOS_AUTH_IDENTITY_VALUE=test-value)

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

# run_image [docker run options...] runs the image and records its output in OUTPUT and its status in STATUS.
run_image() {
  set +e
  OUTPUT=$(docker run --rm "$@" "${IMAGE}" 2>&1)
  STATUS=$?
  set -e
}

# The executable's default logs directory, /home/nacos/nacos/logs, must resolve to the Nacos home's logs.
OUTPUT=$(docker run --rm --entrypoint sh "${IMAGE}" -c 'test "$(readlink -f /home/nacos/nacos/logs)" = /home/nacos/logs && echo linked') \
  || fail "the image has no logs link"
grep -qx linked <<< "${OUTPUT}" || fail "the logs link does not resolve to /home/nacos/logs"

run_image "${AUTH[@]}" -e NACOS_NATIVE_OPTS=-Xmx1g
[[ "${STATUS}" == 0 ]] || fail "start exited with ${STATUS}: ${OUTPUT}"
grep -qx 'pid=1 uid=1000' <<< "${OUTPUT}" || fail "the executable is not PID 1 under uid 1000: ${OUTPUT}"
grep -qx 'arg=-Xmx1g' <<< "${OUTPUT}" || fail "NACOS_NATIVE_OPTS did not reach the executable"
grep -qx 'arg=-Dnacos.standalone=true' <<< "${OUTPUT}" || fail "the standalone flag is missing"
grep -qx 'arg=-Dnacos.deployment.type=merged' <<< "${OUTPUT}" || fail "the deployment flag is missing"
grep -qx 'env.SPRING_DATASOURCE_PLATFORM=mysql' <<< "${OUTPUT}" || fail "the datasource is not mysql"

run_image -e NACOS_AUTH_IDENTITY_KEY=test-key -e NACOS_AUTH_IDENTITY_VALUE=test-value
[[ "${STATUS}" == 255 ]] || fail "a missing NACOS_AUTH_TOKEN must exit 255, got ${STATUS}"
grep -qF 'NACOS_AUTH_TOKEN must be set' <<< "${OUTPUT}" || fail "the missing token is not reported"

run_image "${AUTH[@]}" -e SPRING_DATASOURCE_PLATFORM=postgresql
[[ "${STATUS}" == 1 ]] || fail "a datasource that does not match must exit 1, got ${STATUS}"

if docker build -q -f "${CONTEXT}/Dockerfile.Native" --build-arg NACOS_NATIVE_DATASOURCE=postgresql \
  -t "${IMAGE}-wrong" "${CONTEXT}" >/dev/null 2>&1; then
  docker image rm -f "${IMAGE}-wrong" >/dev/null 2>&1 || true
  fail "the build accepted an archive built for mysql as postgresql"
fi

echo "native-image tests passed"
