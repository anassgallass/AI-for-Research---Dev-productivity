<#
.SYNOPSIS
    Start the Azure AI Search MCP server in DEVELOPMENT mode.

.DESCRIPTION
    Launches the MCP Inspector (browser UI) connected to the server via SSE transport.
    The Inspector lets you test every tool interactively during development.

    Prerequisites: uv must be installed and 'uv sync' must have been run.

.PARAMETER Port
    The port for the SSE server (default: 8080).
#>
param(
    [int]$Port = 8080
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ProjectRoot = Split-Path -Parent $ScriptDir

Push-Location $ProjectRoot
try {
    Write-Host "=======================================" -ForegroundColor Cyan
    Write-Host "  Azure AI Search MCP - DEV MODE"       -ForegroundColor Cyan
    Write-Host "  Transport : SSE (port $Port)"         -ForegroundColor Cyan
    Write-Host "  Inspector : http://localhost:6274"     -ForegroundColor Cyan
    Write-Host "=======================================" -ForegroundColor Cyan
    Write-Host ""

    # Launch via MCP Inspector (bundled with mcp[cli])
    uv run mcp dev main.py --port $Port
}
finally {
    Pop-Location
}
