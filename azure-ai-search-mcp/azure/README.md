# Deploy to Azure Container Apps

This folder contains everything needed to deploy the Azure AI Search MCP server to [Azure Container Apps](https://learn.microsoft.com/azure/container-apps/).

The deployed container exposes the MCP server over **streamable-http** at `https://<your-app>.azurecontainerapps.io/mcp`.

## What gets deployed

| Resource                         | Purpose                                            |
| -------------------------------- | -------------------------------------------------- |
| Azure Container Registry (Basic) | Stores the Docker image                            |
| Log Analytics workspace          | Container App logs                                 |
| Container Apps Environment       | Hosts the Container App                            |
| Container App                    | Runs the MCP server (streamable-http on port 8000) |

## Prerequisites

- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) installed and logged in (`az login`)
- Your Azure AI Search service already set up (endpoint, API key, index name)

> **Note:** Docker Desktop is **not** required. The image is built remotely in ACR via `az acr build`.

## Quick start (PowerShell)

From the `azure-ai-search-mcp` directory:

```powershell
# Uses values from ../.env automatically
.\azure\deploy.ps1

# Or supply values explicitly
.\azure\deploy.ps1 `
    -AzureSearchEndpoint  "https://my-search.search.windows.net" `
    -AzureSearchApiKey    "my-api-key" `
    -AzureSearchIndexName "vector-index"
```

### Optional parameters

| Parameter        | Default           | Description                 |
| ---------------- | ----------------- | --------------------------- |
| `-ResourceGroup` | `ai_for_research` | Azure resource group        |
| `-Location`      | `swedencentral`   | Azure region                |
| `-AppName`       | `mcp-search`      | Base name for all resources |
| `-ImageTag`      | `latest`          | Docker image tag            |

## Manual deployment (step by step)

If you prefer to run each step yourself:

### 1. Deploy infrastructure (ACR, Log Analytics, Environment)

```bash
az group create --name ai_for_research --location swedencentral

az deployment group create \
    -g ai_for_research \
    -f azure/infra.bicep \
    -p appName='mcp-search'
```

Note the outputs: `acrLoginServer`, `acrName`, `environmentId`.

### 2. Build the Docker image in ACR

```bash
# From the azure-ai-search-mcp/ directory
cp azure/.dockerignore .dockerignore

az acr build \
    --registry <acrName> \
    --image mcp-search-server:latest \
    --file azure/Dockerfile \
    .

rm .dockerignore
```

### 3. Deploy the Container App

```bash
az deployment group create \
    -g ai_for_research \
    -f azure/app.bicep \
    -p appName='mcp-search' \
       acrLoginServer='<acrLoginServer>' \
       environmentId='<environmentId>' \
       imageReference='<acrLoginServer>/mcp-search-server:latest' \
       azureSearchEndpoint='https://my-search.search.windows.net' \
       azureSearchApiKey='my-api-key' \
       azureSearchIndexName='vector-index'
```

Note the output: `mcpEndpoint`.

## Connect GitHub Copilot to the deployed server

Update your `.vscode/mcp.json`:

```jsonc
{
  "servers": {
    "azure-ai-search": {
      "type": "http",
      "url": "https://<your-app>.azurecontainerapps.io/mcp",
      "headers": {
        "Content-Type": "application/json",
      },
    },
  },
}
```

## Files

| File            | Description                                              |
| --------------- | -------------------------------------------------------- |
| `Dockerfile`    | Multi-stage Docker build (uv builder -> slim runtime)    |
| `.dockerignore` | Excludes dev files from the Docker build context         |
| `infra.bicep`   | Phase 1 - ACR, Log Analytics, Container Apps Environment |
| `app.bicep`     | Phase 2 - Container App (deployed after image is pushed) |
| `deploy.ps1`    | One-command PowerShell deployment script                 |
| `README.md`     | This file                                                |

## Environment variables

The Container App injects these as env vars (sensitive values stored as secrets):

| Variable                      | Secret? | Description                                                  |
| ----------------------------- | ------- | ------------------------------------------------------------ |
| `AZURE_SEARCH_ENDPOINT`       | Yes     | Azure AI Search endpoint URL                                 |
| `AZURE_SEARCH_API_KEY`        | Yes     | Azure AI Search API key                                      |
| `AZURE_SEARCH_INDEX_NAME`     | No      | Name of the search index                                     |
| `AZURE_SEARCH_EXCLUDE_FIELDS` | No      | Comma-separated fields to exclude (default: `contentVector`) |

## Scaling

The Container App scales from 0 to 3 replicas based on HTTP concurrency (50 concurrent requests per replica). Adjust the `scale` section in `app.bicep` if needed.

## Cleanup

```bash
az group delete --name ai_for_research --yes --no-wait
```

## Credits

- Aryan through Claude Opus 4.6 on GHCP
