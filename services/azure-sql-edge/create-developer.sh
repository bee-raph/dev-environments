#!/usr/bin/env bash
set -euo pipefail
: "${DEVELOPER_PASSWORD:?Set DEVELOPER_PASSWORD}"
# Escape SQL string literals; credentials never enter an image or source file.
password_sql=${DEVELOPER_PASSWORD//\'/\'\'}
/usr/local/bin/sqlcmd -S azure-sql-edge -U sa -C -b -Q "
IF DB_ID(N'app') IS NULL CREATE DATABASE [app];
IF SUSER_ID(N'developer') IS NULL
  CREATE LOGIN [developer] WITH PASSWORD=N'$password_sql', CHECK_POLICY=ON;
ELSE
  ALTER LOGIN [developer] WITH PASSWORD=N'$password_sql';
ALTER SERVER ROLE [sysadmin] ADD MEMBER [developer];
"
echo 'Developer login configured with sysadmin rights.'
