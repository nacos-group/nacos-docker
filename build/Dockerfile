# ==================== 下载阶段 ====================
FROM eclipse-temurin:17-jre AS downloader

ARG NACOS_VERSION=3.2.1
ARG HOT_FIX_FLAG=""

RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp
# nacos release tarball 根目录为 nacos/，解压到 /opt 后路径为 /opt/nacos/
RUN curl -fSL --retry 3 --output nacos-server.tar.gz \
      "https://github.com/alibaba/nacos/releases/download/${NACOS_VERSION}${HOT_FIX_FLAG}/nacos-server-${NACOS_VERSION}.tar.gz" \
    && tar -xzf nacos-server.tar.gz -C /opt \
    && rm -rf /opt/nacos/bin/* /opt/nacos/conf/*.properties \
              /opt/nacos/conf/*.example /opt/nacos/conf/nacos-mysql.sql \
    && rm nacos-server.tar.gz

# ==================== 标准镜像 ====================
FROM eclipse-temurin:17-jre AS standard

LABEL maintainer="pader <huangmnlove@163.com>"

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl iputils-ping vim ca-certificates tzdata \
    && rm -rf /var/lib/apt/lists/*

ENV MODE="cluster" \
    PREFER_HOST_MODE="ip" \
    BASE_DIR="/home/nacos" \
    CLASSPATH=".:/home/nacos/conf:${CLASSPATH}" \
    CLUSTER_CONF="/home/nacos/conf/cluster.conf" \
    FUNCTION_MODE="all" \
    NACOS_USER="nacos" \
    JAVA_HOME="/opt/java/openjdk" \
    JAVA="/opt/java/openjdk/bin/java" \
    JVM_XMS="1g" \
    JVM_XMX="1g" \
    JVM_XMN="512m" \
    JVM_MS="128m" \
    JVM_MMS="320m" \
    NACOS_DEBUG="n" \
    TOMCAT_ACCESSLOG_ENABLED="false" \
    TIME_ZONE="Asia/Shanghai"

ARG NACOS_VERSION=3.2.1

WORKDIR ${BASE_DIR}

COPY --from=downloader /opt/nacos /home/nacos

ADD bin/docker-startup.sh bin/docker-startup.sh
ADD conf/application.properties conf/application.properties

RUN ln -snf /usr/share/zoneinfo/${TIME_ZONE} /etc/localtime \
    && echo ${TIME_ZONE} > /etc/timezone \
    && mkdir -p logs \
    && touch logs/start.out \
    && ln -sf /dev/stdout logs/start.out \
    && ln -sf /dev/stderr logs/start.out \
    && chmod +x bin/docker-startup.sh

EXPOSE 8848 9848 8080

ENTRYPOINT ["bash", "bin/docker-startup.sh"]

# ==================== Slim 镜像 ====================
FROM eclipse-temurin:21-jre-alpine AS slim

LABEL maintainer="pader <huangmnlove@163.com>"

RUN apk add --no-cache curl bash tzdata

ENV MODE="cluster" \
    PREFER_HOST_MODE="ip" \
    BASE_DIR="/home/nacos" \
    CLASSPATH=".:/home/nacos/conf:${CLASSPATH}" \
    CLUSTER_CONF="/home/nacos/conf/cluster.conf" \
    FUNCTION_MODE="all" \
    NACOS_USER="nacos" \
    JAVA_HOME="/opt/java/openjdk" \
    JAVA="/opt/java/openjdk/bin/java" \
    JVM_XMS="1g" \
    JVM_XMX="1g" \
    JVM_XMN="512m" \
    JVM_MS="128m" \
    JVM_MMS="320m" \
    NACOS_DEBUG="n" \
    TOMCAT_ACCESSLOG_ENABLED="false" \
    TIME_ZONE="Asia/Shanghai"

ARG NACOS_VERSION=3.2.1

WORKDIR ${BASE_DIR}

COPY --from=downloader /opt/nacos /home/nacos

ADD bin/docker-startup.sh bin/docker-startup.sh
ADD conf/application.properties conf/application.properties

RUN ln -snf /usr/share/zoneinfo/${TIME_ZONE} /etc/localtime \
    && echo ${TIME_ZONE} > /etc/timezone \
    && mkdir -p logs \
    && touch logs/start.out \
    && ln -sf /dev/stdout logs/start.out \
    && ln -sf /dev/stderr logs/start.out \
    && chmod +x bin/docker-startup.sh

EXPOSE 8848 9848 8080

ENTRYPOINT ["bash", "bin/docker-startup.sh"]
