# 第一阶段：构建环境
FROM ubuntu:22.04 as builder
# 保留维护者信息
LABEL maintainer="YuanJie <782353676@qq.com>"

# 安装构建依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    wget \
    tar \
    && rm -rf /var/lib/apt/lists/*

# 安装 JDK
ARG JDK_VERSION=11.0.27_6
ADD OpenJDK11U-jdk_x64_linux_hotspot_11.0.27_6.tar.gz /usr/local/java/
RUN mv /usr/local/java/jdk-11.0.27+6 /usr/local/java/jdk

# 安装 Nacos
ARG NACOS_VERSION=2.3.2
COPY nacos-server-${NACOS_VERSION}.tar.gz /tmp/
RUN mkdir -p /app && \
    tar -xzf /tmp/nacos-server-${NACOS_VERSION}.tar.gz -C /app && \
    rm -rf /tmp/*

# 第二阶段：运行时环境
FROM ubuntu:22.04

# 保留维护者信息
LABEL maintainer="YuanJie <782353676@qq.com>"

# 安装运行时最小依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    iputils-ping \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# 从构建阶段复制必要文件
COPY --from=builder /usr/local/java/jdk /usr/local/java/jdk
COPY --from=builder /app/nacos /home/nacos

# 设置环境变量（显式声明JAVA变量）
ENV JAVA_HOME=/usr/local/java/jdk \
    JAVA=/usr/local/java/jdk/bin/java \
    PATH=$JAVA_HOME/bin:$PATH
    BASE_DIR=/home/nacos \
    MODE=cluster \
    TIME_ZONE=Asia/Shanghai

# 配置时区
RUN ln -snf /usr/share/zoneinfo/$TIME_ZONE /etc/localtime && \
    echo $TIME_ZONE > /etc/timezone

# 添加配置和启动脚本
ADD bin/docker-startup.sh $BASE_DIR/bin/
ADD conf/application.properties $BASE_DIR/conf/

# 设置日志重定向
RUN mkdir -p $BASE_DIR/logs && \
    ln -sf /dev/stdout $BASE_DIR/logs/start.out && \
    ln -sf /dev/stderr $BASE_DIR/logs/start.out && \
    chmod +x $BASE_DIR/bin/docker-startup.sh

EXPOSE 8848
WORKDIR $BASE_DIR
ENTRYPOINT ["./bin/docker-startup.sh"]
