#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
if [[ ! -f .env ]]; then
    umask 077
    password="DevA1_$(LC_ALL=C od -An -N24 -tx1 /dev/urandom | tr -d ' \n')"
    printf 'DEVELOPER_PASSWORD=%s\n' "$password" > .env
    printf 'GOOGLE_CLOUD_PROJECT=developer-local\n' >> .env
    echo 'Created .env with local development credentials.'
fi
if ! docker network inspect dev-services >/dev/null 2>&1; then
    docker network create dev-services >/dev/null
fi
args=(-f compose.yaml)
if [[ "${1:-}" == --docker ]]; then
    args+=(-f compose.docker.yaml)
    shift
fi
docker compose "${args[@]}" up --detach --wait --wait-timeout 240 "$@"
echo 'Ready for local use. Configuration and credentials are in .env.'
