#!/bin/bash
set -e

# 加载 NACOS_VERSION
source .env
CLEAN_VERSION=${NACOS_VERSION#v}
# deal -slim
CLEAN_VERSION=${CLEAN_VERSION%-*}

SCHEMA_URL="https://raw.githubusercontent.com/alibaba/nacos/${CLEAN_VERSION}/distribution/conf/mysql-schema.sql"

TARGET_DIR="./mysql-init"
VERSIONED_FILE="${TARGET_DIR}/${CLEAN_VERSION}-mysql-schema.sql"
FINAL_FILE="${TARGET_DIR}/mysql-schema.sql"

# 创建目录
mkdir -p "${TARGET_DIR}"

# 下载 schema 文件
echo "⬇️  Downloading MySQL schema for Nacos ${CLEAN_VERSION}..."
curl -sSL "$SCHEMA_URL" -o "${VERSIONED_FILE}"

# 校验下载
if [ ! -s "${VERSIONED_FILE}" ]; then
  echo "❌ Failed to download schema file from $SCHEMA_URL"
  exit 1
fi

# 拷贝为标准文件名供 MySQL 初始化使用
cp "${VERSIONED_FILE}" "${FINAL_FILE}"

# 删除原始版本号文件
rm -f "${VERSIONED_FILE}"

echo "✅ Downloaded and prepared: ${FINAL_FILE}"