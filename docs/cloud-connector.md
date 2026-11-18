# 云端 Muse 接入细节

本页写给云端 Muse（或同类支持自定义连接器的 Agent）看，本机用户只需把隧道地址和 Token 入口配合好。

## 前提

- 本机网关已起，隧道 HTTPS 地址可从公网访问（先用浏览器或 curl 在另一网络验一次根路径有响应）
- Token 已生成，用户将通过 Secure Vault / API Access 安全入口提供，不要让用户把 Token 贴在聊天里

## 云端步骤

1. 用 `credentials.request_api_access` 登记连接：provider 用一个稳定 slug（如 `local-mcp-home`），api_hosts 只填隧道 host，auth_scheme 选 API key / Bearer，placement 选 header。
2. 连接建立后 scaffold 出连接器文档到 `~/workspace/custom-connectors/custom.<provider>/`。
3. Helper 按 MCP-backed CLI 模板写：提供 `list-tools` 和 `call-tool <name> <json-args>` 两个命令，内部向隧道地址发 MCP 的 HTTP 请求，Header 带保险箱代填的 Bearer Token，禁用重定向跟随到未登记 host。
4. 验收：先 `list-tools`，再 `call-tool` 读白名单测试文件。两者都通才报“已接通”。
5. 把已开放工具列表、隧道 host、断开方法写回连接器文档；标注未实测的能力为未实测，不要写成已通。

## 地址变化

临时隧道（trycloudflare）重启会换地址，host 变了必须重新登记连接（host 在登记后不可改）。长期使用应引导用户换 named tunnel 或 Tailscale Funnel 的固定地址后再正式登记。
