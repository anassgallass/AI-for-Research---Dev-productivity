# AI for Research

Use internal knowledge sources with AI agents using MCP with Azure.

## Pre-requisites

- Python (Ideally Python 3.11 or 3.10 for best compatibility)
- uv (https://docs.astral.sh/uv/getting-started/installation/)
- MCP Python SDK (https://github.com/modelcontextprotocol/python-sdk?tab=readme-ov-file#installation)
- Basic understanding of Azure and AI foundry is beneficial but not required.

## Pipeline

### Setup

1. Copy [`.env.example`](./.env.example) and paste it in the same directory.
2. Rename the **copied** `.env.example` to `.env`
3. Open [Azure Portal](https://portal.azure.com)
4. Create Azure RG called `ai_for_research`

### Azure AI Search

1. Create AI Search resource on Azure portal called `ai-for-research-search`. (IMPORTANT: USE FREE PRICING TIER, recommended region: `swedencentral`)
2. In AI Search, go to `Search Management` > `Indexes`
3. Click on `Add Index` > `Add Index (JSON)`, this will open a sidebar where you can enter JSON config.
4. Copy JSON config from [`index_conf.json`](./index_conf.json) and paste it in the sidebar.
5. Click on `Save`
6. On left pane, click on `Overview`
7. Copy the `Url` in `Essentials`
8. Paste that `Url` in `.env` in the field `AZURE_SEARCH_ENDPOINT`
9. On left pane, go to `Settings` > `Keys`
10. Make sure `API Keys` is selected in API Access Control
11. Copy the API key under `Manage query keys`.
12. Paste that API key in the `.env` in the field `AZURE_SEARCH_API_KEY`
13. In the `.env`, set the field `AZURE_SEARCH_INDEX_NAME` to your index name. If you didn't change it, use `vector-index`.
14. Under `Manage admin keys`, copy the `Primary admin key`.
15. Paste the primary admin key in the `.env` in field `AZURE_SEARCH_PRIMARY_API_KEY`
16. The vector index is set up!

### Azure AI Foundry

1. Go to [Azure AI Foundry](https://ai.azure.com)
2. Toggle `New Foundry`
3. Create a project called `ai-for-research-foundry` under resource group `ai_for_research`, ideally in `swedencentral`
4. Copy the `Project API Key`
5. Paste that project api key in your `.env` in field `AZURE_OPENAI_API_KEY`

#### For OCR (Mistral Document OCR)

1. In top nav click on `Discover`
2. In left pane, click on `Models`
3. Search `mistral-document-ai-2505`
4. Click on first result called `mistral-document-ai-2505`
5. Click on `Deploy` > `Default Settings`
6. In your `.env` set `AZURE_MISTRAL_ENDPOINT` as `https://ai-for-research-foundry-resource.services.ai.azure.com/providers/mistral/azure/ocr`
7. Done!

#### For Embedding (OpenAI Text Embedding 3 Large)

1. In top nav click on `Discover`
2. In left pane, click on `Models`
3. Search `text-embedding-3-large`
4. Click on the first result called `text-embedding-3-large`
5. Click on `Deploy` > `Default Settings`
6. In your `.env` set `AZURE_OPENAI_ENDPOINT` as `https://ai-for-research-foundry-resource.cognitiveservices.azure.com`
7. Done!

#### For Inference (Mistral 3 Large)

1. In top nav click on `Discover`
2. In the left pane, click on `Models`
3. Search `Mistral-Large-3`
4. Click on the first result called `Mistral-Large-3`
5. Click on `Deploy` > `Default Settings`
6. In your `.env` set `AZURE_OPENAI_INFERENCE` as `https://ai-for-research-foundry-resource.services.ai.azure.com/openai/v1/`
7. Done!

### Running the pipeline

1. First run `pip install -r requirements.txt` to have all necessary dependencies installed.
2. Open `pipeline.ipynb` and select your python kernel.
3. Run each cell one by one (2 or more cells SHOULD NOT be running at the same time)
4. In the end you can test the inference with your own query or example queries.
5. Done!

### Run the MCP server

You must run these from the `azure-ai-search-mcp` directory for the scripts to work.

The server supports three transport modes:

- **streamable-http** (default): HTTP endpoint for GitHub Copilot, Claude Desktop, mcpo, and other MCP clients
- **stdio**: Legacy local-process mode
- **sse**: Legacy SSE streaming (for MCP Inspector or older web clients)

**Option A: Use the scripts**

Windows (PowerShell):

```powershell
# Dev server (MCP Inspector at http://localhost:6274)
.\scripts\dev.ps1              # default port 8000
.\scripts\dev.ps1 -Port 9090   # custom port

# Prod server (streamable-http)
.\scripts\prod.ps1                              # default: 0.0.0.0:8000
.\scripts\prod.ps1 -Port 9000                   # custom port
.\scripts\prod.ps1 -BindAddress 127.0.0.1       # localhost only
```

macOS / Linux:

```bash
# Dev server (MCP Inspector at http://localhost:6274)
chmod +x scripts/dev.sh
./scripts/dev.sh            # default port 8000
./scripts/dev.sh 9090       # custom port

# Prod server (streamable-http)
chmod +x scripts/prod.sh
./scripts/prod.sh                   # default: 0.0.0.0:8000
./scripts/prod.sh 127.0.0.1 9000    # custom host + port
```

**Option B: Run directly**

```bash
# streamable-http mode (default)
uv run python main.py                                # 0.0.0.0:8000
uv run python main.py --port 9000                    # custom port
uv run python main.py --host 127.0.0.1               # localhost only

# Legacy modes
uv run python main.py --transport stdio               # stdio
uv run python main.py --transport sse --port 8000     # SSE
```

### Available Tools

| Tool              | Description                                                     |
| ----------------- | --------------------------------------------------------------- |
| `semantic_search` | AI-powered semantic search that understands context and meaning |
| `hybrid_search`   | Combines full-text and vector search for balanced results       |
| `text_search`     | Traditional keyword-based text search                           |
| `filtered_search` | Search with OData filter expressions to narrow results          |
| `fetch_document`  | Retrieve a specific document by its unique ID                   |

### GitHub Copilot MCP setup

1. Make sure the MCP server is running first (e.g. via `scripts/prod.ps1` from the `azure-ai-search-mcp` directory).
2. The workspace config at [`.vscode/mcp.json`](./.vscode/mcp.json) connects to the running server at `http://localhost:8000/mcp`.
3. In VS Code, open the Command Palette and run **MCP: List Servers** to verify the connection.
4. GitHub Copilot's **Agent mode** will auto-discover the tools.

> [!NOTE]
> You may need to reload VS Code or the window so GitHub Copilot picks up the MCP server.

> [!TIP]
> For more details on the MCP server (configuration, field exclusion, troubleshooting, etc.), see the [MCP server README](./azure-ai-search-mcp/README.md).

### OpenWebUI MCP setup

First we need to set up OpenWebUI:

1. Install with uv + python:

```powershell
$env:DATA_DIR="C:\open-webui\data"; uvx --python 3.11 open-webui@latest serve
```

2. Open `http://localhost:8080` and create an admin account.
3. Click on your profile (bottom left) → **Admin Panel**.
4. In top nav bar, click on **Settings** → **Connections**.
5. Delete the default OpenAI connection and disable the Ollama connection.
6. Click the plus icon next to **Manage OpenAI API Connections**.
7. From `.env`, use your `AZURE_OPENAI_INFERENCE` URL for **API base URL** (IMPORTANT: without trailing slash!).
8. From `.env`, copy your `AZURE_OPENAI_API_KEY` and paste it next to **Bearer** in **Auth**.
9. Ensure **Provider Type** is NOT `Azure OpenAI` — if it is, click on it to switch it to `OpenAI`.
10. Set **Model ID** to `Mistral-Large-3`.
11. Hit **Save**.

## MCP

1. Navigate to [`azure-ai-search-mcp`](./azure-ai-search-mcp/) — this will be your working directory.
2. Install dependencies with uv:

```bash
uv sync
```

OpenWebUI doesn't support MCP natively. We use [`mcpo`](https://pypi.org/project/mcpo/) to bridge the running MCP server (streamable-http) to an OpenAPI endpoint that OpenWebUI can consume.

#### Prerequisites

```bash
pip install mcpo
```

#### Run the MCP server + mcpo proxy

From the `azure-ai-search-mcp` directory:

Windows (PowerShell):

```powershell
.\scripts\openwebui_mcp.ps1                                       # MCP on 8000, mcpo on 8001
.\scripts\openwebui_mcp.ps1 -McpPort 9090 -McpoPort 9000          # custom ports
.\scripts\openwebui_mcp.ps1 -ApiKey "my-secret"                   # custom API key
```

macOS / Linux:

```bash
chmod +x scripts/openwebui_mcp.sh
./scripts/openwebui_mcp.sh                     # MCP on 8000, mcpo on 8001
./scripts/openwebui_mcp.sh 9090 9000           # custom ports
./scripts/openwebui_mcp.sh 8080 8000 my-key    # custom ports + API key
```

#### Add to OpenWebUI

1. Open OpenWebUI (default: `http://localhost:8080`).
2. Click on your profile (bottom left) → **Admin Panel**.
3. In top nav bar, click on **Settings** → **External Tools**.
4. Click the plus icon next to **Manage Tool Servers**.
5. Enter:
   - **URL**: `http://localhost:8001/azure-ai-search`
   - **API Key**: `top-secret` (or whatever you set when launching the script)
6. Click **Save**.

The MCP tools will now be available in your OpenWebUI chats (you may need to enable them manually before submitting a prompt).

> [!NOTE]
> The mcpo proxy and the GitHub Copilot HTTP config are independent — they both connect to the same MCP server and can run simultaneously.

## Cloud Deployment (Azure Container Apps)

The MCP server can be deployed to [Azure Container Apps](https://learn.microsoft.com/azure/container-apps/) for remote access via streamable-http — no local server required.

> [!IMPORTANT]
> Must have Azure CLI installed and be logged in!

```powershell
# From the azure-ai-search-mcp directory (reads secrets from ../.env)
.\azure\deploy.ps1
```

This single command provisions an ACR, builds the Docker image remotely, and deploys a Container App. The output includes the MCP endpoint URL you can plug into `.vscode/mcp.json`.

See the full guide: [`azure-ai-search-mcp/azure/README.md`](./azure-ai-search-mcp/azure/README.md).

## Credits

- [Aryan Shah (SE Intern)](https://github.com/aryxenv): RAG Pipeline + Azure Setup + Foundry Setup + MCP Server Setup + Github Copilot MCP setup & integration + OpenWebUI MCP setup & integration + MCP Deployment + Documentation
- [Anass Gallass (SSP Intern)](https://github.com/anassgallass): Testing AI Search & GHCP MCP
- [Bertille Mathieu (SE Intern)](https://github.com/bertillessec): Testing AI Search & OpenWebUI MCP
