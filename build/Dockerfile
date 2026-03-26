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
    unzip \
    libstdc++6 \
    && mkdir -p /opt/java \
    && ln -sfn "$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")" /opt/java/openjdk \
    && rm -rf /var/lib/apt/lists/*

RUN curl -LsSf https://astral.sh/uv/install.sh | sh

ENV PATH="/root/.local/bin:${PATH}"

RUN uv python install 3.10 \
    && uv venv -p 3.10 /home/nacos/.venv

RUN uv pip install -p /home/nacos/.venv/bin/python cisco-ai-skill-scanner==2.0.4

ENV PATH="/home/nacos/.venv/bin:${PATH}"

ENV JAVA_HOME="/opt/java/openjdk" \
    JAVA="/opt/java/openjdk/bin/java"

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
ARG SKILLS_DATA_URL="https://download.nacos.io/nacos-server-data/skills-data.zip"
ARG AGENTSPEC_DATA_URL="https://download.nacos.io/nacos-server-data/agentspec-data.zip"

WORKDIR ${BASE_DIR}

RUN set -x \
    && curl -fSL --retry 3 --output nacos-server.tar.gz "https://github.com/alibaba/nacos/releases/download/${NACOS_VERSION}${HOT_FIX_FLAG}/nacos-server-${NACOS_VERSION}.tar.gz" \
    && tar -xzvf nacos-server.tar.gz -C /home \
    && mkdir -p /home/nacos/data \
    && curl -fSL --retry 3 --output /home/nacos/data/skills-data.zip "${SKILLS_DATA_URL}" \
    && curl -fSL --retry 3 --output /home/nacos/data/agentspec-data.zip "${AGENTSPEC_DATA_URL}" \
    && rm -rf nacos-server.tar.gz /home/nacos/bin/* /home/nacos/conf/*.properties /home/nacos/conf/*.example /home/nacos/conf/nacos-mysql.sql \
    && ln -snf /usr/share/zoneinfo/${TIME_ZONE} /etc/localtime \
    && echo ${TIME_ZONE} > /etc/timezone

ADD bin/docker-startup.sh bin/docker-startup.sh
ADD conf/application.properties conf/application.properties

RUN mkdir -p logs \
    && touch logs/start.out \
    && ln -sf /dev/stdout logs/start.out \
    && ln -sf /dev/stderr logs/start.out \
    && chmod +x bin/docker-startup.sh

EXPOSE 8848
EXPOSE 9848 8080

ENTRYPOINT ["bash", "bin/docker-startup.sh"]
