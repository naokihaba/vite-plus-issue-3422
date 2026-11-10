#!/usr/bin/env bash
# Reproduce voidzero-dev/vite-plus#3422 in an isolated VP_HOME.
#
# MODE=aliyun (default)  use https://mirrors.aliyun.com/nodejs-release
# MODE=local             use mirror.py (403 when User-Agent is missing)
# MODE=none              no mirror (nodejs.org), control case
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
mode="${MODE:-aliyun}"
from="${VP_FROM:-1.5.0}"
to="${VP_TO:-1.5.1}"
port="${PORT:-18422}"
export VP_HOME="$here/.home"
export VP_SELF_SETUP_NO_MODIFY_PATH=1
rm -rf -- "$VP_HOME"
mkdir -p "$VP_HOME"

echo "==> 1. Install vp $from from nodejs.org (no mirror)"
env -u VP_NODE_DIST_MIRROR bash -c 'curl -fsSL https://vite.plus | VP_VERSION="$1" bash' _ "$from" >/dev/null
export PATH="$VP_HOME/bin:$PATH"
vp --version | head -1

echo "==> 2. Remove the managed Node.js so that the upgrade must download it"
ls "$VP_HOME/js_runtime/node"
rm -rf -- "$VP_HOME/js_runtime/node/"[0-9]*

case "$mode" in
  aliyun) mirror="https://mirrors.aliyun.com/nodejs-release" ;;
  local)
    python3 "$here/mirror.py" "$port" &
    mirror_pid=$!
    trap 'kill "$mirror_pid" 2>/dev/null || true' EXIT
    sleep 1
    mirror="http://127.0.0.1:$port"
    ;;
  none) mirror="" ;;
  *) echo "unknown MODE: $mode" >&2; exit 2 ;;
esac

echo "==> 3. Upgrade to $to (MODE=$mode, VP_NODE_DIST_MIRROR=${mirror:-<unset>})"
if [ -n "$mirror" ]; then
  VP_NODE_DIST_MIRROR="$mirror" vp upgrade "$to"
else
  env -u VP_NODE_DIST_MIRROR vp upgrade "$to"
fi
