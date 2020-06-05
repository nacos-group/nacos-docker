# Nacos Docker

![Docker Pulls](https://img.shields.io/docker/pulls/nacos/nacos-server.svg?maxAge=60480)

This project contains a Docker image meant to facilitate the deployment of [Nacos](https://github.com/alibaba/nacos).

[**中文**](README_ZH.md)

## Project directory

* build：Nacos makes the source code of the docker image
* env: Environment variable file for compose yaml
* example: Docker compose example for Nacos server



## Precautions

After the latest `nacos/nacos-server:latest` image, the **database master-slave image** has been removed. For specific reasons, refer to [Removing the Master-Slave Image Configuration](https://github.com/nacos-group/nacos-docker/wiki/%E7%A7%BB%E9%99%A4%E6%95%B0%E6%8D%AE%E5%BA%93%E4%B8%BB%E4%BB%8E%E9%95%9C%E5%83%8F%E9%85%8D%E7%BD%AE)





## Quick Start

Run the following command：

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
  docker-compose -f example/standalone-mysql.yaml up
  ```

* Cluster

  ```powershell
  docker-compose -f example/cluster-hostname.yaml up 
  ```


* Service registration

  ```powershell
  curl -X PUT 'http://127.0.0.1:8848/nacos/v1/ns/instance?serviceName=nacos.naming.serviceName&ip=20.18.7.10&port=8080'
  ```

* Service discovery

    ```powershell
    curl -X GET 'http://127.0.0.1:8848/nacos/v1/ns/instances?serviceName=nacos.naming.serviceName'
    ```

* Publish config

  ```powershell
  curl -X POST "http://127.0.0.1:8848/nacos/v1/cs/configs?dataId=nacos.cfg.dataId&group=test&content=helloWorld"
  ```

* Get config

  ```powershell
    curl -X GET "http://127.0.0.1:8848/nacos/v1/cs/configs?dataId=nacos.cfg.dataId&group=test"
  ```

  

* Open the Nacos console in your browser
  
  link：http://127.0.0.1:8848/nacos/



## Common property configuration 

| name                          | description                            | option                                 |
| ----------------------------- | -------------------------------------- | -------------------------------------- |
| MODE                          | cluster/standalone                     | cluster/standalone default **cluster** |
| NACOS_SERVERS                 | nacos cluster address        | eg. ip1:port1 ip2:port2 ip3:port3             |
| PREFER_HOST_MODE              | Whether hostname are supported         | hostname/ip default **ip**             |
| NACOS_APPLICATION_PORT             | nacos server port                      | default **8848**                       |
| NACOS_SERVER_IP             | custom nacos server ip when network was mutil-network                      |                         |
| SPRING_DATASOURCE_PLATFORM    | standalone support mysql               | mysql / empty default empty            |
| MYSQL_SERVICE_HOST | mysql  host |  |
| MYSQL_SERVICE_PORT | mysql  database port | default : **3306** |
| MYSQL_SERVICE_DB_NAME | mysql  database name |  |
| MYSQL_SERVICE_USER | username of  database |  |
| MYSQL_SERVICE_PASSWORD | password of  database |  |
| ~~MYSQL_MASTER_SERVICE_HOST~~     | The **latest** version of the image removes this attribute, using MYSQL_SERVICE_HOST |                                        |
| ~~MYSQL_MASTER_SERVICE_PORT~~     | The **latest** version of the image removes this attribute, using MYSQL_SERVICE_PORT | default : **3306**                     |
| ~~MYSQL_MASTER_SERVICE_DB_NAME~~  | The **latest** version of the image removes this attribute, using MYSQL_SERVICE_DB_NAME |                                        |
| ~~MYSQL_MASTER_SERVICE_USER~~     | The **latest** version of the image removes this attribute, using MYSQL_SERVICE_USER |                                        |
| ~~MYSQL_MASTER_SERVICE_PASSWORD~~ | The **latest** version of the image removes this attribute, using MYSQL_SERVICE_PASSWORD |                                        |
| ~~MYSQL_SLAVE_SERVICE_HOST~~      | The **latest** version of the image removes this attribute   |                                        |
| ~~MYSQL_SLAVE_SERVICE_PORT~~      | The **latest** version of the image removes this attribute   | default :3306                          |
| MYSQL_DATABASE_NUM      | It indicates the number of database             | default :**1**                      |
| JVM_XMS      |  -Xms             | default :2g                          |
| JVM_XMX      |  -Xmx            | default :2g                          |
| JVM_XMN      |  -Xmn           | default :1g                          |
| JVM_MS      |  -XX:MetaspaceSize          | default :128m                          |
| JVM_MMS      |  -XX:MaxMetaspaceSize          | default :320m                          |
| NACOS_DEBUG      |  enable remote debug          | y/n default :n                          |
| TOMCAT_ACCESSLOG_ENABLED      |  server.tomcat.accesslog.enabled         | default :false                          |
| NACOS_AUTH_SYSTEM_TYPE      |  The auth system to use, currently only 'nacos' is supported        | default :nacos                          |
| NACOS_AUTH_ENABLE      |  If turn on auth system        | default :false                          |
| NACOS_AUTH_TOKEN_EXPIRE_SECONDS      |  The token expiration in seconds        | default :18000                          |
| NACOS_AUTH_TOKEN      |  The default token        | default :SecretKey012345678901234567890123456789012345678901234567890123456789                          |
| NACOS_AUTH_CACHE_ENABLE      |  Turn on/off caching of auth information. By turning on this switch, the update of auth information would have a 15 seconds delay.        | default : false                          |
| MEMBER_LIST      |  Set the cluster list with a configuration file or command-line argument        | eg:192.168.16.101:8847?raft_port=8807,192.168.16.101?raft_port=8808,192.168.16.101:8849?raft_port=8809                          |
| EMBEDDED_STORAGE      |    Use embedded storage in cluster mode without mysql      | `embedded` default : none                          |




## Nacos + Grafana + Prometheus

Usage reference：[Nacos monitor-guide](https://nacos.io/zh-cn/docs/monitor-guide.html)

**Note**:  When Grafana creates a new data source, the data source address must be **http://prometheus:9090**


