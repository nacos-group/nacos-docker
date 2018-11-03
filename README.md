### 简介

本项目是 [Nacos](https://github.com/alibaba/nacos) Server的docker镜像的build源码,以及Nacos server 在docker的单机和集群的运行例子.



### 项目目录

* build：nacos 镜像制作的源码,目前里面存放的是dev分支的jar
* initdb：nacos集群SQL脚本
* logs: nacos 运行日志挂载的卷
* mysql:docker mysql 运行挂载卷

### 运行环境

* [Docker](https://www.docker.com/)



### 注意事项

1. 如果想体验目前的nacos server release版本**集群**,请执行docker-compose 指定**cluster-release.yaml**运行,体验dev请运行**cluster-dev.yaml**,dev和release版本的唯一区别是在集群运行时增加了集群节点主机名的解析,不用再docker配置中要指定IP了.其他并无太大区别.
2. 更改release版本号,配置文件中默认的**paderlol/nacos:dev** ->paderlol/nacos:**版本号**,如0.1.0、0.2.0，0.3.0,或者直接去[docker镜像](https://hub.docker.com/r/paderlol/nacos/)仓库查看版本



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
  docker-compose -f cluster.yaml up 
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