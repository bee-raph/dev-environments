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

# Persist the choice so desktop VS Code and later Compose launches agree.
case "${1:-}" in
    --desktop|--browser)
        mode=${1#--}
        temporary=$(mktemp .env.mode.XXXXXX)
        chmod 600 "$temporary"
        awk '!/^[[:space:]]*EDITOR_MODE=/' .env > "$temporary"
        printf '\nEDITOR_MODE=%s\n' "$mode" >> "$temporary"
        mv "$temporary" .env
        shift
        ;;
esac

docker compose up --detach --build --wait "$@"
if [[ $(docker compose exec -T dev printenv EDITOR_MODE) == desktop ]]; then
    echo 'Desktop mode ready. Open this folder in VS Code and Reopen in Container.'
else
    echo 'Editor is ready. Default URL: http://localhost:8084'
fi
echo 'For local-machine use only; published ports are bound to localhost.'
