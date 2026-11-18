#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [ -f .env ]; then set -a; . ./.env; set +a; fi
: "${MCP_TOKEN:?MCP_TOKEN is empty. Run: node scripts/gen-token.mjs and put it in .env}"
: "${SHARE_DIR:?SHARE_DIR is empty. Set it in .env to your whitelist folder}"
PORT="${GATEWAY_PORT:-8000}"
echo "Starting MCP gateway on http://localhost:${PORT} for ${SHARE_DIR}"
echo "Keep this process running. Stop it (Ctrl+C) to disconnect the cloud agent."
exec npx -y supergateway --port "${PORT}" \
  --stdio "npx -y @modelcontextprotocol/server-filesystem ${SHARE_DIR}"
