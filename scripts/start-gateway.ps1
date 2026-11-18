# Windows: start the MCP gateway (stdio -> HTTP via supergateway)
# Usage: right-click -> Run with PowerShell, or: powershell -ExecutionPolicy Bypass -File scripts\start-gateway.ps1
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")
if (Test-Path ".env") {
  Get-Content ".env" | ForEach-Object {
    if ($_ -match "^\s*([^#=]+)=(.*)$") { Set-Item -Path ("Env:" + $Matches[1].Trim()) -Value $Matches[2].Trim() }
  }
}
if (-not $env:MCP_TOKEN) { throw "MCP_TOKEN is empty. Run: node scripts/gen-token.mjs and put it in .env" }
if (-not $env:SHARE_DIR) { throw "SHARE_DIR is empty. Set it in .env to your whitelist folder" }
$port = if ($env:GATEWAY_PORT) { $env:GATEWAY_PORT } else { "8000" }
Write-Host "Starting MCP gateway on http://localhost:$port for $env:SHARE_DIR"
Write-Host "Keep this window open. Close it to disconnect the cloud agent."
npx -y supergateway --port $port --stdio "npx -y @modelcontextprotocol/server-filesystem $env:SHARE_DIR"
