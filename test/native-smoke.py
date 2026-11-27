#!/usr/bin/env python3
# Copyright 1999-2026 Alibaba Group Holding Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""Run a Native Server image against a real database.

Usage: python3 test/native-smoke.py --datasource {mysql,postgresql} --image IMAGE --nacos-source DIR

IMAGE is built by build/Dockerfile.Native from a Native archive of alibaba/nacos. DIR is the source tree that
archive was built from; the database schema is read from it. The test starts the database and the image in
merged standalone mode, then checks readiness, the process, administrator setup and login, configuration
publishing and reads, the console, two refused configurations, a restart on the same database and docker stop.
Requires Docker. Every container and network it creates is removed on exit.
"""

import argparse
import base64
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid

ROOT = Path(__file__).resolve().parent.parent
TEMPLATE = ROOT / "build" / "conf" / "application-native.properties"
SCHEMAS = {
    "mysql": "plugin-default-impl/nacos-default-datasource-plugin/nacos-datasource-plugin-mysql/"
             "src/main/resources/META-INF/mysql-schema.sql",
    "postgresql": "plugin-default-impl/nacos-default-datasource-plugin/nacos-datasource-plugin-postgresql/"
                  "src/main/resources/META-INF/pg-schema.sql",
}
DATABASE_IMAGES = {"mysql": "mysql:8.0", "postgresql": "postgres:17"}
# Keys of the template that name the MySQL database. A PostgreSQL run replaces them.
MYSQL_KEYS = (
    "nacos.plugin.datasource-dialect.type",
    "nacos.plugin.datasource.db.url.0",
    "nacos.plugin.datasource.db.user.0",
    "nacos.plugin.datasource.db.password.0",
)
DB_NAME = "nacos"
DB_USER = "nacos"
# The parameters of env/nacos-standalone-mysql.env: MySQL 8 needs the public key for a login without TLS.
MYSQL_PARAMS = "characterEncoding=utf8&useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC"
CONFIG_PATH = "/nacos/v3/client/cs/config?dataId=native-smoke&groupName=DEFAULT_GROUP"


def docker(*args, check=True, timeout=None):
    result = subprocess.run(["docker", *args], text=True, stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE, timeout=timeout)
    if check and result.returncode:
        raise RuntimeError(f"docker {args[0]} failed with {result.returncode}: {result.stderr.strip()}")
    return result.stdout.strip()


def logs(name):
    result = subprocess.run(["docker", "logs", name], text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    return result.stdout


def request(base, path, method="GET", form=None, token=None):
    headers = {"accessToken": token} if token else {}
    data = urllib.parse.urlencode(form).encode() if form is not None else None
    req = urllib.request.Request(base + path, data=data, headers=headers, method=method)
    try:
        response = urllib.request.urlopen(req, timeout=10)
    except urllib.error.HTTPError as error:
        response = error
    with response:
        raw = response.read().decode(errors="replace")
        try:
            body = json.loads(raw)
        except ValueError:
            body = raw
        return response.status, body


def success(result):
    status, body = result
    assert status == 200 and isinstance(body, dict) and body.get("code") == 0, result
    return body.get("data")


def eventually(description, attempt, timeout):
    """Returns the first value of attempt() that is not None. Connection errors are retried."""
    deadline = time.monotonic() + timeout
    last = None
    while time.monotonic() < deadline:
        try:
            value = attempt()
            if value is not None:
                return value
        except (urllib.error.URLError, OSError, RuntimeError) as error:
            last = error
        time.sleep(2)
    raise AssertionError(f"{description} timed out: {last}")


def wait_config(base, expected, token):
    # Publishing persists to the database before the asynchronous dump reaches the Client API reads.
    def attempt():
        status, body = request(base, CONFIG_PATH, token=token)
        if status == 200 and isinstance(body, dict) and body.get("code") == 20004:
            return None
        data = success((status, body))
        return data if data.get("content") == expected else None

    eventually("configuration read", attempt, timeout=60)


class NativeSmoke:
    def __init__(self, datasource, image, nacos_source):
        self.datasource = datasource
        self.image = image
        self.nacos_source = Path(nacos_source).resolve()
        self.prefix = "native-smoke-" + uuid.uuid4().hex[:10]
        self.network = self.prefix + "-net"
        self.database = self.prefix + "-db"
        self.containers = []
        self.db_password = "db-" + uuid.uuid4().hex
        self.admin_password = "Admin-" + uuid.uuid4().hex
        self.workdir = Path(tempfile.mkdtemp(prefix=self.prefix + "-"))
        self.env = {
            "MODE": "standalone",
            "NACOS_NATIVE_OPTS": "-Xmx1g",
            "NACOS_AUTH_TOKEN": base64.b64encode(os.urandom(32)).decode(),
            "NACOS_AUTH_IDENTITY_KEY": "smokeIdentity",
            "NACOS_AUTH_IDENTITY_VALUE": uuid.uuid4().hex,
        }

    def start_database(self):
        schema = self.nacos_source / SCHEMAS[self.datasource]
        assert schema.is_file(), f"Schema not found: {schema}"
        docker("network", "create", self.network)
        self.containers.append(self.database)
        if self.datasource == "mysql":
            env = {"MYSQL_ROOT_PASSWORD": self.db_password, "MYSQL_DATABASE": DB_NAME,
                   "MYSQL_USER": DB_USER, "MYSQL_PASSWORD": self.db_password}
        else:
            env = {"POSTGRES_USER": DB_USER, "POSTGRES_PASSWORD": self.db_password, "POSTGRES_DB": DB_NAME}
        args = ["run", "-d", "--name", self.database, "--network", self.network,
                "-v", f"{schema}:/docker-entrypoint-initdb.d/nacos.sql:ro"]
        for key, value in env.items():
            args += ["-e", f"{key}={value}"]
        docker(*args, DATABASE_IMAGES[self.datasource])
        eventually(f"{self.datasource} schema", self.database_ready, timeout=300)

    def database_ready(self):
        # The image runs its init scripts on a temporary server without TCP, so only the final server
        # answers on 127.0.0.1.
        if self.datasource == "mysql":
            command = ["mysql", "-h127.0.0.1", f"-u{DB_USER}", f"-p{self.db_password}", DB_NAME,
                       "-e", "SELECT COUNT(*) FROM config_info"]
            environment = []
        else:
            command = ["psql", "-h", "127.0.0.1", "-U", DB_USER, "-d", DB_NAME, "-tAc",
                       "SELECT COUNT(*) FROM config_info"]
            environment = ["-e", f"PGPASSWORD={self.db_password}"]
        try:
            docker("exec", *environment, self.database, *command)
        except RuntimeError:
            return None
        return True

    def database_settings(self):
        if self.datasource == "mysql":
            settings = {"MYSQL_SERVICE_HOST": self.database, "MYSQL_SERVICE_PORT": "3306",
                        "MYSQL_SERVICE_DB_NAME": DB_NAME, "MYSQL_SERVICE_USER": DB_USER,
                        "MYSQL_SERVICE_PASSWORD": self.db_password, "MYSQL_SERVICE_DB_PARAM": MYSQL_PARAMS}
            return settings, []
        return {}, [f"{self.write_postgresql_config()}:/home/nacos/conf/application.properties:ro"]

    def write_postgresql_config(self):
        # The image's template names MySQL. A PostgreSQL run mounts the same template with its own datasource keys.
        lines = TEMPLATE.read_text().splitlines()
        kept = [line for line in lines if line.split("=", 1)[0] not in MYSQL_KEYS]
        assert len(lines) - len(kept) == len(MYSQL_KEYS), "The template must set each MySQL datasource key once"
        kept += [
            "nacos.plugin.datasource-dialect.type=postgresql",
            f"nacos.plugin.datasource.db.url.0=jdbc:postgresql://{self.database}:5432/{DB_NAME}",
            f"nacos.plugin.datasource.db.user.0={DB_USER}",
            f"nacos.plugin.datasource.db.password.0={self.db_password}",
            "nacos.plugin.datasource.db.pool.config.driver-class-name=org.postgresql.Driver",
        ]
        path = self.workdir / "application-postgresql.properties"
        path.write_text("\n".join(kept) + "\n")
        return path

    def start_server(self, name, env=None):
        settings, mounts = self.database_settings()
        args = ["run", "-d", "--name", name, "--network", self.network,
                "-p", "127.0.0.1::8848", "-p", "127.0.0.1::8080"]
        for key, value in {**self.env, **settings, **(env or {})}.items():
            args += ["-e", f"{key}={value}"]
        for mount in mounts:
            args += ["-v", mount]
        self.containers.append(name)
        docker(*args, self.image)
        return name

    @staticmethod
    def base(name, port):
        return "http://" + docker("port", name, f"{port}/tcp").splitlines()[0]

    @staticmethod
    def wait_ready(base, name):
        def attempt():
            # A container that has stopped will not become ready, so fail at once instead of waiting.
            if docker("inspect", "-f", "{{.State.Running}}", name) != "true":
                raise AssertionError(f"{name} stopped before it was ready")
            status, body = request(base, "/nacos/v3/admin/core/state/readiness")
            return True if status == 200 and isinstance(body, dict) and body.get("code") == 0 else None

        eventually("readiness", attempt, timeout=240)

    def check_process(self, name):
        assert docker("exec", name, "cat", "/proc/1/comm") == "nacos-server", "The executable is not PID 1"
        assert docker("exec", name, "id", "-u") == "1000", "The Server does not run as uid 1000"

    def login(self, base, initialize=False):
        if initialize:
            success(request(base, "/nacos/v3/auth/user/admin", "POST", {"password": self.admin_password}))
        status, body = request(base, "/nacos/v3/auth/user/login", "POST",
                               {"username": "nacos", "password": self.admin_password})
        assert status == 200 and isinstance(body, dict) and body.get("accessToken"), (status, body)
        return body["accessToken"]

    @staticmethod
    def publish(base, token):
        content = "native-" + uuid.uuid4().hex
        config = {"dataId": "native-smoke", "groupName": "DEFAULT_GROUP", "content": content}
        success(request(base, "/nacos/v3/admin/cs/config", "POST", config, token))
        wait_config(base, content, token)
        return content

    @staticmethod
    def check_console(console):
        def attempt():
            status, body = request(console, "/v3/console/health/readiness")
            return True if status == 200 and isinstance(body, dict) and body.get("code") == 0 else None

        eventually("console readiness", attempt, timeout=60)
        status, body = request(console, "/next/")
        assert status == 200 and "<html" in body.lower(), f"The console UI is not served: {status}"

    def refuse(self, env, expected):
        name = self.prefix + "-refused-" + uuid.uuid4().hex[:6]
        self.start_server(name, env)
        exit_code = int(docker("wait", name, timeout=300))
        output = logs(name)
        if expected not in output:
            # The root logger writes to logs/ only, so a message of the Server is read from there.
            copied = self.workdir / ("refused-" + uuid.uuid4().hex[:6])
            copied.mkdir()
            docker("cp", f"{name}:/home/nacos/logs/.", str(copied))
            for path in sorted(copied.rglob("*")):
                if path.is_file():
                    output += "\n" + path.read_text(errors="replace")
        assert exit_code != 0 and expected in output, (
            f"The Server should refuse {env} with '{expected}', exit {exit_code}:\n{output[-2000:]}")

    def run(self):
        self.start_database()
        name = self.start_server(self.prefix + "-server")
        base = self.base(name, 8848)
        started = time.monotonic()
        self.wait_ready(base, name)
        print(f"PASS: ready {time.monotonic() - started:.1f}s after start", flush=True)
        self.check_process(name)
        token = self.login(base, initialize=True)
        content = self.publish(base, token)
        self.check_console(self.base(name, 8080))
        print("PASS: process, administrator, configuration and console", flush=True)

        self.refuse({"MODE": "cluster"}, "does not match this executable")
        self.refuse({"NACOS_AI_RESOURCE_SEARCH_ENABLED": "false"},
                    "AOT artifact mismatch for nacos.ai.resource.search.enabled")
        print("PASS: refused a cluster mode and a changed AI resource search switch", flush=True)

        docker("restart", name)
        base = self.base(name, 8848)
        self.wait_ready(base, name)
        token = self.login(base)
        wait_config(base, content, token)
        print("PASS: restart on the same database keeps the configuration", flush=True)

        started = time.monotonic()
        docker("stop", "-t", "15", name)
        stopped = time.monotonic() - started
        assert stopped < 15, f"docker stop took {stopped:.1f}s, so the Server did not exit on SIGTERM"
        print(f"PASS: docker stop in {stopped:.1f}s", flush=True)

    def cleanup(self, failed):
        for name in reversed(self.containers):
            if failed:
                state = docker("inspect", "-f", "{{.State.Status}} exit={{.State.ExitCode}}", name, check=False)
                print(f"--- {name}: {state}\n{logs(name)}", flush=True)
            docker("rm", "-f", "-v", name, check=False)
        docker("network", "rm", self.network, check=False)
        shutil.rmtree(self.workdir, ignore_errors=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--datasource", choices=sorted(SCHEMAS), required=True)
    parser.add_argument("--image", required=True)
    parser.add_argument("--nacos-source", required=True,
                        help="Source tree of the archive; the database schema is read from it")
    args = parser.parse_args()
    test = NativeSmoke(args.datasource, args.image, args.nacos_source)
    failed = True
    try:
        test.run()
        failed = False
    finally:
        test.cleanup(failed)
    print(f"PASS: native image on {args.datasource}", flush=True)


if __name__ == "__main__":
    main()
