#!/bin/sh
set -eu
: "${DEVELOPER_PASSWORD:?Set DEVELOPER_PASSWORD in .env}"
password_hash=$(printf '%s' "$DEVELOPER_PASSWORD" | sha256sum | cut -d ' ' -f 1)
printf 'user default off\nuser developer on #%s ~* &* +@all\n' "$password_hash" > /tmp/developer-users.acl
exec /usr/local/bin/docker-entrypoint.sh redis-server \
    --bind 0.0.0.0 --aclfile /tmp/developer-users.acl \
    --appendonly yes --dir /data
