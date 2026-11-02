#!/usr/bin/env bash
set -euo pipefail
mkdir -p "$HOME/.config/git" "$CODEX_HOME" "$CLAUDE_CONFIG_DIR"
chmod 700 "$CODEX_HOME" "$CLAUDE_CONFIG_DIR"
# Seed extensions only once, so user additions and removals persist.
data_dir="$HOME/.local/share/code-server"
if [[ ! -f "$data_dir/.extensions-seeded" ]]; then
    mkdir -p "$data_dir/extensions"
    cp -a /opt/editor-extensions/. "$data_dir/extensions/"
    touch "$data_dir/.extensions-seeded"
fi
exec code-server --bind-addr 0.0.0.0:8080 --auth none \
    --disable-telemetry --disable-update-check /workspace/src "$@"
