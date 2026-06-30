#!/bin/bash
set -e

ARGS=("$@")

# 如果设置了 PROXY_URL，在参数前插入 --proxy-server
if [ -n "$PROXY_URL" ]; then
    ARGS=("--proxy-server" "$PROXY_URL" "${ARGS[@]}")
fi

exec npx -y @playwright/mcp "${ARGS[@]}"
