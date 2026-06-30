# Playwright MCP Server (Docker)

基于 Docker 的 Playwright MCP 服务器，配合 Hermes Agent 使用，让 AI 能直接操控浏览器。

## 前置条件

- Docker
- 与 Hermes Agent 共用 Docker 网络（`hermes-single_default`）
- （可选）VPN 代理，用于访问被墙的网站

## 快速启动

```bash
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

网络配置：playwright-mcp 自动连接到 `hermes-single_default` 网络，与 Hermes Agent 互通。

## 与 Hermes Agent 配合

Hermes 的 `config.yaml` 中配置：

```yaml
mcp_servers:
  playwright:
    url: "http://host.docker.internal:8931/mcp"
    headers:
      Host: "localhost:8931"
    timeout: 120
```

启动 MCP 服务器后，重启 Hermes 容器即可加载 playwright 工具：

```bash
docker restart hermes-single
```

或等待约 1-2 分钟，MCP 客户端会自动重连。

## 管理命令

| 操作 | 命令 |
|------|------|
| 启动 | `docker compose up -d` |
| 停止 | `docker compose down` |
| 重启 | `docker compose down && docker compose up -d` |
| 查看日志 | `docker logs playwright-mcp` |
| 测试连接 | `docker exec hermes-single /opt/hermes/.venv/bin/hermes mcp test playwright` |

## 从零搭建（新机器）

```bash
# 1. 克隆仓库
git clone <repo-url> ~/playwright
cd ~/playwright

# 2. 创建 Docker 网络（如果没有 Hermes）
docker network create hermes-single_default

# 3. 启动
docker compose up -d
```
