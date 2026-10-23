#!/usr/bin/env python3
# Copyright 1999-2026 Alibaba Group Holding Ltd.
#
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

"""Exercise standalone MySQL mounts using isolated containers and volumes."""

import json
from pathlib import Path
import subprocess
import tempfile
import time
import uuid


ROOT = Path(__file__).resolve().parent.parent


def run(*args, check=True):
    return subprocess.run(args, check=check, text=True, capture_output=True)


def check_example(example):
    config = json.loads(run(
        "docker", "compose", "--env-file", str(ROOT / "example/.env"),
        "-f", str(ROOT / "example" / example), "config", "--format", "json",
    ).stdout)
    mysql = config["services"]["mysql"]
    # Keep the example's mount options, environment and health check, but isolate
    # every resource from deployed examples and avoid publishing host ports.
    mysql.pop("container_name", None)
    mysql.pop("ports", None)
    project = "nacos-schema-test-" + uuid.uuid4().hex[:12]
    with tempfile.TemporaryDirectory(prefix=project) as directory:
        schema = Path(directory) / "mysql-schema.sql"
        found = False
        for volume in mysql["volumes"]:
            if volume["target"] == "/var/lib/mysql":
                volume.clear()
                volume.update(type="volume", source="mysql-data", target="/var/lib/mysql")
            elif volume["target"].startswith("/docker-entrypoint-initdb.d"):
                volume["source"] = str(schema)
                found = True
        assert found, "MySQL initialization mount is missing"
        compose_file = Path(directory) / "compose.json"
        compose_file.write_text(json.dumps({
            "services": {"mysql": mysql}, "volumes": {"mysql-data": {}},
        }))
        command = ("docker", "compose", "-p", project, "-f", str(compose_file))
        try:
            missing = run(*command, "up", "-d", check=False)
            assert missing.returncode != 0, "Missing schema must prevent startup"
            assert str(schema) in missing.stderr, missing.stderr
            assert not schema.exists(), "Compose must not create a directory for missing SQL"
            # A minimal schema proves the mounted SQL is executed by MySQL.
            schema.write_text("CREATE TABLE schema_probe (id INT PRIMARY KEY);\n"
                              "INSERT INTO schema_probe VALUES (1);\n")
            for attempt in range(2):
                run(*command, "up", "-d")
                deadline = time.monotonic() + 120
                while True:
                    query = run(*command, "exec", "-T", "mysql", "sh", "-c",
                                'MYSQL_PWD="$MYSQL_PASSWORD" mysql -h127.0.0.1 '
                                '-u"$MYSQL_USER" -D"$MYSQL_DATABASE" -Nse '
                                "'SELECT COUNT(*) FROM schema_probe'", check=False)
                    if query.returncode == 0 and query.stdout.strip() == "1":
                        break
                    if time.monotonic() >= deadline:
                        raise AssertionError(run(*command, "logs", "mysql").stdout)
                    time.sleep(2)
                # Retain the data volume: a second startup must preserve data
                # without rerunning CREATE TABLE against the existing database.
                if attempt == 0:
                    run(*command, "down")
            print(f"{example}: missing schema rejected; initialization and reuse passed")
        finally:
            run(*command, "down", "--volumes", "--remove-orphans", check=False)


if __name__ == "__main__":
    for name in ("standalone-mysql.yaml", "standalone-independent-mysql.yaml"):
        check_example(name)
