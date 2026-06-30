# Playwright MCP Server (Docker)

基于 Docker 的 Playwright MCP 服务器，配合 Hermes Agent 使用，让 AI 能直接操控浏览器。

所有 MCP 服务通过共享的 `mcp-net` Docker 网络互通，**端口不暴露到宿主机**。

## 前置条件

- Docker
- （可选）VPN 代理，用于访问被墙的网站

## 快速启动

```bash
# 1. 确保 mcp-net 网络存在
docker network inspect mcp-net >/dev/null 2>&1 || docker network create mcp-net

# 2. 启动
cd ~/playwright
docker compose up -d
```

## 配置说明

`docker-compose.yml` 中的关键参数：

| 参数 | 值 | 说明 |
|------|-----|------|
| `--proxy-server` | `http://172.24.16.1:7890` | 通过宿主机 VPN 代理访问外网（可选） |
| `--user-agent` | Windows Chrome 130 UA | 伪装成真实浏览器，减少验证码 |
| `--viewport-size` | `1920x1080` | 设置正常分辨率 |
| `--executable-path` | `/ms-playwright/.../chrome` | 容器内 Chrome 路径 |
| `--no-sandbox` | — | Linux 上需要关闭沙箱 |
| `--host` | `0.0.0.0` | 监听所有网络接口 |
| `--allowed-hosts` | `*` | 允许所有来源的请求 |

网络：playwright-mcp 接入 `mcp-net` 共享网络，不暴露端口到宿主机。

## 与 Hermes Agent 配合

playwright-mcp 通过内部网络 `mcp-net` 与 Hermes 通信，无需端口映射。

### 网络配置

确保 Hermes 的 `docker-compose.yml` 也接入了 `mcp-net`：

```yaml
services:
  hermes:
    networks:
      - default
      - mcp-net   # 接入共享 MCP 网络

networks:
  mcp-net:
    external: true
```

### Hermes config.yaml 配置

Hermes 的 profile config 中配置 MCP 服务器（走容器名，不走 host.docker.internal）：

```yaml
mcp_servers:
  playwright:
    url: "http://playwright-mcp:8931/mcp"
    timeout: 120
```

容器重启后，Hermes 自动加载 playwright 工具。

### 一键部署（Hermes-Docker 仓库）

如果使用 [Hermes-Docker](https://github.com/Firefly-Star/Hermes-Docker) 仓库，playwright 已作为子模块集成。运行 `setup.sh` 时选择启用即可自动部署：

```bash
git clone --recurse-submodules https://github.com/Firefly-Star/Hermes-Docker.git
cd Hermes-Docker
bash setup.sh
# 在 [7] 容器化 Playwright MCP 服务器 选择 y
```

## 管理命令

| 操作 | 命令 |
|------|------|
| 启动 | `docker compose up -d` |
| 停止 | `docker compose down` |
| 重启 | `docker compose down && docker compose up -d` |
| 查看日志 | `docker logs playwright-mcp` |
| 测试连接 | `docker exec hermes-single hermes mcp test playwright` |

## 从零搭建（新机器）

```bash
# 1. 克隆仓库
git clone https://github.com/Firefly-Star/playwright-mcp-server-docker.git ~/playwright
cd ~/playwright

# 2. 创建共享 MCP 网络（只需一次）
docker network inspect mcp-net >/dev/null 2>&1 || docker network create mcp-net

# 3. 启动
docker compose up -d

# 4. 在 Hermes config.yaml 中添加 mcp 配置（见上方说明）
# 5. 重启 Hermes 容器
```
