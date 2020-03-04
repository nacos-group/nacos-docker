# Nacos Docker

本项目是 [Nacos](https://github.com/alibaba/nacos) Server的docker镜像的build源码,以及Nacos server 在docker的单机和集群的运行例子.



## 项目目录

* build：nacos 镜像制作的源码
* env: docker compose 环境变量文件
* example: docker-compose编排例子



## 运行环境

* [Docker](https://www.docker.com/)

  

### 注意事项

 从最新的nacos:nacos-server/latest 镜像以后,移除了数据库主从镜像,具体原因请参考[移除主从镜像配置](https://github.com/nacos-group/nacos-docker/wiki/%E7%A7%BB%E9%99%A4%E6%95%B0%E6%8D%AE%E5%BA%93%E4%B8%BB%E4%BB%8E%E9%95%9C%E5%83%8F%E9%85%8D%E7%BD%AE)



## 快速开始

打开命令窗口执行：

``` powershell
 docker run --name nacos-standalone -e MODE=standalone -p 8848:8848 -d nacos/nacos-server:latest
```





## 其他使用方式

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
  





## 属性配置列表



| 属性名称                          | 描述                                                         | 选项                              |
| --------------------------------- | ------------------------------------------------------------ | ----------------------------------- |
| MODE                              | 系统启动方式: 集群/单机                                      | cluster/standalone默认 **cluster**  |
| NACOS_SERVERS                     | nacos cluster address                                        | p1:port1空格ip2:port2 空格ip3:port3 |
| PREFER_HOST_MODE                  | 支持IP还是域名模式                                           | hostname/ip 默认 **ip**             |
| NACOS_SERVER_PORT                 | Nacos 运行端口                                               | 默认 **8848**                       |
| NACOS_SERVER_IP                   | 多网卡模式下可以指定IP                                       |                                     |
| SPRING_DATASOURCE_PLATFORM        | standalone support mysql                                     | mysql / 空 默认:空                 |
| MYSQL_SERVICE_HOST                | mysql  host                                                  |                                     |
| MYSQL_SERVICE_PORT                | mysql  database port                                         | 默认 : **3306**                  |
| MYSQL_SERVICE_DB_NAME             | mysql  database name                                         |                                     |
| MYSQL_SERVICE_USER                | username of  database                                        |                                     |
| MYSQL_SERVICE_PASSWORD            | password of  database                                        |                                     |
| ~~MYSQL_MASTER_SERVICE_HOST~~     | **latest(目前latest 是1.1.4)以后**版本镜像移除, 使用 MYSQL_SERVICE_HOST |                                     |
| ~~MYSQL_MASTER_SERVICE_PORT~~     | **latest(目前latest 是1.1.4)以后**版本镜像移除, 使用 using MYSQL_SERVICE_PORT | 默认 : **3306**                  |
| ~~MYSQL_MASTER_SERVICE_DB_NAME~~  | **latest(目前latest 是1.1.4)以后**版本镜像移除, 使用 MYSQL_SERVICE_DB_NAME |                                     |
| ~~MYSQL_MASTER_SERVICE_USER~~     | **latest(目前latest 是1.1.4)以后**版本镜像移除, 使用 MYSQL_SERVICE_USER |                                     |
| ~~MYSQL_MASTER_SERVICE_PASSWORD~~ | **latest(目前latest 是1.1.4)以后**版本镜像移除, 使用, using MYSQL_SERVICE_PASSWORD |                                     |
| ~~MYSQL_SLAVE_SERVICE_HOST~~      | **latest(目前latest 是1.1.4)以后**版本镜像移除 |                                     |
| ~~MYSQL_SLAVE_SERVICE_PORT~~      | **latest(目前latest 是1.1.4)以后**版本镜像移除 | 默认 :3306                     |
| MYSQL_DATABASE_NUM                | It indicates the number of database                          | 默认 :**1**                    |
| JVM_XMS                           | -Xms                                                         | 默认 :2g                       |
| JVM_XMX                           | -Xmx                                                         | 默认 :2g                       |
| JVM_XMN                           | -Xmn                                                         | 默认 :1g                       |
| JVM_MS                            | -XX:MetaspaceSize                                            | 默认 :128m                     |
| JVM_MMS                           | -XX:MaxMetaspaceSize                                         | 默认 :320m                     |
| NACOS_DEBUG                       | enable remote debug                                          | y/n 默认 :n                      |
| TOMCAT_ACCESSLOG_ENABLED          | server.tomcat.accesslog.enabled                              | 默认 :false                      |
| NACOS_AUTH_SYSTEM_TYPE      |  权限系统类型选择,目前只支持nacos类型       | 默认 :nacos                          |
| NACOS_AUTH_ENABLE      |  是否开启权限系统       | 默认 :false                          |
| NACOS_AUTH_TOKEN_EXPIRE_SECONDS      |  token 失效时间        | 默认 :18000                          |
| NACOS_AUTH_TOKEN      |  token       | 默认 :SecretKey012345678901234567890123456789012345678901234567890123456789                          |
| NACOS_AUTH_CACHE_ENABLE      |  权限缓存开关 ,开启后权限缓存的更新默认有15秒的延迟      | 默认 : false                          |





## Nacos + Grafana + Prometheus

使用参考：[Nacos monitor-guide](https://nacos.io/zh-cn/docs/monitor-guide.html)

**Note**:  当使用Grafana创建数据源的时候地址必须是: **http://prometheus:9090**