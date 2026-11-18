# 架构说明

## 组件

| 组件 | 位置 | 职责 |
|---|---|---|
| MCP Server | 本机 | 真正干活：文件、桌面、浏览器工具，默认 stdio |
| supergateway | 本机 | 把 stdio 转成 HTTP/SSE，供远程调用 |
| 隧道 | 本机→公网 | Cloudflare Tunnel 或 Tailscale Funnel，把本地端口安全暴露成 HTTPS |
| 自定义连接器 | 云端 Muse | 登记隧道 host + Bearer Token，helper 包装 list-tools / call-tool |
| 云端 Agent | 云端 | 经连接器下发工具调用，只看到工具结果 |

## 为什么不能直连

MCP Server 的 stdio 传输靠父进程拉起子进程，只在本机成立。云端 Agent 没有办法在用户电脑上拉起进程，也连不到内网 `localhost`。HTTP 网关 + 隧道就是把“本机进程调用”翻译成“带鉴权的 HTTPS 调用”。

## 多个 MCP Server 怎么组织

每个 Server 开一个网关端口（8000 文件、8001 桌面、8002 浏览器），隧道分别暴露，或用一个反向代理按路径分发。先单开文件跑通，再逐个加，不要一次全开后一起排查。

## 断开方式

关掉网关进程 = 断开。隧道进程关掉同样断开。不需要卸载任何东西。
