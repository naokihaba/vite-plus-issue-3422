#!/usr/bin/env bash
# Reproduce voidzero-dev/vite-plus#3422 in an isolated VP_HOME.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
from="${VP_FROM:-1.5.0}"
to="${VP_TO:-1.5.1}"
port="${PORT:-18422}"
export VP_HOME="$here/.home"
export VP_SELF_SETUP_NO_MODIFY_PATH=1
rm -rf -- "$VP_HOME"
mkdir -p "$VP_HOME"

echo "==> 1. Install vp $from from nodejs.org (no mirror)"
curl -fsSL https://vite.plus | VP_VERSION="$from" bash >/dev/null
export PATH="$VP_HOME/bin:$PATH"
vp --version | head -3

echo "==> 2. Remove the managed Node.js that the target release requires"
# The reporter had only an older managed Node.js (24.15.0).
ls "$VP_HOME/js_runtime/node"
rm -rf -- "$VP_HOME/js_runtime/node/"[0-9]*

echo "==> 3. Upgrade to $to through a mirror that blocks: ${BLOCK_VERSIONS:-24.22.2}"
python3 "$here/mirror.py" "$port" &
mirror_pid=$!
trap 'kill "$mirror_pid" 2>/dev/null || true' EXIT
sleep 1
VP_NODE_DIST_MIRROR="http://127.0.0.1:$port" vp upgrade "$to"
