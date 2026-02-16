<#
.SYNOPSIS
    Start the Azure AI Search MCP server via mcpo for OpenWebUI.

.DESCRIPTION
    Launches mcpo (MCP-to-OpenAPI proxy) wrapping the MCP server over stdio.
    This exposes the tools as an OpenAPI endpoint that OpenWebUI can consume.

    After starting, add the server in OpenWebUI:
      Admin Panel > Settings > Tools > OpenAPI Servers > Add Connection
      URL  : http://localhost:<Port>/azure-ai-search
      Key  : <ApiKey>

    Prerequisites: uv, mcpo (pip install mcpo), and 'uv sync' must have been run.

.PARAMETER Port
    The port for the mcpo HTTP server (default: 8000).

.PARAMETER ApiKey
    API key for mcpo authentication (default: "top-secret"). Set to "" to disable.
#>
param(
    [int]$Port = 8000,
    [string]$ApiKey = "top-secret"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ProjectRoot = Split-Path -Parent $ScriptDir

Push-Location $ProjectRoot
try {
    Write-Host "================================================" -ForegroundColor Magenta
    Write-Host "  Azure AI Search MCP - OpenWebUI (via mcpo)"    -ForegroundColor Magenta
    Write-Host "  mcpo endpoint : http://localhost:$Port"         -ForegroundColor Magenta
    Write-Host "  Tools docs    : http://localhost:$Port/azure-ai-search/docs" -ForegroundColor Magenta
    Write-Host "================================================" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "Add to OpenWebUI -> Admin -> Settings -> Tools -> OpenAPI Servers:" -ForegroundColor Yellow
    Write-Host "  URL : http://localhost:$Port/azure-ai-search"  -ForegroundColor Yellow
    Write-Host "  Key : $ApiKey"                                  -ForegroundColor Yellow
    Write-Host ""

    $mcpoArgs = @("--port", $Port, "--config", "mcpo-config.json")
    if ($ApiKey -ne "") {
        $mcpoArgs += @("--api-key", $ApiKey)
    }

    mcpo @mcpoArgs
}
finally {
    Pop-Location
}
