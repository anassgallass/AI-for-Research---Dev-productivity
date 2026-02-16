<#
.SYNOPSIS
    Build, push, and deploy the Azure AI Search MCP server to Azure Container Apps.

.DESCRIPTION
    End-to-end deployment script that:
      1. Deploys infrastructure (ACR, Log Analytics, Container Apps Environment)
      2. Builds the Docker image in ACR (no local Docker required)
      3. Deploys the Container App pointing at the built image

    Prerequisites:
      - Azure CLI (az) installed and logged in (az login)
      - The .env file at the workspace root (../.env) OR supply params directly

.PARAMETER ResourceGroup
    Azure resource group to deploy into (default: ai_for_research).

.PARAMETER Location
    Azure region (default: swedencentral).

.PARAMETER AppName
    Base name for all resources (default: mcp-search).

.PARAMETER ImageTag
    Docker image tag (default: latest).

.PARAMETER AzureSearchEndpoint
    Azure AI Search endpoint. If omitted, read from ../.env.

.PARAMETER AzureSearchApiKey
    Azure AI Search API key. If omitted, read from ../.env.

.PARAMETER AzureSearchIndexName
    Azure AI Search index name. If omitted, read from ../.env.
#>
param(
    [string]$ResourceGroup  = "ai_for_research",
    [string]$Location       = "swedencentral",
    [string]$AppName        = "mcp-search",
    [string]$ImageTag       = "latest",
    [string]$AzureSearchEndpoint  = "",
    [string]$AzureSearchApiKey    = "",
    [string]$AzureSearchIndexName = ""
)

$ErrorActionPreference = "Stop"
$ScriptDir     = Split-Path -Parent $MyInvocation.MyCommand.Definition
$McpRoot       = Split-Path -Parent $ScriptDir          # azure-ai-search-mcp/
$WorkspaceRoot = Split-Path -Parent $McpRoot             # repo root

# ── Helper: load a value from ../.env if not provided ──
function Get-EnvValue([string]$Key, [string]$Override) {
    if ($Override -ne "") { return $Override }
    $envFile = Join-Path $WorkspaceRoot ".env"
    if (Test-Path $envFile) {
        $match = Select-String -Path $envFile -Pattern "^${Key}=(.+)$" | Select-Object -First 1
        if ($match) { return $match.Matches.Groups[1].Value.Trim('"').Trim("'") }
    }
    throw "Missing $Key - pass it as a parameter or set it in $envFile"
}

$AzureSearchEndpoint  = Get-EnvValue "AZURE_SEARCH_ENDPOINT"   $AzureSearchEndpoint
$AzureSearchApiKey    = Get-EnvValue "AZURE_SEARCH_API_KEY"    $AzureSearchApiKey
$AzureSearchIndexName = Get-EnvValue "AZURE_SEARCH_INDEX_NAME" $AzureSearchIndexName

$imageName = "$AppName-server"
$imageRef  = ""   # set after infra deploys

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  MCP Server -> Azure Container Apps Deploy" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Resource Group : $ResourceGroup"
Write-Host "  Location       : $Location"
Write-Host "  App Name       : $AppName"
Write-Host "  Image Tag      : $ImageTag"
Write-Host "  Search Index   : $AzureSearchIndexName"
Write-Host ""

# ── 1. Ensure resource group exists ──
Write-Host "[1/4] Ensuring resource group '$ResourceGroup' exists..." -ForegroundColor Yellow
az group create --name $ResourceGroup --location $Location --output none

# ── 2. Deploy infrastructure (ACR + Log Analytics + Environment) ──
Write-Host "[2/4] Deploying infrastructure (infra.bicep)..." -ForegroundColor Yellow
$infraFile = Join-Path $ScriptDir "infra.bicep"

$infraDeploy = az deployment group create `
    --resource-group $ResourceGroup `
    --template-file  $infraFile `
    --parameters appName=$AppName `
    --output json | ConvertFrom-Json

$acrLoginServer = $infraDeploy.properties.outputs.acrLoginServer.value
$acrName        = $infraDeploy.properties.outputs.acrName.value
$environmentId  = $infraDeploy.properties.outputs.environmentId.value
$imageRef       = "$acrLoginServer/${imageName}:${ImageTag}"

Write-Host "  ACR            : $acrLoginServer" -ForegroundColor Green
Write-Host "  ACR Name       : $acrName" -ForegroundColor Green
Write-Host "  Environment ID : $environmentId" -ForegroundColor Green
Write-Host "  Image          : $imageRef" -ForegroundColor Green

# ── 3. Build Docker image in ACR (no local Docker needed) ──
Write-Host "[3/4] Building Docker image in ACR (az acr build)..." -ForegroundColor Yellow

# Copy .dockerignore to the build context root (azure-ai-search-mcp/)
$dockerignoreSrc  = Join-Path $ScriptDir ".dockerignore"
$dockerignoreDest = Join-Path $McpRoot ".dockerignore"
Copy-Item $dockerignoreSrc $dockerignoreDest -Force

try {
    Push-Location $McpRoot
    az acr build `
        --registry $acrName `
        --image "${imageName}:${ImageTag}" `
        --file "azure/Dockerfile" `
        .
}
finally {
    Pop-Location
    if (Test-Path $dockerignoreDest) { Remove-Item $dockerignoreDest -Force }
}

# ── 4. Deploy Container App (image now exists in ACR) ──
Write-Host "[4/4] Deploying Container App (app.bicep)..." -ForegroundColor Yellow
$appFile = Join-Path $ScriptDir "app.bicep"

$appDeploy = az deployment group create `
    --resource-group $ResourceGroup `
    --template-file  $appFile `
    --parameters `
        appName=$AppName `
        acrLoginServer=$acrLoginServer `
        environmentId=$environmentId `
        imageReference=$imageRef `
        azureSearchEndpoint=$AzureSearchEndpoint `
        azureSearchApiKey=$AzureSearchApiKey `
        azureSearchIndexName=$AzureSearchIndexName `
    --output json | ConvertFrom-Json

$mcpEndpoint = $appDeploy.properties.outputs.mcpEndpoint.value

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Deployment complete!" -ForegroundColor Green
Write-Host "  MCP Endpoint: $mcpEndpoint" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "To use with GitHub Copilot, set your .vscode/mcp.json to:" -ForegroundColor Cyan
Write-Host @"
{
  "servers": {
    "azure-ai-search": {
      "type": "http",
      "url": "$mcpEndpoint",
      "headers": { "Content-Type": "application/json" }
    }
  }
}
"@ -ForegroundColor Gray
