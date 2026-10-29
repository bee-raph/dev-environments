#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
docker compose run --rm --no-deps --entrypoint /bin/bash init -ec '
export SQLCMDPASSWORD="$DEVELOPER_PASSWORD"
sqlcmd -S azure-sql-edge -U developer -d app -C -b -Q "
SET NOCOUNT ON;
IF IS_SRVROLEMEMBER(N'\''sysadmin'\'') <> 1 THROW 50001, '\''Developer must be sysadmin'\'', 1;
CREATE TABLE #developer_smoke (value int NOT NULL);
INSERT INTO #developer_smoke VALUES (42);
IF (SELECT value FROM #developer_smoke) <> 42 THROW 50002, '\''Read/write failed'\'', 1;
DROP TABLE #developer_smoke;
SELECT @@VERSION AS engine_version;
SELECT '\''Developer administrator query and write/read/delete passed.'\'' AS result;
"
'
image=$(docker compose images -q azure-sql-edge | head -n 1)
printf 'Container image architecture: '
docker image inspect "$image" --format '{{.Architecture}}'
