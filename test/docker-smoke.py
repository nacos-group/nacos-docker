#!/usr/bin/env python3
# Copyright 1999-2026 Alibaba Group Holding Ltd.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""Exercise the built image, including canonical configuration and volume recovery.

Usage: python3 test/docker-smoke.py --image nacos-smoke:test [--lite] [--mysql]
Requires Docker and, for --mysql, example/mysql-init/mysql-schema.sql.
All containers, networks and volumes created by this test are removed on exit.
"""

import argparse
import base64
import json
import os
from pathlib import Path
import socket
import struct
import subprocess
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid


def docker(*args, check=True):
    result = subprocess.run(["docker", *args], text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if check and result.returncode:
        print(result.stderr, flush=True)
        result.check_returncode()
    return (result.stdout + (result.stderr if args[0] == "logs" else "")).strip()


def request(base, path, method="GET", form=None, token=None):
    headers = {"accessToken": token} if token else {}
    data = urllib.parse.urlencode(form).encode() if form is not None else None
    req = urllib.request.Request(base + path, data=data, headers=headers, method=method)
    try:
        response = urllib.request.urlopen(req, timeout=5)
    except urllib.error.HTTPError as error:
        response = error
    with response:
        raw = response.read().decode()
        try:
            body = json.loads(raw)
        except ValueError:
            body = raw
        return response.status, body


def success(result):
    status, body = result
    assert status == 200 and isinstance(body, dict) and body.get("code") == 0, result
    return body.get("data")


def wait_ready(base, path):
    deadline = time.monotonic() + 180
    last = None
    while time.monotonic() < deadline:
        try:
            last = request(base, path)
            if last[0] == 200 and isinstance(last[1], dict) and last[1].get("code") == 0:
                return
        except (urllib.error.URLError, TimeoutError, OSError) as error:
            last = str(error)
        time.sleep(2)
    raise AssertionError(f"Readiness timeout at {base}{path}: {last}")


def wait_config(base, path, expected_content, token):
    # Publishing persists to MySQL before the asynchronous dump reaches Client API reads.
    deadline = time.monotonic() + 30
    last = None
    while time.monotonic() < deadline:
        last = request(base, path, token=token)
        status, body = last
        if status == 200 and isinstance(body, dict) and body.get("code") == 20004:
            # Only retry RESOURCE_NOT_FOUND while the new config is being dumped.
            time.sleep(0.5)
            continue
        data = success(last)
        assert isinstance(data, dict) and data.get("content") == expected_content, last
        return
    raise AssertionError(f"Config propagation timeout at {base}{path}: {last}")


def check_dns(name):
    # An absent service must receive NXDOMAIN on both published transports.
    query_id = 12345
    domain = "absent-" + uuid.uuid4().hex + ".nacos"
    question = b"".join(bytes([len(label)]) + label.encode() for label in domain.split("."))
    query = struct.pack("!6H", query_id, 0x0100, 1, 0, 0, 0) + question + b"\0\0\1\0\1"
    for protocol in ("udp", "tcp"):
        host, port = docker("port", name, f"15353/{protocol}").splitlines()[0].rsplit(":", 1)
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM if protocol == "udp" else socket.SOCK_STREAM) as sock:
            sock.settimeout(5)
            sock.connect((host, int(port)))
            if protocol == "udp":
                sock.send(query)
                response = sock.recv(4096)
            else:
                sock.sendall(struct.pack("!H", len(query)) + query)
                with sock.makefile("rb") as stream:
                    length = struct.unpack("!H", stream.read(2))[0]
                    response = stream.read(length)
            response_id, flags = struct.unpack("!HH", response[:4])
            assert response_id == query_id and flags & 0x8000 and flags & 0xF == 3, response


class SmokeTest:
    def __init__(self, image):
        self.image = image
        self.prefix = "nacos-smoke-" + uuid.uuid4().hex[:10]
        self.containers = []
        self.volumes = []
        self.network = None
        self.password = "SmokeTest-" + uuid.uuid4().hex
        self.env = {
            "MODE": "standalone", "JVM_XMS": "256m", "JVM_XMX": "768m", "JVM_XMN": "128m",
            "NACOS_AUTH_TOKEN": base64.b64encode(os.urandom(32)).decode(),
            "NACOS_AUTH_IDENTITY_KEY": "smokeIdentity",
            "NACOS_AUTH_IDENTITY_VALUE": uuid.uuid4().hex,
        }

    def volume(self, suffix):
        name = self.prefix + "-" + suffix
        docker("volume", "create", name)
        self.volumes.append(name)
        return name

    def start(self, suffix, env=None, volume=None, ports=(8848, 8080), extra=()):
        name = self.prefix + "-" + suffix
        args = ["run", "-d", "--name", name]
        if self.network:
            args += ["--network", self.network]
        for key, value in {**self.env, **(env or {})}.items():
            args += ["-e", f"{key}={value}"]
        for port in ports:
            args += ["-p", f"127.0.0.1::{port}"]
        if volume:
            args += ["-v", f"{volume}:/home/nacos/data"]
        self.containers.append(name)
        docker(*args, *extra, self.image)
        return name

    @staticmethod
    def base(name, port=8848):
        binding = docker("port", name, f"{port}/tcp").splitlines()[0]
        return "http://" + binding

    def ready(self, name, console=False):
        base = self.base(name, 8080 if console else 8848)
        path = "/v3/console/health/readiness" if console else "/nacos/v3/admin/core/state/readiness"
        wait_ready(base, path)
        return base

    def login(self, base, initialize=False):
        if initialize:
            success(request(base, "/nacos/v3/auth/user/admin", "POST", {"password": self.password}))
        status, body = request(base, "/nacos/v3/auth/user/login", "POST",
                               {"username": "nacos", "password": self.password})
        assert status == 200 and body.get("accessToken"), (status, body)
        return body["accessToken"]

    def client_roundtrip(self, base, token=None):
        form = {"serviceName": "docker.smoke", "ip": "127.0.0.1", "port": "8081", "ephemeral": "false"}
        success(request(base, "/nacos/v3/client/ns/instance", "POST", form, token))
        path = "/nacos/v3/client/ns/instance/list?serviceName=docker.smoke"
        result = success(request(base, path, token=token))
        assert any(host["ip"] == "127.0.0.1" and host["port"] == 8081 for host in result), result

    def standalone(self, lite=False):
        volume = self.volume("data")
        env = {"NACOS_AUTH_TOKEN_EXPIRE_SECONDS": "3600"}
        # Exercise the canonical Registry port with a non-default value.
        if not lite:
            env.update(NACOS_AI_REGISTRY_ENABLED="true", NACOS_AI_SKILL_REGISTRY_ENABLED="true",
                       NACOS_AI_ARD_ENABLED="true", NACOS_AI_REGISTRY_PORT="19080",
                       NACOS_NAMING_DNS_ENABLED="true", NACOS_NAMING_DNS_PORT="15353")
        ports = (8848, 8080) if lite else (8848, 8080, 19080)
        dns_ports = () if lite else ("-p", "127.0.0.1::15353/tcp", "-p", "127.0.0.1::15353/udp")
        name = self.start("default", env, volume, ports, dns_ports)
        base = self.ready(name)
        self.ready(name, console=True)
        status, _ = request(base, "/nacos/v3/client/ns/instance/list?serviceName=docker.smoke")
        assert status in (401, 403), "Default Client API auth was not enforced"
        token = self.login(base, initialize=True)
        self.client_roundtrip(base, token)
        plugin = "/nacos/v3/admin/core/plugin/"
        query = "?pluginType=auth&pluginName=nacos"
        detail = success(request(base, plugin + "detail" + query, token=token))
        assert str(detail["config"]["token.expire.seconds"]) == "3600", detail
        success(request(base, plugin + "config", "PUT", {
            "pluginType": "auth", "pluginName": "nacos",
            "config": json.dumps({"token.expire.seconds": "2400"}),
        }, token))
        if not lite:
            docker("exec", name, "skill-scanner", "--help")
            for archive in ("skills-data.zip", "agentspec-data.zip"):
                docker("exec", name, "test", "-s", "/home/nacos/data/" + archive)
            registry = self.base(name, 19080)
            # Any HTTP response proves the adaptor bound the requested port.
            deadline = time.monotonic() + 30
            while True:
                try:
                    request(registry, "/", token=token)
                    check_dns(name)
                    break
                except (urllib.error.URLError, TimeoutError, OSError):
                    if time.monotonic() >= deadline:
                        raise
                    time.sleep(1)
            scanner = success(request(base, plugin + "detail?pluginType=ai-pipeline&pluginName=skill-scanner", token=token))
            assert scanner["enabled"] is True, scanner
            spector = success(request(base, plugin + "detail?pluginType=ai-pipeline&pluginName=skill-spector", token=token))
            assert spector["enabled"] is False, spector
            success(request(base, plugin + "status", "PUT", {
                "pluginType": "ai-pipeline", "pluginName": "skill-scanner", "enabled": "false",
            }, token))
        docker("stop", "-t", "15", name)
        docker("rm", name)
        # Recreate the container with the same volume: runtime overrides must survive.
        name = self.start("recreated", env, volume, ports, dns_ports)
        base = self.ready(name)
        token = self.login(base)
        detail = success(request(base, plugin + "detail" + query, token=token))
        assert str(detail["config"]["token.expire.seconds"]) == "2400", detail
        if not lite:
            scanner = success(request(base, plugin + "detail?pluginType=ai-pipeline&pluginName=skill-scanner", token=token))
            assert scanner["enabled"] is False, scanner
        docker("stop", "-t", "15", name)
        # Explicit false changes Client auth only; Admin and Console stay protected.
        name = self.start("auth-false", {"NACOS_AUTH_ENABLE": "false"})
        base = self.ready(name)
        self.client_roundtrip(base)
        assert request(base, plugin + "list")[0] in (401, 403)
        console = self.ready(name, console=True)
        assert request(console, "/v3/console/plugin/list")[0] in (401, 403)
        docker("stop", "-t", "15", name)
        print("PASS: default auth, explicit false and plugin persistence" +
              ("" if lite else ", Registry port and DNS TCP/UDP"), flush=True)

    def mysql_console(self, schema):
        assert schema.is_file(), "Run bash example/mysql-init.sh before --mysql"
        self.network = self.prefix + "-network"
        docker("network", "create", self.network)
        mysql = self.prefix + "-mysql"
        self.containers.append(mysql)
        docker("run", "-d", "--name", mysql, "--network", self.network,
               "-e", "MYSQL_ROOT_PASSWORD=smoke-root", "-e", "MYSQL_DATABASE=nacos",
               "-e", "MYSQL_USER=nacos", "-e", "MYSQL_PASSWORD=smoke-db",
               "-v", f"{schema}:/docker-entrypoint-initdb.d/nacos.sql:ro",
               os.environ.get("MYSQL_TEST_IMAGE", "mysql:8.0"))
        deadline = time.monotonic() + 120
        while time.monotonic() < deadline:
            try:
                docker("exec", mysql, "mysql", "-h127.0.0.1", "-unacos", "-psmoke-db",
                       "nacos", "-e", "SELECT COUNT(*) FROM ai_resource_task")
                break
            except subprocess.CalledProcessError:
                time.sleep(2)
        else:
            raise AssertionError("MySQL schema initialization timed out")
        env = {"SPRING_DATASOURCE_PLATFORM": "mysql", "MYSQL_SERVICE_HOST": mysql,
               "MYSQL_SERVICE_DB_NAME": "nacos", "MYSQL_SERVICE_USER": "nacos",
               "MYSQL_SERVICE_PASSWORD": "smoke-db",
               "MYSQL_SERVICE_DB_PARAM": "useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC",
               "NACOS_DEPLOYMENT_TYPE": "server"}
        server = self.start("mysql-server", env, self.volume("mysql-server-data"), (8848,))
        base = self.ready(server)
        token = self.login(base, initialize=True)
        self.client_roundtrip(base, token)
        config = {"dataId": "docker-smoke", "groupName": "DEFAULT_GROUP", "content": "mysql-roundtrip"}
        success(request(base, "/nacos/v3/admin/cs/config", "POST", config, token))
        wait_config(base, "/nacos/v3/client/cs/config?dataId=docker-smoke&groupName=DEFAULT_GROUP",
                    config["content"], token)
        env.update(NACOS_DEPLOYMENT_TYPE="console", MEMBER_LIST=server + ":8848")
        console = self.start("console", env, self.volume("console-data"), (8080,))
        console_base = self.ready(console, console=True)
        success(request(console_base, "/v3/console/plugin/list", token=token))
        print("PASS: MySQL schema/config and independent Console with authentication", flush=True)

    def cleanup(self, failed):
        for name in reversed(self.containers):
            if failed:
                print(docker("logs", "--tail", "100", name, check=False), flush=True)
            docker("rm", "-f", "-v", name, check=False)
        for name in self.volumes:
            docker("volume", "rm", name, check=False)
        if self.network:
            docker("network", "rm", self.network, check=False)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--image", required=True)
    parser.add_argument("--lite", action="store_true")
    parser.add_argument("--mysql", action="store_true")
    args = parser.parse_args()
    test = SmokeTest(args.image)
    failed = True
    try:
        test.standalone(args.lite)
        if args.mysql:
            test.mysql_console(Path(__file__).resolve().parents[1] / "example/mysql-init/mysql-schema.sql")
        failed = False
    finally:
        test.cleanup(failed)
