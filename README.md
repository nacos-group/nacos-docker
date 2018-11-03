### 简介

这个仓库是 [Nacos](https://github.com/alibaba/nacos) Server的docker镜像的build的源码,以及docker的单机和集群的运行例子,目前的例子是基于develop分支制作,后续会根据最新版本进行制作,需要使用其他release版本的可以去[docker仓库](https://hub.docker.com/r/paderlol/nacos/)去自取。



### 运行要求

* [Docker](https://www.docker.com/)



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