# Nacos Docker

This project contains a Docker image meant to facilitate the deployment of [Nacos](https://github.com/alibaba/nacos) 
.



## Project directory

* build：Nacos makes the source code of the docker image
* env: Environment variable file for compose yaml


## Precautions
> The cluster configuration domain name resolution is not supported until version 0.5.0 of Nacos
1. When the Nacos version is below 0.5.0, use the **cluster-ip.yaml** file when executing the docker-compose command
2. When the Nacos 0.5.0 or later, use either **cluster-hostname.yaml** or **cluster-ip.yaml**  in the execution of the docker-composer command



## Quick Start

Run the following command：

* Clone project

  ```powershell
  git clone https://github.com/paderlol/nacos-docker.git
  cd nacos-docker
  ```


* Stand-alone

  ```powershell
  docker-compose -f standalone.yaml up
  ```

* Cluster

  ```powershell
  docker-compose -f cluster-hostname.yaml up 
  ```


* Service registration

  ```powershell
  curl -X PUT 'http://127.0.0.1:8848/nacos/v1/ns/instance?serviceName=nacos.naming.serviceName&ip=20.18.7.10&port=8080'
  ```

* Publish config

  ```powershell
  curl -X POST "http://127.0.0.1:8848/nacos/v1/cs/configs?dataId=nacos.cfg.dataId&group=test&content=helloWorld"
  ```

* Open the Nacos console in your browser

  link：http://127.0.0.1:8848/nacos/
