#!/usr/bin/env bash
# Show that the aliyun mirror rejects requests without a User-Agent header.
set -euo pipefail
url="${1:-https://mirrors.aliyun.com/nodejs-release/v24.22.2/SHASUMS256.txt}"
printf 'with User-Agent (curl default): '
curl -s -o /dev/null -w '%{http_code}\n' "$url"
printf 'without User-Agent:             '
curl -s -o /dev/null -w '%{http_code}\n' -H 'User-Agent:' "$url"
