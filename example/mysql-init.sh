#!/usr/bin/env bash
set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# Keep the original .env source and precedence, independent of the working directory.
source "${SCRIPT_DIR}/.env"
: "${NACOS_VERSION:?NACOS_VERSION must be set in example/.env}"
CLEAN_VERSION=${NACOS_VERSION#v}
# Strip only the Docker image suffix. Preserve four-part versions, prereleases,
# dated hotfixes and other upstream tag formats without SemVer/PEP 440 validation.
CLEAN_VERSION=${CLEAN_VERSION%-slim}

SCHEMA_BASE="https://raw.githubusercontent.com/alibaba/nacos/${CLEAN_VERSION}"
NEW_SCHEMA_URL="${SCHEMA_BASE}/plugin-default-impl/nacos-default-datasource-plugin/nacos-datasource-plugin-mysql/src/main/resources/META-INF/mysql-schema.sql"
OLD_SCHEMA_URL="${SCHEMA_BASE}/distribution/conf/mysql-schema.sql"
TARGET_DIR="${SCRIPT_DIR}/mysql-init"
FINAL_FILE="${TARGET_DIR}/mysql-schema.sql"
mkdir -p "${TARGET_DIR}"
TEMP_FILE=$(mktemp "${TARGET_DIR}/.mysql-schema.XXXXXX")
trap 'rm -f "${TEMP_FILE}"' EXIT

echo "Downloading MySQL schema for Nacos ${CLEAN_VERSION}..."
if ! curl -fsSL --retry 3 "${NEW_SCHEMA_URL}" -o "${TEMP_FILE}"; then
  echo "Trying the distribution schema path..."
  curl -fsSL --retry 3 "${OLD_SCHEMA_URL}" -o "${TEMP_FILE}"
fi
if [[ ! -s "${TEMP_FILE}" ]]; then
  echo "Empty MySQL schema for Nacos ${CLEAN_VERSION}" >&2
  exit 1
fi
chmod 644 "${TEMP_FILE}"
mv "${TEMP_FILE}" "${FINAL_FILE}"
echo "Prepared ${FINAL_FILE} (new databases only; existing databases need incremental migration)."
