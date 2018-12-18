# Nacos Docker

This project contains a Docker image meant to facilitate the deployment of [Nacos](https://github.com/alibaba/nacos) 
.



## Project directory

* build：Nacos makes the source code of the docker image
* env: Environment variable file for compose yaml
* example: Docker compose example for Nacos server


## Precautions
> The cluster configuration domain name resolution is not supported until version 0.5.0 of Nacos
1. When the Nacos version is below 0.5.0, You can use **cluster-ip.yaml**  when you execute the docker-compose command
2. When Nacos version 0.5.0 or higher, You can use either **cluster-hostname.yaml** or **cluster-ip.yaml** when you execute the docker-compose command



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
