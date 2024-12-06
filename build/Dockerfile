FROM bitnami/minideb:bookworm AS installer
RUN install_packages wget ca-certificates
ARG NACOS_VERSION=2.4.3
ARG HOT_FIX_FLAG=""

# 安装依赖
RUN set -x \
    && wget -O /var/tmp/nacos-server.tar.gz https://github.com/alibaba/nacos/releases/download/${NACOS_VERSION}${HOT_FIX_FLAG}/nacos-server-${NACOS_VERSION}.tar.gz \
    && tar -xzvf /var/tmp/nacos-server.tar.gz -C /home \
    && rm -rf /var/tmp/nacos-server.tar.gz /home/nacos/bin/* /home/nacos/conf/*.properties /home/nacos/conf/*.example /home/nacos/conf/nacos-mysql.sql

FROM bitnami/java:1.8-debian-12

# set env 
ENV MODE="cluster" \
    PREFER_HOST_MODE="ip"\
    BASE_DIR="/home/nacos" \
    CLASSPATH=".:/home/nacos/conf:$CLASSPATH" \
    CLUSTER_CONF="/home/nacos/conf/cluster.conf" \
    FUNCTION_MODE="all" \
    NACOS_USER="nacos" \
    NACOS_DEBUG="n" \
    TOMCAT_ACCESSLOG_ENABLED="false" \
    TZ="Asia/Shanghai"

# build target version
ARG NACOS_VERSION=2.4.3
ARG HOT_FIX_FLAG=""

WORKDIR $BASE_DIR

# copy bin to workdir
COPY --from=installer ["/home/nacos", "/home/nacos"]

ADD bin/docker-startup.sh bin/docker-startup.sh
ADD conf/application.properties conf/application.properties

# add nonroot
RUN useradd -r -u 1001 -g root nacos
RUN find / -perm /6000 -type f -exec chmod a-s {} \; || true

# 设置启动日志目录
RUN mkdir -p logs \
    && touch logs/start.out \
    && ln -sf /dev/stdout logs/start.out \
    && ln -sf /dev/stderr logs/start.out \
    && chown -R nacos:root /home/nacos \
    && chmod +x bin/docker-startup.sh

USER 1001
EXPOSE 8848
ENTRYPOINT ["sh","bin/docker-startup.sh"]
