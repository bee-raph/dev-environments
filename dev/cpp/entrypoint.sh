#!/usr/bin/env bash
set -euo pipefail

# Desktop mode keeps the container alive for VS Code Dev Containers.
case "${EDITOR_MODE:-browser}" in
    browser) ;;
    desktop)
        if [[ "${1:-}" == --healthcheck ]]; then
            [[ -f /tmp/dev-desktop-ready ]]
            exit
        fi
        ;;
    *) echo 'EDITOR_MODE must be browser or desktop.' >&2; exit 1 ;;
esac
if [[ "${1:-}" == --healthcheck ]]; then
    exec curl --fail --silent http://127.0.0.1:8080/healthz
fi
rm -f /tmp/dev-desktop-ready
mkdir -p "$HOME/.config/git" "$CODEX_HOME" "$CLAUDE_CONFIG_DIR"
chmod 700 "$CODEX_HOME" "$CLAUDE_CONFIG_DIR"
mkdir -p "$HOME/.config/opencode" "$HOME/.local/share/opencode"
chmod 700 "$HOME/.config/opencode" "$HOME/.local/share/opencode"
if [[ "${EDITOR_MODE:-browser}" == desktop ]]; then
    touch /tmp/dev-desktop-ready
    exec sleep infinity
fi
# Seed extensions only once, so user additions and removals persist.
data_dir="$HOME/.local/share/code-server"
if [[ ! -f "$data_dir/.extensions-seeded" ]]; then
    mkdir -p "$data_dir/extensions"
    cp -a /opt/editor-extensions/. "$data_dir/extensions/"
    touch "$data_dir/.extensions-seeded"
fi
exec code-server --bind-addr 0.0.0.0:8080 --auth none \
    --disable-telemetry --disable-update-check /workspace/src "$@"
