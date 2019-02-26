# Nacos Docker

![Docker Pulls](https://img.shields.io/docker/pulls/nacos/nacos-server.svg?maxAge=60480)

This project contains a Docker image meant to facilitate the deployment of [Nacos](https://github.com/alibaba/nacos).


## Project directory

* build：Nacos makes the source code of the docker image
* env: Environment variable file for compose yaml
* example: Docker compose example for Nacos server


## Quick Start

Run the following command：

* Clone project

  ```powershell
  git clone https://github.com/nacos-group/nacos-docker.git
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
| PREFER_HOST_MODE              | Whether hostname are supported         | hostname/ip default **ip**             |
| NACOS_SERVER_PORT             | nacos server port                      | default **8848**                       |
| SPRING_DATASOURCE_PLATFORM    | standalone support mysql               | mysql / empty default empty            |
| MYSQL_MASTER_SERVICE_HOST     | mysql master host                      |                                        |
| MYSQL_MASTER_SERVICE_PORT     | mysql master database port             | default : **3306**                     |
| MYSQL_MASTER_SERVICE_DB_NAME  | mysql master database name             |                                        |
| MYSQL_MASTER_SERVICE_USER     | username of master database            |                                        |
| MYSQL_MASTER_SERVICE_PASSWORD | password of master database            |                                        |
| MYSQL_SLAVE_SERVICE_HOST      | mysql slave host                       |                                        |
| MYSQL_SLAVE_SERVICE_PORT      | mysql slave database port              | default :3306                          |

## Nacos + Grafana + Prometheus
Usage reference：[Nacos monitor-guide](https://nacos.io/zh-cn/docs/monitor-guide.html)

**Note**:  When Grafana creates a new data source, the data source address must be **http://prometheus:9090**
 
