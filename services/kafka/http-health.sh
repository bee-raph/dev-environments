#!/usr/bin/env bash
set -euo pipefail
exec 3<>/dev/tcp/127.0.0.1/8083
credentials=$(printf 'developer:%s' "$DEVELOPER_PASSWORD" | base64 | tr -d '\n')
printf 'GET /connectors HTTP/1.0\r\nHost: localhost\r\nAuthorization: Basic %s\r\n\r\n' "$credentials" >&3
read -r _protocol status _rest <&3
[[ "$status" == 200 ]]
