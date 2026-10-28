#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
if [[ ! -f .env ]]; then
    umask 077
    password="DevA1_$(LC_ALL=C od -An -N24 -tx1 /dev/urandom | tr -d ' \n')"
    cluster_id=$(LC_ALL=C head -c 16 /dev/urandom | base64 | tr '+/' '-_' | tr -d '=\n')
    printf 'DEVELOPER_PASSWORD=%s\nKAFKA_CLUSTER_ID=%s\n' "$password" "$cluster_id" > .env
    echo 'Created .env with generated developer credentials and cluster ID.'
fi
if ! docker network inspect dev-services >/dev/null 2>&1; then
    docker network create dev-services >/dev/null
fi
docker compose run --rm --no-deps init
docker compose up --detach --wait --wait-timeout 360 "$@"
echo 'Kafka ready: localhost:9092, localhost:9093, localhost:9094'
echo 'UI: http://localhost:8090; schema registry: http://localhost:18081; Connect: http://localhost:18083'
echo 'All service accounts use developer; password is in .env.'
