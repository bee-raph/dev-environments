#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
if [[ ! -f .env ]]; then
    umask 077
    random_password() { printf 'DevA1_'; LC_ALL=C od -An -N24 -tx1 /dev/urandom | tr -d ' \n'; }
    printf 'DEVELOPER_PASSWORD=%s\n' "$(random_password)" > .env
    printf 'SA_PASSWORD=%s\n' "$(random_password)" >> .env
    echo 'Created .env with generated service credentials.'
fi
if ! docker network inspect dev-services >/dev/null 2>&1; then
    docker network create dev-services >/dev/null
fi
docker compose up --build --detach --wait --wait-timeout 240 "$@"
docker compose run --rm --no-deps init
echo 'Ready for local use. Account: developer; password is in .env.'
