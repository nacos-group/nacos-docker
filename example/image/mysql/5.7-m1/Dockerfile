ARG TARGETPLATFORM
FROM --platform=${TARGETPLATFORM:-linux/amd64} mysql:5.7.40
ADD https://raw.githubusercontent.com/alibaba/nacos/develop/plugin-default-impl/nacos-default-datasource-plugin/nacos-datasource-plugin-mysql/src/main/resources/META-INF/mysql-schema.sql /docker-entrypoint-initdb.d/nacos-mysql.sql
RUN chown -R mysql:mysql /docker-entrypoint-initdb.d/nacos-mysql.sql
EXPOSE 3306
CMD ["mysqld", "--character-set-server=utf8mb4", "--collation-server=utf8mb4_unicode_ci"]