# Nacos Docker

本项目是 [Nacos](https://github.com/alibaba/nacos) Server的docker镜像的build源码,以及Nacos server 在docker的单机和集群的运行例子.



## 项目目录

* build：nacos 镜像制作的源码
* env: docker compose 环境变量文件
* example: docker-compose编排例子



## 运行环境

* [Docker](https://www.docker.com/)

  

### 注意事项

* 从最新的nacos:nacos-server/latest 镜像以后,移除了数据库主从镜像,具体原因请参考[移除主从镜像配置](https://github.com/nacos-group/nacos-docker/wiki/%E7%A7%BB%E9%99%A4%E6%95%B0%E6%8D%AE%E5%BA%93%E4%B8%BB%E4%BB%8E%E9%95%9C%E5%83%8F%E9%85%8D%E7%BD%AE)
* 从Nacos 1.3.1版本开始,数据库存储已经升级到8.0, 并且它向下兼容
* 例子演示中使用的数据库是为了方便定制了官方Mysql镜像, 自动初始化的数据库脚本.  
* 如果你使用自定义数据库, 第一次启动Nacos前需要手动初始化 [数据库脚本](https://github.com/alibaba/nacos/blob/develop/distribution/conf/nacos-mysql.sql) .




## 快速开始

打开命令窗口执行：

* Clone project

  ```powershell
  git clone --depth 1 https://github.com/nacos-group/nacos-docker.git
  cd nacos-docker
  ```


* Standalone Derby

  ```powershell
  docker-compose -f example/standalone-derby.yaml up
  ```

* Standalone Mysql

  ```powershell
  # Using mysql 5.7
  docker-compose -f example/standalone-mysql-5.7.yaml up
  
  # Using mysql 8
  docker-compose -f example/standalone-mysql-8.yaml up
  ```

* 集群模式

  ```powershell
  docker-compose -f example/cluster-hostname.yaml up 
  ```


* 服务注册示例

  ```powershell
  curl -X PUT 'http://127.0.0.1:8848/nacos/v1/ns/instance?serviceName=nacos.naming.serviceName&ip=20.18.7.10&port=8080'
  ```

* 服务发现示例

  ```powershell
  curl -X GET 'http://127.0.0.1:8848/nacos/v1/ns/instances?serviceName=nacos.naming.serviceName'
  ```

* 推送配置示例

  ```powershell
  curl -X POST "http://127.0.0.1:8848/nacos/v1/cs/configs?dataId=nacos.cfg.dataId&group=test&content=helloWorld"
  ```

* 获取配置示例

  ```powershell
    curl -X GET "http://127.0.0.1:8848/nacos/v1/cs/configs?dataId=nacos.cfg.dataId&group=test"
  ```

  

* 打开浏览器

  link：http://127.0.0.1:8848/nacos/

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
| NACOS_SERVERS                     | 集群地址                                   | p1:port1空格ip2:port2 空格ip3:port3 |
| PREFER_HOST_MODE                  | 支持IP还是域名模式                                           | hostname/ip 默认 **ip**             |
| NACOS_SERVER_PORT                 | Nacos 运行端口                                               | 默认 **8848**                       |
| NACOS_SERVER_IP                   | 多网卡模式下可以指定IP                                       |                                     |
| SPRING_DATASOURCE_PLATFORM        | 单机模式下支持MYSQL数据库                        | mysql / 空 默认:空                 |
| MYSQL_SERVICE_HOST                | 数据库  连接地址                                                |                                     |
| MYSQL_SERVICE_PORT                | 数据库端口                                       | 默认 : **3306**                  |
| MYSQL_SERVICE_DB_NAME             | 数据库库名                                     |                                     |
| MYSQL_SERVICE_USER                | 数据库用户名                                  |                                     |
| MYSQL_SERVICE_PASSWORD            | 数据库用户密码                                    |                                     |
| MYSQL_SERVICE_DB_PARAM          | 数据库连接参数                                     | default : **characterEncoding=utf8&connectTimeout=1000&socketTimeout=3000&autoReconnect=true&useSSL=false** |
| MYSQL_DATABASE_NUM                | It indicates the number of database                          | 默认 :**1**                    |
| JVM_XMS                           | -Xms                                                         | 默认 :1g                       |
| JVM_XMX                           | -Xmx                                                         | 默认 :1g                       |
| JVM_XMN                           | -Xmn                                                         | 默认 :512m                       |
| JVM_MS                            | -XX:MetaspaceSize                                            | 默认 :128m                     |
| JVM_MMS                           | -XX:MaxMetaspaceSize                                         | 默认 :320m                     |
| NACOS_DEBUG                       | 是否开启远程DEBUG                                 | y/n 默认 :n                      |
| TOMCAT_ACCESSLOG_ENABLED          | server.tomcat.accesslog.enabled                              | 默认 :false                      |
| NACOS_AUTH_SYSTEM_TYPE      |  权限系统类型选择,目前只支持nacos类型       | 默认 :nacos                          |
| NACOS_AUTH_ENABLE      |  是否开启权限系统       | 默认 :false                          |
| NACOS_AUTH_TOKEN_EXPIRE_SECONDS      |  token 失效时间        | 默认 :18000                          |
| NACOS_AUTH_TOKEN      |  token       | 默认 :SecretKey012345678901234567890123456789012345678901234567890123456789                          |
| NACOS_AUTH_CACHE_ENABLE      |  权限缓存开关 ,开启后权限缓存的更新默认有15秒的延迟      | 默认 : false                          |
| MEMBER_LIST | 通过环境变量的方式设置集群地址 | 例子:192.168.16.101:8847?raft_port=8807,192.168.16.101?raft_port=8808,192.168.16.101:8849?raft_port=8809 |
| EMBEDDED_STORAGE | 是否开启集群嵌入式存储模式 | `embedded`  默认 : none |
| NACOS_AUTH_CACHE_ENABLE      |    nacos.core.auth.caching.enabled      |  default : false                          |
| NACOS_AUTH_USER_AGENT_AUTH_WHITE_ENABLE      |    nacos.core.auth.enable.userAgentAuthWhite      |  default : false                          |
| NACOS_AUTH_IDENTITY_KEY      |    nacos.core.auth.server.identity.key      |  default : serverIdentity                          |
| NACOS_AUTH_IDENTITY_VALUE      |    nacos.core.auth.server.identity.value      |  default : security                          |
| NACOS_SECURITY_IGNORE_URLS      |    nacos.security.ignore.urls      |  default : `/,/error,/**/*.css,/**/*.js,/**/*.html,/**/*.map,/**/*.svg,/**/*.png,/**/*.ico,/console-fe/public/**,/v1/auth/**,/v1/console/health/**,/actuator/**,/v1/console/server/**`                          |





## 高级配置

如果上面的属性列表无法满足你的需求时,可以挂载`custom.properties`到`/home/nacos/init.d/` 目录,然后在里面像使用Spring Boot的`application.properties`文件一样配置属性, 并且这个文件配置的属性**优先级高于application.properties**

参考例子: [cluster-hostname.yaml](/example/cluster-hostname)





## Nacos + Grafana + Prometheus

使用参考：[Nacos monitor-guide](https://nacos.io/zh-cn/docs/monitor-guide.html)

**Note**:  当使用Grafana创建数据源的时候地址必须是: **http://prometheus:9090**