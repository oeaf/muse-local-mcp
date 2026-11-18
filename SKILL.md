# muse-local-mcp

## 用途

在用户本地电脑（Windows / Mac / Linux）上安装本地 MCP 服务，让云端 Agent 经带 Token 鉴权的 HTTPS 隧道安全调用本机工具：文件（白名单目录）、桌面、浏览器。当用户要求新装、重连、修复或验收本地 MCP 操控通道，或让另一个 Agent 按本流程直接上手时使用。

## 先分清路线

- 路线 A（本机 Agent）：客户端在本机（Claude Code / Cursor / Claude Desktop / Pi），走 stdio 直连，不需要网关和隧道。只做第 2 步配置即可。
- 路线 B（云端 Agent）：Agent 在云端，必须走 网关转 HTTP + 隧道转 HTTPS + 云端自定义连接器。完整走 6 步。

开工前先问清：装哪台机器、先开哪个能力（文件 / 桌面 / 浏览器）。默认先只装文件能力跑通，再加桌面。

## 前置

- Node.js 20+、Git；按需 Python 3.11+
- 白名单目录已建好（如 `D:\MuseShare` 或 `~/MuseShare`）
- 隧道工具二选一已装：cloudflared 或 Tailscale

## 步骤

1. 环境检查：运行 `node scripts/check-env.mjs`，缺什么补什么，不要跳过。
2. stdio 验活：用 MCP Inspector 拉起目标 MCP Server，确认 Tools 列表可见。路线 A 到此把 `config/mcp.local.example.json` 写入客户端 `mcp.json` 即完成。
3. 生成 Token：运行 `node scripts/gen-token.mjs`，把输出写进本机 `gateway.env` 复制出的 `.env`（权限收紧），不要把 Token 发到聊天或写进任何进仓库的文件。
4. 启动网关：Windows 运行 `scripts/start-gateway.ps1`，Mac/Linux 运行 `scripts/start-gateway.sh`。确认 `http://localhost:8000/sse` 本机可达。
5. 开隧道：`cloudflared tunnel --url http://localhost:8000` 或 `tailscale funnel 8000`，记下 HTTPS 地址。临时地址只用于测通，长期使用换固定地址。
6. 云端接入（云端 Agent 侧）：按 `docs/cloud-connector.md` 建自定义连接器，Token 走 Secure Vault 安全入口，登记 host 与 Bearer 鉴权，helper 包装 list-tools / call-tool。
7. 验收：按顺序做 列工具 → 读测试文件 → 写临时文件并删除 →（如装了桌面）截图 → 读控件树。逐项回报状态矩阵，失败项写清卡在哪一步和原始报错要点。

## 安全规则

- 只暴露白名单目录；禁止整盘、家目录根、`.ssh`、浏览器配置目录。
- 网关无 Token 不许开隧道。
- 删除、付款、对外发送、改系统设置必须人工确认。
- 配置文件只放占位符；真实 Token 只在本机 `.env` 与云端保险箱。
- 用户说停就停：关网关进程即断开，不要留后台常驻，除非用户明确要求常驻并已说明保活方式。

## 故障处理

- Inspector 不通：先查 Node/npx 与路径，不要直接改走隧道排查。
- 云端 401：核对两端 Token 是否一致，不要把 Token 贴出来比对，只报一致/不一致。
- 临时隧道地址变化：云端连接器需同步更新 host，提醒用户改用固定地址。
- 桌面无图形会话：说明该能力必须装在有桌面的本机，云 VM 装了无效。

## 交付口径

装完给用户：状态矩阵（每步 通/不通）、隧道地址（可公开部分）、已开放的工具列表、如何关掉（关哪个进程）、下一步建议。不要只报“装好了”。
