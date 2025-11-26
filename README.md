# Nacos Docker

![Docker Pulls](https://img.shields.io/docker/pulls/nacos/nacos-server.svg?maxAge=60480)

This project contains a Docker image meant to facilitate the deployment of [Nacos](https://github.com/alibaba/nacos).

[**中文**](README_ZH.md)

## Note

The following environment variables have been **removed** from the default values in the new version(**Nacos 2.2.1**)
for the sake of **system security**, please add them yourself when starting up, otherwise an error will be reported at
startup.

1. ~~NACOS_AUTH_IDENTITY_KEY~~
2. ~~NACOS_AUTH_IDENTITY_VALUE~~
3. ~~NACOS_AUTH_TOKEN~~

## Project directory

* build：Nacos makes the source code of the docker image
* env: Environment variable file for compose yaml
* example: Docker compose example for Nacos server

## Precautions

* The **database master-slave image** has been removed, after the latest `nacos/nacos-server:latest` image. For specific
  reasons, refer
  to [Removing the Master-Slave Image Configuration](https://github.com/nacos-group/nacos-docker/wiki/%E7%A7%BB%E9%99%A4%E6%95%B0%E6%8D%AE%E5%BA%93%E4%B8%BB%E4%BB%8E%E9%95%9C%E5%83%8F%E9%85%8D%E7%BD%AE)
* Since Nacos 1.3.1 version, the database storage has been upgraded to 8.0, and it is backward compatible
* If you use a custom database, you need to initialize
  the [database script](https://github.com/alibaba/nacos/blob/master/distribution/conf/mysql-schema.sql) yourself for
  the first time.

## Quick Start

### Nacos v3.x

```shell
docker run --name nacos-standalone-derby \
    -e MODE=standalone \
    -e NACOS_AUTH_TOKEN=${your_nacos_auth_secret_token} \
    -e NACOS_AUTH_IDENTITY_KEY=${your_nacos_server_identity_key} \
    -e NACOS_AUTH_IDENTITY_VALUE=${your_nacos_server_identity_value} \
    -p 8080:8080 \
    -p 8848:8848 \
    -p 9848:9848 \
    -d nacos/nacos-server:latest
```

### Nacos v2.x

```shell
docker run --name nacos-standalone-derby-v2.5.1 \
    -e MODE=standalone \
    -e NACOS_AUTH_ENABLE=true \
    -e NACOS_AUTH_TOKEN=${your_nacos_auth_secret_token} \
    -e NACOS_AUTH_IDENTITY_KEY=${your_nacos_server_identity_key} \
    -e NACOS_AUTH_IDENTITY_VALUE=${your_nacos_server_identity_value} \
    -p 8848:8848 \
    -p 9848:9848 \
    -d nacos/nacos-server:v2.5.1
```

## Advanced Usage

* Tips: You can change [the version of the Nacos image](https://hub.docker.com/r/nacos/nacos-server/tags) in the compose file from the following configuration. `example/.env`

```dotenv
NACOS_VERSION=v3.1.1
```

For Mac user with Arm Chip (like M1/M2/M3 series) , you need to add `-slim` after version which support `arm` arch.

```dotenv
NACOS_VERSION=v3.1.1-slim
```

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
  cd example
  ./mysql-init.sh && docker-compose -f standalone-mysql.yaml up
  ```

* Standalone Independent Mysql（Only Nacos 3.x is supported）

  ```powershell
  cd example
  ./mysql-init.sh && docker-compose -f standalone-independent-mysql.yaml up
  ```

* Standalone Nacos Cluster

  ```powershell
  docker-compose -f example/cluster-hostname.yaml up 
  ```

* Service registration

  ```powershell
  curl -X POST 'http://127.0.0.1:8848/nacos/v3/client/ns/instance?serviceName=quickstart.test.service&ip=127.0.0.1&port=8080
  ```

* Service discovery

    ```powershell
    curl -X GET 'http://127.0.0.1:8848/nacos/v3/client/ns/instance/list?serviceName=quickstart.test.service'
    ```

* Publish config

  ```powershell
  curl -X POST 'http://127.0.0.1:8848/nacos/v3/auth/user/login' -d 'username=nacos' -d 'password=${your_password}'
  curl -X POST 'http://127.0.0.1:8848/nacos/v3/admin/cs/config?dataId=quickstart.test.config&groupName=test&content=HelloWorld' -H "accessToken:${your_access_token}"
  ```

* Get config

  ```powershell
    curl -X GET 'http://127.0.0.1:8848/nacos/v3/client/cs/config?dataId=quickstart.test.config&groupName=test'
  ```

* Open the Nacos console in your browser

  link：http://127.0.0.1:8080/index.html

## Common property configuration

| name                                    | description                                                                                                                       | option                                                                                                                                                                                |
|-----------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| MODE                                    | cluster/standalone                                                                                                                | cluster/standalone default **cluster**                                                                                                                                                |
| NACOS_SERVERS                           | nacos cluster address                                                                                                             | eg. ip1:port1 ip2:port2 ip3:port3                                                                                                                                                     |
| PREFER_HOST_MODE                        | Whether hostname are supported                                                                                                    | hostname/ip default **ip**                                                                                                                                                            |
| NACOS_APPLICATION_PORT                  | nacos server port                                                                                                                 | default **8848**                                                                                                                                                                      |
| NACOS_SERVER_IP                         | custom nacos server ip when network was mutil-network                                                                             |                                                                                                                                                                                       |
| SPRING_DATASOURCE_PLATFORM              | standalone support mysql                                                                                                          | mysql / empty default empty                                                                                                                                                           |
| MYSQL_SERVICE_HOST                      | mysql  host                                                                                                                       |                                                                                                                                                                                       |
| MYSQL_SERVICE_PORT                      | mysql  database port                                                                                                              | default : **3306**                                                                                                                                                                    |
| MYSQL_SERVICE_DB_NAME                   | mysql  database name                                                                                                              |                                                                                                                                                                                       |
| MYSQL_SERVICE_USER                      | username of  database                                                                                                             |                                                                                                                                                                                       |
| MYSQL_SERVICE_PASSWORD                  | password of  database                                                                                                             |                                                                                                                                                                                       |
| MYSQL_DATABASE_NUM                      | It indicates the number of database                                                                                               | default :**1**                                                                                                                                                                        |
| MYSQL_SERVICE_DB_PARAM                  | Database url parameter                                                                                                            | default :**characterEncoding=utf8&connectTimeout=1000&socketTimeout=3000&autoReconnect=true&useSSL=false**                                                                            |
| JVM_XMS                                 | -Xms                                                                                                                              | default :1g                                                                                                                                                                           |
| JVM_XMX                                 | -Xmx                                                                                                                              | default :1g                                                                                                                                                                           |
| JVM_XMN                                 | -Xmn                                                                                                                              | default :512m                                                                                                                                                                         |
| JVM_MS                                  | -XX:MetaspaceSize                                                                                                                 | default :128m                                                                                                                                                                         |
| JVM_MMS                                 | -XX:MaxMetaspaceSize                                                                                                              | default :320m                                                                                                                                                                         |
| NACOS_DEBUG                             | enable remote debug                                                                                                               | y/n default :n                                                                                                                                                                        |
| TOMCAT_ACCESSLOG_ENABLED                | server.tomcat.accesslog.enabled                                                                                                   | default :false                                                                                                                                                                        |
| NACOS_AUTH_SYSTEM_TYPE                  | The auth system to use, currently only 'nacos' is supported                                                                       | default :nacos                                                                                                                                                                        |
| NACOS_AUTH_ENABLE                       | If turn on auth system                                                                                                            | default :false                                                                                                                                                                        |
| NACOS_AUTH_TOKEN_EXPIRE_SECONDS         | The token expiration in seconds                                                                                                   | default :18000                                                                                                                                                                        |
| NACOS_AUTH_TOKEN                        |                                                                                                                                   | `Note: It is removed from Nacos 2.2.1`                                                                                                                                                |
| NACOS_AUTH_CACHE_ENABLE                 | Turn on/off caching of auth information. By turning on this switch, the update of auth information would have a 15 seconds delay. | default : false                                                                                                                                                                       |
| MEMBER_LIST                             | Set the cluster list with a configuration file or command-line argument                                                           | eg:192.168.16.101:8847?raft_port=8807,192.168.16.101?raft_port=8808,192.168.16.101:8849?raft_port=8809                                                                                |
| EMBEDDED_STORAGE                        | Use embedded storage in cluster mode without mysql                                                                                | `embedded` default : none                                                                                                                                                             |
| NACOS_AUTH_CACHE_ENABLE                 | nacos.core.auth.caching.enabled                                                                                                   | default : false                                                                                                                                                                       |
| NACOS_AUTH_USER_AGENT_AUTH_WHITE_ENABLE | nacos.core.auth.enable.userAgentAuthWhite                                                                                         | default : false                                                                                                                                                                       |
| NACOS_AUTH_IDENTITY_KEY                 | nacos.core.auth.server.identity.key                                                                                               | `Note: It is removed from Nacos 2.2.1`                                                                                                                                                |
| NACOS_AUTH_IDENTITY_VALUE               | nacos.core.auth.server.identity.value                                                                                             | `Note: It is removed from Nacos 2.2.1`                                                                                                                                                |
| NACOS_SECURITY_IGNORE_URLS              | nacos.security.ignore.urls                                                                                                        | default : `/,/error,/**/*.css,/**/*.js,/**/*.html,/**/*.map,/**/*.svg,/**/*.png,/**/*.ico,/console-fe/public/**,/v1/auth/**,/v1/console/health/**,/actuator/**,/v1/console/server/**` |
| NACOS_CONSOLE_UI_ENABLED                | nacos.console.ui.enabled                                                                                                          | default : `true`                                                                                                                                                                      |
| NACOS_CORE_PARAM_CHECK_ENABLED          | nacos.core.param.check.enabled                                                                                                    | default : `true`                                                                                                                                                                      |
| DB_POOL_CONNECTION_TIMEOUT              | Database connection pool timeout in milliseconds                                                                                  | default : **30000**                                                                                                                                                                   |
| NACOS_CONSOLE_UI_ENABLED                | nacos.console.ui.enabled                                                                                                          | default : `true`                                                                                                                                                                      |
| NACOS_CORE_PARAM_CHECK_ENABLED          | nacos.core.param.check.enabled                                                                                                    | default : `true`                                                                                                                                                                      |
| NACOS_AUTH_ADMIN_ENABLE                 | nacos.core.auth.admin.enable                                                                                                      | default : `true`                                                                                                                                                                      |
| NACOS_AUTH_CONSOLE_ENABLE               | nacos.core.auth.console.enable                                                                                                    | default : `true`                                                                                                                                                                      |                                                                                                                                                                                       |
| NACOS_CONSOLE_PORT                      | nacos.console.port                                                                                                                | default : `8080`                                                                                                                                                                      |
| NACOS_CONSOLE_CONTEXTPATH               | nacos.console.contextPath                                                                                                         | default : ``                                                                                                                                                                          |
| NACOS_DEPLOYMENT_TYPE                   | nacos.deployment.type                                                                                                             | default : `merged` support config `server` `console`                                                                                                                                  |

## Advanced configuration

~~If the above property configuration list does not meet your requirements, you can mount the `custom.properties` file
into the `/home/nacos/init.d/` directory of the container, where the spring properties can be configured, and the
priority is higher than `application.properties` file~~

If you have a lot of custom configuration needs, It is highly recommended to mount `application.properties` in
production environment.

For example:

```docker
docker-compose -f example/custom-application-config.yaml up -d
```

## Nacos + Grafana + Prometheus

Usage reference：[Nacos monitor-guide](https://nacos.io/zh-cn/docs/monitor-guide.html)

**Note**:  When Grafana creates a new data source, the data source address must be **http://prometheus:9090**


