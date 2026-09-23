# Nacos Docker

![Docker Pulls](https://img.shields.io/docker/pulls/nacos/nacos-server.svg?maxAge=60480)

本项目是 [Nacos](https://github.com/alibaba/nacos) Server的docker镜像的build源码,以及Nacos server 在docker的单机和集群的运行例子.

[**English**](README.md)

## 注意

从Nacos 2.2.1开始为了系统安全考虑**移除**了以下环境变量的默认值,启动时请自行添加,否则会启动报错.

1. ~~NACOS_AUTH_IDENTITY_KEY~~
2. ~~NACOS_AUTH_IDENTITY_VALUE~~
3. ~~NACOS_AUTH_TOKEN~~

从 Nacos 3.3 开始，未设置 `NACOS_AUTH_ENABLE` 时，Client API 鉴权（`nacos.core.auth.enabled`）默认开启。
显式设置 `NACOS_AUTH_ENABLE=true` 或 `NACOS_AUTH_ENABLE=false` 均会覆盖该默认值。应用客户端尚未完成凭据配置时，
可以将显式 `false` 作为有时限的升级兼容选择；旧版本镜像仍遵循各自版本内置的默认值。

Client API 鉴权与 Admin API、Console API 鉴权相互独立。本次默认值调整不会关闭或改变
`NACOS_AUTH_ADMIN_ENABLE` 和 `NACOS_AUTH_CONSOLE_ENABLE`。生产环境必须使用唯一且足够强的 token secret 和
server identity；仓库中提交的凭据仅用于本地示例，不得在生产环境复用。

## 项目目录

* build：nacos 镜像制作的源码
* env: docker compose 环境变量文件
* example: docker compose编排例子

## 运行环境

* [Docker](https://www.docker.com/)

### 注意事项

* 从最新的nacos:nacos-server/latest
  镜像以后,移除了数据库主从镜像,具体原因请参考[移除主从镜像配置](https://github.com/nacos-group/nacos-docker/wiki/%E7%A7%BB%E9%99%A4%E6%95%B0%E6%8D%AE%E5%BA%93%E4%B8%BB%E4%BB%8E%E9%95%9C%E5%83%8F%E9%85%8D%E7%BD%AE)
* 从Nacos 1.3.1版本开始,数据库存储已经升级到8.0, 并且它向下兼容
* 例子演示中使用的数据库是为了方便定制了官方Mysql镜像, 自动初始化的数据库脚本.
* 如果你使用自定义数据库, 第一次启动Nacos前需要手动初始化 [数据库脚本](https://github.com/alibaba/nacos/blob/3.3.0-RC/plugin-default-impl/nacos-default-datasource-plugin/nacos-datasource-plugin-mysql/src/main/resources/META-INF/mysql-schema.sql)

## 快速开始

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

## 其他使用方式

* 提示: 你需要通过 `example/.env` 中的以下配置来更改 Compose 文件中 [Nacos 镜像版本](https://hub.docker.com/r/nacos/nacos-server/tags)。

```dotenv
NACOS_VERSION=v3.3.0-RC
```

Standard 和 Slim 均构建 `linux/amd64`、`linux/arm64` 镜像，Arm Mac 无需强制选择 Slim。Slim 标签示例：

```dotenv
NACOS_VERSION=v3.3.0-RC-slim
```

打开命令窗口执行：

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
* Standalone Independent Mysql（仅支持 Nacos 3.x 版本）

  ```powershell
  cd example
  ./mysql-init.sh && docker compose -f standalone-independent-mysql.yaml up
  ```

* docker单节点部署集群模式

  ```powershell
  bash example/mysql-init.sh
  docker compose -f example/cluster-hostname.yaml up --build
  ```

* 登录（Nacos 3.3 及以上版本默认要求 Client API 请求携带凭据）

  首次部署请先打开 `http://127.0.0.1:8080/` 初始化管理员密码。

  ```powershell
  curl -X POST 'http://127.0.0.1:8848/nacos/v3/auth/user/login' -d 'username=nacos' -d "password=${your_password}"
  ```

* 服务注册示例

  ```powershell
  curl -X POST 'http://127.0.0.1:8848/nacos/v3/client/ns/instance?serviceName=quickstart.test.service&ip=127.0.0.1&port=8080' -H "accessToken:${your_access_token}"
  ```

* 服务发现示例

  ```powershell
  curl -X GET 'http://127.0.0.1:8848/nacos/v3/client/ns/instance/list?serviceName=quickstart.test.service' -H "accessToken:${your_access_token}"
  ```

* 推送配置示例

  ```powershell
  curl -X POST 'http://127.0.0.1:8848/nacos/v3/admin/cs/config?dataId=quickstart.test.config&groupName=test&content=HelloWorld' -H "accessToken:${your_access_token}"
  ```

* 获取配置示例

  ```powershell
    curl -X GET 'http://127.0.0.1:8848/nacos/v3/client/cs/config?dataId=quickstart.test.config&groupName=test' -H "accessToken:${your_access_token}"
  ```

* 访问控制台

  浏览器访问：http://127.0.0.1:8080/

## 属性配置列表

| 属性名称                                    | 描述                                        | 选项                                                                                                                                                                                    |
|-----------------------------------------|-------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| MODE                                    | 系统启动方式: 集群/单机                             | cluster/standalone 默认 **cluster**                                                                                                                                                     |
| FUNCTION_MODE | 功能模式；Lite 默认 microservice，不内置扫描运行时 | config/naming/microservice/ai/all；Standard/Slim 默认 all |
| NACOS_SERVERS                           | 集群地址                                      | p1:port1空格ip2:port2 空格ip3:port3                                                                                                                                                       |
| PREFER_HOST_MODE                        | 支持IP还是域名模式                                | hostname/ip 默认**IP**                                                                                                                                                                  |
| NACOS_APPLICATION_PORT | nacos.server.main.port | 8848 |
| NACOS_SERVER_IP                         | 多网卡模式下可以指定IP                              |                                                                                                                                                                                       |
| SPRING_DATASOURCE_PLATFORM | nacos.plugin.datasource-dialect.type；非 MySQL 请挂载自定义 JDBC 配置 | 单机/embedded 默认 Derby；普通集群默认 MySQL |
| MYSQL_SERVICE_HOST                      | 数据库 连接地址                                  |                                                                                                                                                                                       |
| MYSQL_SERVICE_PORT                      | 数据库端口                                     | 默认 : **3306**                                                                                                                                                                         |
| MYSQL_SERVICE_DB_NAME                   | 数据库库名                                     |                                                                                                                                                                                       |
| MYSQL_SERVICE_USER                      | 数据库用户名                                    |                                                                                                                                                                                       |
| MYSQL_SERVICE_PASSWORD                  | 数据库用户密码                                   |                                                                                                                                                                                       |
| MYSQL_SERVICE_DB_PARAM                  | 数据库连接参数                                   | 默认:**characterEncoding=utf8&connectTimeout=1000&socketTimeout=3000&autoReconnect=true&useSSL=false**                                                                                  |
| MYSQL_DATABASE_NUM                      | 数据库个数                                     | 默认:**1**                                                                                                                                                                              |
| JVM_XMS                                 | -Xms                                      | 默认 :1g                                                                                                                                                                                |
| JVM_XMX                                 | -Xmx                                      | 默认 :1g                                                                                                                                                                                |
| JVM_XMN                                 | -Xmn                                      | 512m                                                                                                                                                                                  |
| JVM_MS                                  | - XX:MetaspaceSize                        | 默认 :128m                                                                                                                                                                              |
| JVM_MMS                                 | -XX:MaxMetaspaceSize                      | 默认 :320m                                                                                                                                                                              |
| NACOS_DEBUG                             | 是否开启远程DEBUG                               | y/n 默认 :n                                                                                                                                                                             |
| TOMCAT_ACCESSLOG_ENABLED                | server.tomcat.accesslog.enabled           | 默认 :false                                                                                                                                                                             |
| NACOS_AUTH_SYSTEM_TYPE | nacos.plugin.auth.type | nacos；支持 ldap、oidc 和自定义插件 |
| NACOS_AUTH_ENABLE                       | 是否开启 Client API 鉴权；与 Admin、Console API 鉴权相互独立 | 未设置时使用镜像默认值（Nacos 3.3+ 为 `true`；旧镜像保留各自内置默认值）。显式 `true`/`false` 均可覆盖；`false` 仅建议作为有时限的升级兼容选择。                                                                                         |
| NACOS_AUTH_TOKEN_EXPIRE_SECONDS | nacos.plugin.auth.nacos.token.expire.seconds | 18000 |
| NACOS_AUTH_TOKEN | nacos.plugin.auth.nacos.token.secret.key | 必填；Base64，解码后至少 32 字节 |
| NACOS_AUTH_CACHE_ENABLE | nacos.plugin.auth.nacos.caching.enabled | false（保留 Docker 默认值） |
| MEMBER_LIST                             | 通过环境变量的方式设置集群地址                           | 例子:192.168.16.101:8847?raft_port=8807,192.168.16.101?raft_port=8808,192.168.16.101:8849?raft_port=8809                                                                                |
| EMBEDDED_STORAGE                        | 是否开启集群嵌入式存储模式                             | `embedded`  默认 : none                                                                                                                                                                 |
| NACOS_AUTH_IDENTITY_KEY                 | nacos.core.auth.server.identity.key；生产环境必须使用唯一值 | `注意：其默认值从 Nacos 2.2.1 起移除，必须显式设置。`                                                                                                                                                    |
| NACOS_AUTH_IDENTITY_VALUE               | nacos.core.auth.server.identity.value；生产环境必须使用唯一值 | `注意：其默认值从 Nacos 2.2.1 起移除，必须显式设置。`                                                                                                                                                    |
| NACOS_SECURITY_IGNORE_URLS | nacos.security.ignore.urls | 见配置模板，包含 /next/**、/legacy/** |
| DB_POOL_CONNECTION_TIMEOUT | nacos.plugin.datasource.db.pool.config.connection-timeout | 30000 ms |
| NACOS_CONSOLE_UI_ENABLED                | nacos.console.ui.enabled                  | default : `true`                                                                                                                                                                      |
| NACOS_CORE_PARAM_CHECK_ENABLED          | nacos.core.param.check.enabled            | default : `true`                                                                                                                                                                      |
| NACOS_AUTH_ADMIN_ENABLE                 | 独立控制 nacos.core.auth.admin.enabled     | default : `true`                                                                                                                                                                      |
| NACOS_AUTH_CONSOLE_ENABLE               | 独立控制 nacos.core.auth.console.enabled   | default : `true` |
| NACOS_CONSOLE_PORT                      | nacos.console.port                        | default : `8080`                                                                                                                                                                      |
| NACOS_CONSOLE_CONTEXTPATH               | nacos.console.contextPath                 | default : ``                                                                                                                                                                          |
| NACOS_DEPLOYMENT_TYPE                   | nacos.deployment.type                     | default : `merged` 支持配置 `server` `console`                                                                                                                                            |
| NACOS_EXT_PLUGIN_DIRS                   | 追加到 `loader.path` 的外挂插件或依赖目录              | 使用逗号分隔目录，例如 `/home/nacos/ext-plugins,/home/nacos/ext-libs`                                                                                                                            |
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

## 高级配置

复制 `build/conf/application.properties` 并按需修改，挂载到 `/home/nacos/conf/application.properties`。
使用 3.3 模板迁移旧配置，保留环境变量占位符；不要直接挂载整份 2.x/3.2 配置覆盖新模板。
自定义配置示例已经挂载 `example/init.d/application.properties`：

```shell
bash example/mysql-init.sh
docker compose -f example/custom-application-config.yaml up --build
```

如果你需要在不重建镜像的情况下加载额外的插件 jar 或依赖 jar，可以把这些目录挂载到容器内，
然后通过 `NACOS_EXT_PLUGIN_DIRS` 追加到 `loader.path`。

举个例子:

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

这个能力适合插件 jar 和运行时依赖 jar 需要分别挂载的场景。例如 LDAP 部署可以把 LDAP
鉴权插件 jar 放在一个目录，把所需的 `spring-ldap-core` 依赖 jar 放在另一个目录。

## 升级到 3.3.0-RC

此分支的 Dockerfile 和配置模板面向 3.3.0-RC，Java 仍使用 17。构建旧版 Nacos 请使用对应版本的仓库代码，不能只把此模板的 `NACOS_VERSION` 改回 3.2。

1. 先备份数据库及每个节点的 data、配置和插件。对照目标版本 schema 执行增量 DDL；`mysql-init.sh` 和 MySQL 示例 Dockerfile 只用于新库初始化，不会升级已有 MySQL 数据卷。
2. 外置数据库补齐 `ai_resource_search_document`、`ai_resource_search_chunk`、`ai_resource_task` 表及索引。Search 默认开启；临时关闭可设置 `NACOS_AI_RESOURCE_SEARCH_ENABLED=false`，此时不能开启 ARD。按实际 schema 检查 `permissions.resource` 扩容及对应数据库的其他变化，不要在生产库重跑完整初始化 SQL。
3. Docker 环境变量名称保留，但插件属性已迁到 canonical key：鉴权使用 `nacos.plugin.auth.*`，方言使用 `nacos.plugin.datasource-dialect.type`，连接和连接池使用 `nacos.plugin.datasource.db.*`。新键存在时优先于旧 alias，空值也不会回退。鉴权开关及 identity 仍使用 `nacos.core.auth.*`。
4. Client API 鉴权默认开启。首次部署从控制台初始化管理员密码，再登录获取 accessToken；客户端未迁移时可显式设置 `NACOS_AUTH_ENABLE=false`。所有节点的 token 和 identity 必须一致；即使关闭 Client 鉴权，JRaft 节点身份仍需要配置。
5. 保留节点原有 data；插件状态和运行时配置存储于 `data/plugin`，运行时持久化值可覆盖静态值。`.enabled` 是初始状态，已有状态请通过插件管理修改；`RESTART` 配置项仍需要重启。不要在节点间共用同一个 data 卷。
6. 仅挂载经过 3.3 兼容验证的外部插件。旧 AI Pipeline Builder、旧 AI Resource Import SPI 和已删除的配置迁移 Mapper 不能直接沿用。历史 A2A/MCP、Raft 数据和回滚边界按官方升级手册处理，不能只回退镜像标签。

详见 [3.3.0-RC 发布说明](https://github.com/alibaba/nacos/releases/tag/3.3.0-RC) 和 [next 升级手册](https://nacos.io/docs/next/manual/admin/upgrading/)。

## 数据持久化与可选能力

Compose 示例给每个 Nacos 服务挂载独立的 named volume 到 `/home/nacos/data`。更换镜像时复用原卷；`docker compose down -v` 会删除卷及其中的数据。独立 Console 也需要自己的 data 卷。集群控制台端口分别为宿主机的 8080、8081、8082。

旧部署如果没有挂载 data，需要在重建容器前逐节点导出 `/home/nacos/data`（例如 `docker cp <container>:/home/nacos/data ./data-backup`），再恢复到新卷，或直接 bind mount 导出的目录。新增空卷不会自动迁移旧容器可写层里的数据。

Standard/Slim 把内置 AI 数据包放在 `/home/nacos/data-seed`。启动时仅向 data 复制缺失的 zip，不覆盖已有包，因此空 bind mount 也能初始化。插件状态、Derby 和 Raft 文件均由持久卷保留。

```shell
# MCP、Skill、ARD 共用 9080，鉴权保持开启
docker compose -f example/standalone-ai-registry.yaml up
```

`NACOS_AI_REGISTRY_ENABLED` 继续只控制 MCP；Skill 和 ARD 各有独立开关。修改 Registry/DNS 端口后还需同步修改 Compose 端口映射。私网 MCP 工具导入需要显式配置允许的 IP/CIDR。

Standard/Slim 内置 Skill Scanner，SkillSpector 默认关闭。安装或挂载 SkillSpector 运行时后，设置 command 及 enabled；已有插件状态可能需要从控制台重新启用。Lite 默认 `FUNCTION_MODE=microservice` 并关闭 Pipeline，不内置 Python、扫描器或 AI 数据包，仓库已有的 `build/Dockerfile.Lite` 仅供自行构建，发布流程只发布 Standard/Slim。

## 本地验证

```shell
bash test/auth-defaults.sh
bash test/mysql-init.sh
docker build -f build/Dockerfile -t nacos-smoke:test build
bash example/mysql-init.sh
python3 test/docker-smoke.py --image nacos-smoke:test --mysql
```

真实镜像测试覆盖默认鉴权、显式关闭 Client 鉴权、配置映射、Registry 自定义端口、DNS TCP/UDP、插件配置及状态重建恢复，并验证 MySQL 和独立 Console。测试使用独立容器、网络和数据卷，结束后清理自身资源。

## Nacos + Grafana + Prometheus

使用参考：[Nacos monitor-guide](https://nacos.io/zh-cn/docs/monitor-guide.html)

**Note**:  当使用Grafana创建数据源的时候地址必须是: **http://prometheus:9090**
