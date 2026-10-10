#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p src
if [[ ! -f .env ]]; then
    umask 077
    touch .env
    # Linux bind mounts need the host user's numeric IDs. Docker Desktop
    # handles macOS bind mount ownership without changing the container UID.
    if [[ $(uname -s) == Linux ]]; then
        printf 'DEV_UID=%s\nDEV_GID=%s\n' "$(id -u)" "$(id -g)" >> .env
    fi
    echo 'Created .env for optional local settings.'
fi
docker compose up --detach --build --wait "$@"
echo 'Editor is ready. Default URL: http://localhost:8085'
echo 'For local-machine use only; published ports are bound to localhost.'
