#!/usr/bin/env bash
set -euo pipefail
mkdir -p "$HOME/.config/git"
# Seed extensions only once, so user additions and removals persist.
data_dir="$HOME/.local/share/code-server"
if [[ ! -f "$data_dir/.extensions-seeded" ]]; then
    mkdir -p "$data_dir/extensions"
    cp -a /opt/editor-extensions/. "$data_dir/extensions/"
    touch "$data_dir/.extensions-seeded"
fi
exec code-server --bind-addr 0.0.0.0:8080 --auth none \
    --disable-telemetry --disable-update-check /workspace/src "$@"
