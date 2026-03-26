FROM ubuntu:latest

LABEL maintainer="pader <huangmnlove@163.com>"

ENV DEBIAN_FRONTEND=noninteractive

# 安装依赖（对应原 apk 包）
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-17-jre-headless \
    curl \
    iputils-ping \
    vim \
    libcurl4 \
    bash \
    ca-certificates \
    tzdata \
    libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

RUN curl -LsSf https://astral.sh/uv/install.sh | sh

ENV PATH="/root/.local/bin:${PATH}"

RUN uv python install 3.10 \
    && uv venv -p 3.10 /home/nacos/.venv

RUN uv pip install -p /home/nacos/.venv/bin/python cisco-ai-skill-scanner==2.0.4

ENV PATH="/home/nacos/.venv/bin:${PATH}"

# Ubuntu amd64 下 OpenJDK 17 常见路径（arm64 请改为 java-17-openjdk-arm64）
ENV JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64" \
    JAVA="/usr/lib/jvm/java-17-openjdk-amd64/bin/java"

ENV MODE="cluster" \
    PREFER_HOST_MODE="ip" \
    BASE_DIR="/home/nacos" \
    CLASSPATH=".:/home/nacos/conf:${CLASSPATH}" \
    CLUSTER_CONF="/home/nacos/conf/cluster.conf" \
    FUNCTION_MODE="all" \
    NACOS_USER="nacos" \
    JVM_XMS="1g" \
    JVM_XMX="1g" \
    JVM_XMN="512m" \
    JVM_MS="128m" \
    JVM_MMS="320m" \
    NACOS_DEBUG="n" \
    TOMCAT_ACCESSLOG_ENABLED="false" \
    TIME_ZONE="Asia/Shanghai"

ARG NACOS_VERSION=3.2.0-BETA
ARG HOT_FIX_FLAG=""

WORKDIR ${BASE_DIR}
COPY ./nacos /home/nacos

RUN set -x \
    && rm -rf nacos-server.tar.gz /home/nacos/bin/* /home/nacos/conf/*.properties /home/nacos/conf/*.example /home/nacos/conf/nacos-mysql.sql \
    && ln -snf /usr/share/zoneinfo/${TIME_ZONE} /etc/localtime \
    && echo ${TIME_ZONE} > /etc/timezone

ADD bin/docker-startup.sh bin/docker-startup.sh
ADD conf/application.properties conf/application.properties
RUN ls /home/nacos

RUN mkdir -p logs \
    && touch logs/start.out \
    && ln -sf /dev/stdout logs/start.out \
    && ln -sf /dev/stderr logs/start.out \
    && chmod +x bin/docker-startup.sh

EXPOSE 8848
EXPOSE 9848 8080

ENTRYPOINT ["bash", "bin/docker-startup.sh"]
