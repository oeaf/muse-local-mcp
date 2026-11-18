# muse-local-mcp

让**云端 AI Agent（如 Muse）安全地操控你本地电脑**的本地 MCP 服务包。

本机装好后，云端 Agent 经一条带 Token 鉴权的 HTTPS 隧道调用你本机的 MCP 工具：读/写白名单目录里的文件、操控桌面、操控浏览器。敏感动作保留人工确认，不用时关掉网关即断开。

> 核心事实先说清：MCP 装在本机 ≠ 云端就能直连。绝大多数 MCP Server 默认走 stdio，只供本机进程调用；云端 Agent 在另一台机器上，连不到你家的 `localhost`。本仓库补的就是中间两层：**HTTP 网关 + 安全隧道**。

## 链路

```
云端 Agent (Muse)
  -> HTTPS 自定义连接器 (Bearer Token)
    -> 隧道 (Cloudflare Tunnel / Tailscale Funnel)
      -> 本地网关 supergateway (http://localhost:8000)
        -> MCP Server (stdio): filesystem / agent-desktop / playwright
          -> 你的电脑: 文件 / 桌面 / 浏览器
```

## 能做什么

| 能力 | MCP Server | 说明 |
|---|---|---|
| 文件 | `@modelcontextprotocol/server-filesystem` | 只读写白名单目录，不暴露整盘 |
| 桌面 | `vercel-labs/agent-desktop` | 读无障碍树做点击/输入，不猜像素；需图形会话，装在 Mac / Windows 本机 |
| 浏览器 | `@playwright/mcp` 或 `anomalyco/browse` | 操控浏览器；browse 可用真实浏览器登录态 |

## 两条路线，先选一条

### 路线 A：只给本机 Agent 用（最简单，5 分钟）

本机跑 Claude Code / Cursor / Claude Desktop / Pi 时，不需要网关和隧道。把 `config/mcp.local.example.json` 里的配置抄进客户端的 `mcp.json`，重启客户端即可。

### 路线 B：给云端 Agent 用（本仓库主线）

按下面 6 步走：网关转 HTTP → 隧道变 HTTPS → 云端建自定义连接器。

## 快速开始（路线 B）

### 1. 装运行时

- Node.js 20+（nodejs.org 的 LTS）、Git
- 按需：Python 3.11+
- 验证：`node -v`、`npx -v` 能输出版本号

### 2. 本机先跑通 stdio

新建白名单目录，如 `D:\MuseShare`（Windows）或 `~/MuseShare`（Mac/Linux），只放愿意让 Agent 访问的文件。

```bash
npx -y @modelcontextprotocol/inspector npx -y @modelcontextprotocol/server-filesystem /path/to/MuseShare
```

Inspector 打开后点 Connect → Tools，能看到 `read_file`、`list_directory` 等工具才算通。这步不通不要往下走。

### 3. 生成 Token 并启动网关

```bash
# 生成 Token（自己保存，不要发到聊天/仓库里）
node scripts/gen-token.mjs

# 启动网关：把 stdio 转成 HTTP，Token 从环境变量读
# Windows PowerShell / Mac 终端的完整命令见 scripts/ 目录的启动脚本
```

- Windows：运行 `scripts/start-gateway.ps1`
- Mac/Linux：运行 `scripts/start-gateway.sh`
- 脚本会从同目录 `.env`（不进仓库）读取 `MCP_TOKEN` 和 `SHARE_DIR`

本机验证：`curl http://localhost:8000/sse` 有响应即网关已起。

### 4. 开隧道（二选一，不要做路由器端口映射）

**Cloudflare Tunnel（推荐，地址可固定）**

```bash
cloudflared tunnel --url http://localhost:8000
```

先用它给的 `https://*.trycloudflare.com` 临时地址测通，长期使用再建 named tunnel 绑自己的域名。

**Tailscale Funnel**

```bash
tailscale funnel 8000
```

得到 `https://<机器名>.<tailnet>.ts.net` 地址。

### 5. 在云端 Muse 里建连接器

把隧道 HTTPS 地址告诉你的 Muse，Token 通过它的 Secure Vault / API Access 安全入口填写，不要直接贴在聊天里。Muse 侧会：

1. 登记该 host + Bearer Token 鉴权，建 `custom.<本机名>` 自定义连接器
2. 用 MCP client helper 包装 `list-tools` / `call-tool`
3. 先做无害验收：列工具 → 读白名单里的测试文件 → 回报结果

验收细节见 `docs/cloud-connector.md`。

### 6. 验收顺序（不要跳步）

1. 列工具成功
2. 读白名单测试文件成功
3. 写一个临时文件再删掉成功
4. 桌面能力：先截图、再读控件树，最后才放开点击/输入

## 安全铁律

- 只暴露白名单目录，永不暴露整盘、家目录根、`.ssh`、浏览器配置目录
- 网关必须带 Bearer Token；没有 Token 的隧道等于把电脑敞开给全网
- Token 只存本机 `.env`（权限 600 / 仅本人可读）和云端保险箱，永不进仓库、聊天、日志
- 删除、付款、对外发送、改系统设置：保留人工确认，不给 Agent 自动放行
- 不用时关掉网关进程，云端立刻断开；这是最干脆的断开方式
- 隧道只用 Tunnel/Funnel，不做公网端口转发

## 目录

```
README.md                  本文件：原理 + 6 步快速开始
SKILL.md                   给 Muse / 其他 Agent 的技能说明（照它安装）
skill.yaml                 技能清单
INSTALL_FOR_AGENT.md       给另一个 Agent 的一键安装指令（复制粘贴用）
config/
  mcp.local.example.json   路线 A：本机客户端 mcp.json 示例
  gateway.env.example      网关 .env 模板（只放占位符）
  claude_desktop.example.json  Claude Desktop 配置示例
scripts/
  gen-token.mjs            生成随机 Token
  check-env.mjs            检查 Node/npx/目录是否就绪
  start-gateway.sh         Mac/Linux 启动网关
  start-gateway.ps1        Windows 启动网关
docs/
  architecture.md          链路与组件说明
  cloud-connector.md       云端 Muse 自定义连接器接入细节
  security.md              安全清单与故障排查
```

## 故障排查（速查）

| 现象 | 先查 |
|---|---|
| Inspector 连不上 | Node 版本、npx 是否可用、白名单路径是否存在 |
| 网关起了但云端连不上 | 隧道是否在跑、HTTPS 地址是否变了（临时隧道重启会换地址） |
| 401 | 云端连接器里的 Token 与本机 `.env` 是否一致 |
| 桌面工具无反应 | 本机是否有图形会话、agent-desktop 是否装在本机而非云 VM |
| 临时隧道地址失效 | 改用 named tunnel / Tailscale Funnel 的固定地址 |

完整版见 `docs/security.md` 的排查节。

## 与桥接方案的关系

本仓库走标准 MCP，胜在可复用给 Claude Code、Codex、Cursor 等多个 Agent。若只服务单个云端 Muse，文件队列 + Hook 唤醒的桥接方案（如 feishu-bridge、muse-qq-bridge）同样可行。两条路不冲突，可并存。

## License

MIT
