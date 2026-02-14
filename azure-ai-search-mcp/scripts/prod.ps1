<#
.SYNOPSIS
    Start the Azure AI Search MCP server in PRODUCTION / STDIO mode.

.DESCRIPTION
    Runs the server with stdio transport so it can be consumed by
    GitHub Copilot, Claude Desktop, or any MCP-compatible client.

    Prerequisites: uv must be installed and 'uv sync' must have been run.
#>

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ProjectRoot = Split-Path -Parent $ScriptDir

Push-Location $ProjectRoot
try {
    Write-Host "=======================================" -ForegroundColor Green
    Write-Host "  Azure AI Search MCP - PROD MODE"      -ForegroundColor Green
    Write-Host "  Transport : stdio"                     -ForegroundColor Green
    Write-Host "=======================================" -ForegroundColor Green
    Write-Host ""

    uv run python main.py --transport stdio
}
finally {
    Pop-Location
}
