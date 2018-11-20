### 简介

本项目是 [Nacos](https://github.com/alibaba/nacos) Server的docker镜像的build源码,以及Nacos server 在docker的单机和集群的运行例子.



### 项目目录

* build：nacos 镜像制作的源码,目前里面存放的是最新0.5.0的jar
* env: 镜像运行环境变量文件
* logs: nacos 运行日志挂载的卷
* mysql: docker mysql-master 运行挂载卷

### 运行环境

* [Docker](https://www.docker.com/)



### 注意事项
> nacos 0.5.0 开始才支持集群配置域名解析,所以需要集群使用需要注意以下事项
1. Nacos server 低于0.5.0版本,执行docker-compose 指定**cluster-ip.yaml**运行.
2. Nacos server 0.5.0或者更高版本集群,执行docker-compose 指定**cluster-hostname.yaml**或者**cluster-ip.yaml**运行都可以



### 使用方法

打开命令窗口执行：

* Clone 项目 并且进入项目根目录

  ```powershell
  git clone https://github.com/paderlol/nacos-docker.git
  cd nacos-docker
  ```


* 单机

  ```powershell
  docker-compose -f standalone.yaml up
  ```

* 集群

  ```powershell
  docker-compose -f cluster-hostname.yaml up 
  ```


* 注册服务

  ```powershell
  curl -X PUT 'http://127.0.0.1:8848/nacos/v1/ns/instance?serviceName=nacos.naming.serviceName&ip=20.18.7.10&port=8080'
  ```

* 注册配置

  ```powershell
  curl -X POST "http://127.0.0.1:8848/nacos/v1/cs/configs?dataId=nacos.cfg.dataId&group=test&content=helloWorld"
  ```

* 访问控制台

  浏览器访问：http://127.0.0.1:8848/nacos/
