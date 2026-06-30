#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# ── 加载已有配置 ──
load_env() {
    if [ -f "$ENV_FILE" ]; then
        set -a
        source "$ENV_FILE"
        set +a
    fi
}
load_env

echo "============================================"
echo "  Playwright MCP 代理配置"
echo "============================================"
echo ""

# ── 是否使用代理 ──
echo -e "${BOLD}[1] 是否使用 VPN 代理？${NC}"
echo -e "  ${DIM}代理用于让 Chrome 访问被墙的网站（如 Google）。${NC}"
local cur_proxy="${PROXY_ENABLED:-false}"
local label="不使用"
[ "$cur_proxy" = "true" ] && label="使用"
read -p "  使用代理? [y/N] (当前: $label): " val
case "$val" in
    y|Y|yes)
        PROXY_ENABLED=true
        ;;
    *)
        PROXY_ENABLED=false
        echo -e "  ${YELLOW}跳过代理配置${NC}"
        # 写入 .env
        cat > "$ENV_FILE" << EOF
PROXY_ENABLED=false
EOF
        echo -e "  ${GREEN}✓ 已写入 $ENV_FILE${NC}"
        exit 0
        ;;
esac

# ── 检测宿主机 IP ──
echo ""
echo -e "${BOLD}[2] 宿主机 IP 检测${NC}"
auto_ip=""
if grep -qi microsoft /proc/version 2>/dev/null; then
    # WSL: hostname -I 取第一个 IP
    auto_ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    echo -e "  ${DIM}检测到 WSL 环境${NC}"
else
    # 原生 Linux: ip route 或 hostname -I
    auto_ip=$(ip route get 1 2>/dev/null | grep -oP 'src \K\S+')
    [ -z "$auto_ip" ] && auto_ip=$(hostname -I 2>/dev/null | awk '{print $1}')
fi

local cur_ip="${PROXY_HOST:-$auto_ip}"
read -p "  宿主机 IP (检测到: $cur_ip): " val
PROXY_HOST="${val:-$cur_ip}"

# ── 填写端口 ──
echo ""
echo -e "${BOLD}[3] 代理端口${NC}"
local cur_port="${PROXY_PORT:-7890}"
read -p "  端口 (默认: $cur_port): " val
PROXY_PORT="${val:-$cur_port}"

# ── 写入 .env ──
cat > "$ENV_FILE" << EOF
PROXY_ENABLED=true
PROXY_HOST=$PROXY_HOST
PROXY_PORT=$PROXY_PORT
PROXY_URL=http://$PROXY_HOST:$PROXY_PORT
EOF

echo ""
echo -e "  ${GREEN}✓ 已写入 $ENV_FILE${NC}"
echo "  PROXY_URL=http://${PROXY_HOST}:${PROXY_PORT}"
echo ""
echo "启动容器: docker compose up -d"
