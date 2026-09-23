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

Starting with Nacos 3.3, Client API authentication (`nacos.core.auth.enabled`) is enabled by default when
`NACOS_AUTH_ENABLE` is unset. Set `NACOS_AUTH_ENABLE=true` or `NACOS_AUTH_ENABLE=false` to override it explicitly.
Explicit `false` is available as a temporary upgrade-compatibility option while clients are being configured with
credentials. Earlier versioned images continue to use the defaults built into those image versions.

Client API authentication is independent of Admin API and Console API authentication. This default change does not
disable or otherwise change `NACOS_AUTH_ADMIN_ENABLE` or `NACOS_AUTH_CONSOLE_ENABLE`. Use unique, strong token and
server identity values in production; credentials committed in this repository are for local examples only and must
not be reused.

## Project directory

* build：Nacos makes the source code of the docker image
* env: Environment variable file for compose yaml
* example: Docker compose example for Nacos server

## Precautions

* The **database master-slave image** is no longer provided. For specific
  reasons, refer
  to [Removing the Master-Slave Image Configuration](https://github.com/nacos-group/nacos-docker/wiki/%E7%A7%BB%E9%99%A4%E6%95%B0%E6%8D%AE%E5%BA%93%E4%B8%BB%E4%BB%8E%E9%95%9C%E5%83%8F%E9%85%8D%E7%BD%AE)
* Since Nacos 1.3.1 version, the database storage has been upgraded to 8.0, and it is backward compatible
* If you use a custom database, you need to initialize
  the [database script](https://github.com/alibaba/nacos/blob/3.3.0-RC/plugin-default-impl/nacos-default-datasource-plugin/nacos-datasource-plugin-mysql/src/main/resources/META-INF/mysql-schema.sql) yourself for
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
NACOS_VERSION=v3.3.0-RC
```

Both Standard and Slim support `linux/amd64` and `linux/arm64`; Arm Macs do not require the Slim variant. Example Slim tag:

```dotenv
NACOS_VERSION=v3.3.0-RC-slim
```

Run the following command：

* Clone project

  ```powershell
  git clone --depth 1 https://github.com/nacos-group/nacos-docker.git
  cd nacos-docker
  ```

* Standalone Derby

  ```powershell
  docker compose -f example/standalone-derby.yaml up
  ```

* Standalone Mysql

  ```powershell
  cd example
  ./mysql-init.sh && docker compose -f standalone-mysql.yaml up
  ```

* Standalone Independent Mysql（Only Nacos 3.x is supported）

  ```powershell
  cd example
  ./mysql-init.sh && docker compose -f standalone-independent-mysql.yaml up
  ```

* Standalone Nacos Cluster

  ```powershell
  bash example/mysql-init.sh
  docker compose -f example/cluster-hostname.yaml up --build
  ```

* Log in (required for Client API requests by default in Nacos 3.3 and later)

  On a new deployment, open `http://127.0.0.1:8080/` to initialize the administrator password first.

  ```powershell
  curl -X POST 'http://127.0.0.1:8848/nacos/v3/auth/user/login' -d 'username=nacos' -d "password=${your_password}"
  ```

* Service registration

  ```powershell
  curl -X POST 'http://127.0.0.1:8848/nacos/v3/client/ns/instance?serviceName=quickstart.test.service&ip=127.0.0.1&port=8080' -H "accessToken:${your_access_token}"
  ```

* Service discovery

    ```powershell
    curl -X GET 'http://127.0.0.1:8848/nacos/v3/client/ns/instance/list?serviceName=quickstart.test.service' -H "accessToken:${your_access_token}"
    ```

* Publish config

  ```powershell
  curl -X POST 'http://127.0.0.1:8848/nacos/v3/admin/cs/config?dataId=quickstart.test.config&groupName=test&content=HelloWorld' -H "accessToken:${your_access_token}"
  ```

* Get config

  ```powershell
    curl -X GET 'http://127.0.0.1:8848/nacos/v3/client/cs/config?dataId=quickstart.test.config&groupName=test' -H "accessToken:${your_access_token}"
  ```

* Open the Nacos console in your browser

  link：http://127.0.0.1:8080/

## Common property configuration

| name                                    | description                                                                                                                       | option                                                                                                                                                                                |
|-----------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| MODE                                    | cluster/standalone                                                                                                                | cluster/standalone default **cluster**                                                                                                                                                |
| FUNCTION_MODE | Function mode; Lite defaults to microservice and bundles no scanner runtime | config/naming/microservice/ai/all; Standard/Slim default: all |
| NACOS_SERVERS                           | nacos cluster address                                                                                                             | eg. ip1:port1 ip2:port2 ip3:port3                                                                                                                                                     |
| PREFER_HOST_MODE                        | Whether hostname are supported                                                                                                    | hostname/ip default **ip**                                                                                                                                                            |
| NACOS_APPLICATION_PORT                  | nacos server port                                                                                                                 | default **8848**                                                                                                                                                                      |
| NACOS_SERVER_IP                         | custom nacos server ip when network was mutil-network                                                                             |                                                                                                                                                                                       |
| SPRING_DATASOURCE_PLATFORM | nacos.plugin.datasource-dialect.type; mount custom JDBC properties for non-MySQL databases | Derby for standalone/embedded; MySQL for ordinary cluster mode |
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
| NACOS_AUTH_SYSTEM_TYPE | nacos.plugin.auth.type | nacos; also supports ldap, oidc and custom plugins |
| NACOS_AUTH_ENABLE                       | Enable Client API authentication; independent of Admin and Console API authentication                                             | Unset uses the image default (`true` for Nacos 3.3+; earlier images keep their built-in default). Explicit `true`/`false` overrides it; use `false` only as a temporary upgrade aid.                                                                  |
| NACOS_AUTH_TOKEN_EXPIRE_SECONDS | nacos.plugin.auth.nacos.token.expire.seconds | 18000 |
| NACOS_AUTH_TOKEN | nacos.plugin.auth.nacos.token.secret.key | Required; Base64 encoding of at least 32 bytes |
| NACOS_AUTH_CACHE_ENABLE | nacos.plugin.auth.nacos.caching.enabled | false (preserves the Docker default) |
| MEMBER_LIST                             | Set the cluster list with a configuration file or command-line argument                                                           | eg:192.168.16.101:8847?raft_port=8807,192.168.16.101?raft_port=8808,192.168.16.101:8849?raft_port=8809                                                                                |
| EMBEDDED_STORAGE                        | Use embedded storage in cluster mode without mysql                                                                                | `embedded` default : none                                                                                                                                                             |
| NACOS_AUTH_IDENTITY_KEY                 | nacos.core.auth.server.identity.key; use a unique production value                                                                | `Note: Its default value was removed in Nacos 2.2.1, so it must be set explicitly.`                                                                                                   |
| NACOS_AUTH_IDENTITY_VALUE               | nacos.core.auth.server.identity.value; use a unique production value                                                              | `Note: Its default value was removed in Nacos 2.2.1, so it must be set explicitly.`                                                                                                   |
| NACOS_SECURITY_IGNORE_URLS | nacos.security.ignore.urls | See the template, including /next/** and /legacy/** |
| NACOS_CONSOLE_UI_ENABLED                | nacos.console.ui.enabled                                                                                                          | default : `true`                                                                                                                                                                      |
| NACOS_CORE_PARAM_CHECK_ENABLED          | nacos.core.param.check.enabled                                                                                                    | default : `true`                                                                                                                                                                      |
| DB_POOL_CONNECTION_TIMEOUT | nacos.plugin.datasource.db.pool.config.connection-timeout | 30000 ms |
| NACOS_AUTH_ADMIN_ENABLE                 | Independently controls nacos.core.auth.admin.enabled                                                                              | default : `true`                                                                                                                                                                      |
| NACOS_AUTH_CONSOLE_ENABLE               | Independently controls nacos.core.auth.console.enabled                                                                            | default : `true` |
| NACOS_CONSOLE_PORT                      | nacos.console.port                                                                                                                | default : `8080`                                                                                                                                                                      |
| NACOS_CONSOLE_CONTEXTPATH               | nacos.console.contextPath                                                                                                         | default : ``                                                                                                                                                                          |
| NACOS_DEPLOYMENT_TYPE                   | nacos.deployment.type                                                                                                             | default : `merged` support config `server` `console`                                                                                                                                  |
| NACOS_EXT_PLUGIN_DIRS                   | Additional mounted plugin or dependency directories appended to `loader.path`                                                     | comma-separated directories, for example `/home/nacos/ext-plugins,/home/nacos/ext-libs`                                                                                               |
| NACOS_CONSOLE_UI_DEFAULT | nacos.console.ui.default | next / legacy; next |
| NACOS_AI_REGISTRY_ENABLED | nacos.ai.mcp.registry.enabled | false |
| NACOS_AI_SKILL_REGISTRY_ENABLED | nacos.ai.skill.registry.enabled | false |
| NACOS_AI_ARD_ENABLED | nacos.ai.ard.enabled | false |
| NACOS_AI_REGISTRY_PORT | nacos.ai.registry.port | 9080 |
| NACOS_AI_RESOURCE_SEARCH_ENABLED | nacos.ai.resource.search.enabled | true |
| NACOS_AI_RESOURCE_IMPORT_ENABLED | nacos.plugin.ai-resource-import.enabled | true |
| NACOS_AUTH_ALLOW_ANONYMOUS_AI_ENABLED | nacos.plugin.auth.nacos.anonymous.ai.enabled | false |
| NACOS_AI_PIPELINE_ENABLED | nacos.plugin.ai-pipeline.enabled | true; Lite: false |
| NACOS_AI_PIPELINE_SKILL_SCANNER_ENABLED | nacos.plugin.ai-pipeline.skill-scanner.enabled | true; Lite: false |
| NACOS_AI_PIPELINE_SKILL_SCANNER_COMMAND | nacos.plugin.ai-pipeline.skill-scanner.command | skill-scanner |
| NACOS_AI_PIPELINE_SKILL_SPECTOR_ENABLED | nacos.plugin.ai-pipeline.skill-spector.enabled | false |
| NACOS_AI_PIPELINE_SKILL_SPECTOR_COMMAND | nacos.plugin.ai-pipeline.skill-spector.command | skill-spector |
| NACOS_CONSOLE_AI_MCP_IMPORT_ALLOWED_PRIVATE_ADDRESSES | nacos.console.ai.mcp.import.allowed-private-addresses | IP/CIDR list; empty |
| NACOS_NAMING_DNS_ENABLED | nacos.naming.dns.enabled | false |
| NACOS_NAMING_DNS_PORT | nacos.naming.dns.port | 5353 (TCP + UDP) |

## Advanced configuration

Copy `build/conf/application.properties`, customize it, and mount it at `/home/nacos/conf/application.properties`.
Migrate older settings into the 3.3 template and retain the environment placeholders; do not replace it with an entire 2.x/3.2 configuration.
The custom configuration example mounts `example/init.d/application.properties`:

```shell
bash example/mysql-init.sh
docker compose -f example/custom-application-config.yaml up --build
```

If you need to load extra plugin jars or dependency jars without rebuilding the image, mount those
directories into the container and append them through `NACOS_EXT_PLUGIN_DIRS`.

For example:

```docker
docker compose -f example/custom-plugin-dir.yaml up -d
```

```docker
docker run --name nacos-standalone \
  -e MODE=standalone \
  -e NACOS_AUTH_TOKEN=${your_nacos_auth_secret_token} \
  -e NACOS_AUTH_IDENTITY_KEY=${your_nacos_server_identity_key} \
  -e NACOS_AUTH_IDENTITY_VALUE=${your_nacos_server_identity_value} \
  -e NACOS_EXT_PLUGIN_DIRS=/home/nacos/ext-plugins,/home/nacos/ext-libs \
  -v /path/to/plugins:/home/nacos/ext-plugins \
  -v /path/to/libs:/home/nacos/ext-libs \
  -p 8080:8080 \
  -p 8848:8848 \
  -p 9848:9848 \
  -d nacos/nacos-server:latest
```

This is useful when a plugin jar and its runtime dependency jars need to be mounted separately. For
example, an LDAP deployment can mount the LDAP auth plugin jar in one directory and the required
`spring-ldap-core` dependency jars in another.

## Upgrade to 3.3.0-RC

This branch's Dockerfiles and configuration template target 3.3.0-RC and retain Java 17. To build older Nacos versions, use the corresponding repository revision; changing only `NACOS_VERSION` back to 3.2 is not supported by this template.

1. Back up the database and each node's data, configuration and plugins. Apply reviewed incremental DDL from the target schema. `mysql-init.sh` and the MySQL example Dockerfiles initialize new databases; they do not upgrade existing MySQL volumes.
2. Add `ai_resource_search_document`, `ai_resource_search_chunk`, `ai_resource_task` and their indexes to external databases. Search is enabled by default. `NACOS_AI_RESOURCE_SEARCH_ENABLED=false` temporarily disables it, but ARD then cannot be enabled. Check the actual `permissions.resource` size and other database-specific changes; never replay the full initialization SQL against production data.
3. Docker variable names are retained. Auth properties now use `nacos.plugin.auth.*`, the dialect uses `nacos.plugin.datasource-dialect.type`, and JDBC/pool settings use `nacos.plugin.datasource.db.*`. Canonical keys override legacy aliases even when empty. Auth gates and server identity remain under `nacos.core.auth.*`.
4. Client API authentication defaults to enabled. Initialize the administrator password in Console on a new deployment, then log in for an accessToken. Set `NACOS_AUTH_ENABLE=false` explicitly during a client migration window. All members must share the token secret and server identity; JRaft still needs server identity with Client auth disabled.
5. Retain each node's existing data. Plugin states and runtime configuration live under `data/plugin`; persisted overrides take precedence over static settings. `.enabled` supplies initial state, so update existing states through plugin management. `RESTART` properties still require a restart. Never share one data volume between nodes.
6. Mount only plugins verified for 3.3. Old AI Pipeline Builders, AI Resource Import SPIs and removed Config migration Mappers require migration. Follow the official runbook for historical A2A/MCP, Raft data and rollback boundaries; changing the image tag alone is not a rollback plan.

See the [3.3.0-RC release notes](https://github.com/alibaba/nacos/releases/tag/3.3.0-RC) and [next upgrade manual](https://nacos.io/en/docs/next/manual/admin/upgrading/).

## Persistent data and optional capabilities

Compose examples mount a separate named volume at `/home/nacos/data` for each Nacos service, including independent Console. Reuse that volume when replacing the image. `docker compose down -v` deletes the volumes and their data. Cluster Console host ports are 8080, 8081 and 8082.

If an older deployment has no data mount, copy `/home/nacos/data` out of each old container before recreating it (for example, `docker cp <container>:/home/nacos/data ./data-backup`). Restore that data into the new volume, or bind-mount the copied directory. Adding an empty volume does not migrate data from the old container layer.

Standard/Slim store bundled AI archives in `/home/nacos/data-seed`. Startup copies only missing zip files to data, preserving existing archives and supporting empty bind mounts. The volume retains plugin state, Derby and Raft files.

```shell
# MCP, Skill and ARD share port 9080; authentication remains enabled
docker compose -f example/standalone-ai-registry.yaml up
```

`NACOS_AI_REGISTRY_ENABLED` continues to control only MCP; Skill and ARD have separate switches. Update Compose port mappings when changing Registry/DNS ports. Private-network MCP tool imports require an explicit IP/CIDR allowlist.

Standard/Slim bundle Skill Scanner and disable SkillSpector by default. Install or mount the SkillSpector runtime before setting its command and enabling it; existing persisted states may also need updating in Console. Lite defaults to `FUNCTION_MODE=microservice` with Pipeline disabled and bundles no Python, scanners or AI archives. The existing `build/Dockerfile.Lite` is for local builds; the publishing workflow releases only Standard/Slim.

## Local validation

```shell
bash test/auth-defaults.sh
bash test/mysql-init.sh
docker build -f build/Dockerfile -t nacos-smoke:test build
bash example/mysql-init.sh
python3 test/docker-smoke.py --image nacos-smoke:test --mysql
```

Image tests cover default auth, explicit Client auth opt-out, configuration mapping, a custom Registry port, DNS TCP/UDP, persisted plugin configuration/state after container replacement, MySQL and independent Console. Tests create isolated containers, networks and volumes and remove their own resources on exit.

## Nacos + Grafana + Prometheus

Usage reference：[Nacos monitor-guide](https://nacos.io/zh-cn/docs/monitor-guide.html)

**Note**:  When Grafana creates a new data source, the data source address must be **http://prometheus:9090**
