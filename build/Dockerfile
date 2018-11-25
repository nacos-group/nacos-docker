FROM centos:7.5.1804
MAINTAINER pader "huangmnlove@163.com"

# set environment
ENV MODE="cluster" \
    PREFER_HOST_MODE="ip"\
    BASE_DIR="/home/nacos" \
    CLASSPATH=".:/home/nacos/conf:$CLASSPATH" \
    CLUSTER_CONF="/home/nacos/conf/cluster.conf" \
    JAVA_HOME="/usr/lib/jvm/java-1.8.0-openjdk" \
    JAVA="/usr/lib/jvm/java-1.8.0-openjdk/bin/java"

RUN set -x \
    && yum update -y \
    && yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel wget iputils nc tzdata vim libcurl\
    && yum autoremove -y wget \
    && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && yum clean all

WORKDIR /home/nacos

COPY nacos $BASE_DIR


# set startup log dir
RUN mkdir -p logs \
	&& cd logs \
	&& touch start.out \
	&& ln -sf /dev/stdout $BASE_DIR/logs/start.out \
	&& ln -sf /dev/stderr $BASE_DIR/logs/start.out
RUN chmod +x bin/docker-startup.sh

EXPOSE 8848
ENTRYPOINT ["bin/docker-startup.sh"]