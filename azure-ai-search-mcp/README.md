# Azure AI Search MCP Server

A Python-based Model Context Protocol (MCP) server that integrates Azure AI Search capabilities into agentic workflows. This server provides semantic search, hybrid search, text search, filtered search, and document retrieval tools for AI agents.

## Features

- 🔍 **Semantic Search**: AI-powered search that understands context and meaning
- 🔀 **Hybrid Search**: Combines full-text and vector search for balanced results
- 📝 **Text Search**: Traditional keyword-based search
- 🔎 **Filtered Search**: Search with OData filter expressions
- 📄 **Document Fetch**: Retrieve specific documents by ID
- 📊 **Index Schema Resource**: Access to index field definitions and metadata
- 🌐 **OpenWebUI Integration**: Works with OpenWebUI via mcpo proxy

## Installation

### Prerequisites

- uv
- Python 3.11 or higher
- Azure AI Search Service
- API keys (see `.env.example`)

### From Source

```bash
git clone https://github.com/anassgallass/AI-for-Research---Dev-productivity.git
cd azure-ai-search-mcp
uv sync
```

## Configuration

### Environment Variables

Create a `.env` file in your workspace root (parent of `azure-ai-search-mcp` directory) with these variables:

```env
AZURE_SEARCH_ENDPOINT=https://your-search-service.search.windows.net
AZURE_SEARCH_API_KEY=your-api-key-here
AZURE_SEARCH_INDEX_NAME=your-index-name

# Optional: Comma-separated list of fields to exclude from search results
# Default: contentVector
AZURE_SEARCH_EXCLUDE_FIELDS=contentVector
```

### Required Azure Resources

1. **Azure AI Search Service**: Create a search service in the Azure Portal
2. **Search Index**: Configure an index with your data
3. **API Key**: Get the admin or query key from the Azure Portal

Optional for enhanced semantic search:

- **Semantic Configuration**: Enables Azure's semantic ranker (recommended but not required)
- **Vectorizer**: Enables vector-based semantic search (works without semantic configuration)

## Running the Server

### Dev Mode (MCP Inspector)

Dev mode launches the **MCP Inspector** — a browser-based UI that lets you invoke each tool interactively and inspect results. Great for testing and debugging.

**Windows (PowerShell):**

```powershell
.\scripts\dev.ps1              # default port 8000
.\scripts\dev.ps1 -Port 9090   # custom port
```

**macOS / Linux:**

```bash
chmod +x scripts/dev.sh
./scripts/dev.sh            # default port 8000
./scripts/dev.sh 9090       # custom port
```

The Inspector will open at **http://localhost:6274**.

### Prod Mode (streamable-http)

Prod mode runs the server with **streamable-http** transport, exposing an HTTP endpoint
that GitHub Copilot, Claude Desktop, mcpo, and any MCP-compatible client can connect to.

**Windows (PowerShell):**

```powershell
.\scripts\prod.ps1                              # default: 0.0.0.0:8000
.\scripts\prod.ps1 -Port 9000                   # custom port
.\scripts\prod.ps1 -Host 127.0.0.1 -Port 9000  # localhost only
```

**macOS / Linux:**

```bash
chmod +x scripts/prod.sh
./scripts/prod.sh                   # default: 0.0.0.0:8000
./scripts/prod.sh 127.0.0.1 9000    # custom host + port
```

You can also run directly:

```bash
uv run python main.py                                            # streamable-http on 0.0.0.0:8000 (default)
uv run python main.py --port 9000                                # custom port
uv run python main.py --host 127.0.0.1                           # localhost only
uv run python main.py --transport stdio                          # legacy stdio mode
uv run python main.py --transport sse --port 8000                # legacy SSE mode
```

## GitHub Copilot Integration

This server can be used as a **custom MCP server** in GitHub Copilot (VS Code).

> **Prerequisite:** The MCP server must be running first (e.g. via `scripts/prod.ps1`).

### Option 1 — Workspace config (recommended)

A ready-to-use config is provided at `.vscode/mcp.json`. It connects to the running MCP server over HTTP:

```jsonc
// .vscode/mcp.json
{
  "servers": {
    "azure-ai-search": {
      "type": "http",
      "url": "http://localhost:8000/mcp",
      "headers": {
        "Content-Type": "application/json",
      },
    },
  },
}
```

### Option 2 — User-level settings

Add the server to your VS Code **User Settings** (`settings.json`):

```jsonc
{
  "mcp": {
    "servers": {
      "azure-ai-search": {
        "type": "http",
        "url": "http://localhost:8000/mcp",
        "headers": {
          "Content-Type": "application/json",
        },
      },
    },
  },
}
```

### Option 3 — Remote / containerised deployment

If the MCP server runs in a container or remote host, just point the URL at it:

```jsonc
{
  "servers": {
    "azure-ai-search": {
      "type": "http",
      "url": "https://your-container-app.azurecontainerapps.io/mcp",
      "headers": {
        "Content-Type": "application/json",
      },
    },
  },
}
```

> **Tip:** See the [Azure Container Apps deployment guide](./azure/README.md) for a one-command deploy to Azure.

After configuring, Copilot's **Agent mode** (Chat panel) will auto-discover the tools (`semantic_search`, `hybrid_search`, `text_search`, `filtered_search`, `fetch_document`). You can verify under **MCP: List Servers** in the Command Palette.

## Available Tools

### 1. `semantic_search`

Performs AI-powered semantic search that understands context and meaning. Works with or without semantic configuration - will use vectorizer if semantic configuration is not available.

**Parameters:**

- `query` (string, required): The search query
- `top` (number, optional): Maximum results to return (default: 5)

**Example:**

```json
{
  "query": "machine learning algorithms",
  "top": 5
}
```

### 2. `hybrid_search`

Combines full-text and vector search for balanced results.

**Parameters:**

- `query` (string, required): The search query
- `top` (number, optional): Maximum results to return (default: 5)

**Example:**

```json
{
  "query": "artificial intelligence trends",
  "top": 5
}
```

### 3. `text_search`

Traditional keyword-based text search.

**Parameters:**

- `query` (string, required): The search query
- `top` (number, optional): Maximum results to return (default: 5)

**Example:**

```json
{
  "query": "data science",
  "top": 5
}
```

### 4. `filtered_search`

Search with OData filter expressions to narrow results.

**Parameters:**

- `query` (string, required): The search query
- `filter` (string, required): OData filter expression
- `top` (number, optional): Maximum results to return (default: 5)

**Example:**

```json
{
  "query": "technology",
  "filter": "category eq 'AI' and year ge 2020",
  "top": 5
}
```

### 5. `fetch_document`

Retrieve a specific document by its unique ID. Returns the complete document with all fields.

**Parameters:**

- `document_id` (string, required): The document's unique identifier

**Example:**

```json
{
  "document_id": "doc-12345"
}
```

## Field Exclusion

- **Search tools** (`semantic_search`, `hybrid_search`, `text_search`, `filtered_search`): Return document summaries without fields specified in `AZURE_SEARCH_EXCLUDE_FIELDS` environment variable (default: `contentVector`)
- **Fetch document**: Always returns full document with only `contentVector` fields excluded

You can customize which fields are excluded via the `AZURE_SEARCH_EXCLUDE_FIELDS` environment variable. The `fetch_document` tool always excludes only `contentVector`.

## Security Notes

- **API Keys**: Never commit API keys to version control
- **Environment Variables**: Use environment variables or secure secret management
- **Access Control**: Use Azure RBAC and query keys (not admin keys) in production
- **Rate Limiting**: Be aware of Azure Search service tier limits
- **Field Exclusion**: Use `AZURE_SEARCH_EXCLUDE_FIELDS` to prevent sensitive data from being returned in search results
- **Data Privacy**: The `contentVector` fields are always excluded from search results by default

## OpenWebUI Integration

OpenWebUI doesn't support the MCP protocol natively. We use [`mcpo`](https://pypi.org/project/mcpo/) to bridge the running MCP server (streamable-http) to an OpenAPI endpoint that OpenWebUI can consume.

### Prerequisites

```bash
pip install mcpo
```

### Run the MCP server + mcpo proxy

The OpenWebUI scripts start the MCP server in the background, then launch mcpo
pointing at it over streamable-http:

From the `azure-ai-search-mcp` directory:

**Windows (PowerShell):**

```powershell
.\scripts\openwebui_mcp.ps1                                       # MCP on 8000, mcpo on 8001
.\scripts\openwebui_mcp.ps1 -McpPort 9090 -McpoPort 9000          # custom ports
.\scripts\openwebui_mcp.ps1 -ApiKey "my-secret"                   # custom api key
```

**macOS / Linux:**

```bash
chmod +x scripts/openwebui_mcp.sh
./scripts/openwebui_mcp.sh                     # MCP on 8000, mcpo on 8001
./scripts/openwebui_mcp.sh 9090 9000           # custom ports
./scripts/openwebui_mcp.sh 8080 8000 my-key    # custom ports + api key
```

> **Note:** If you already have the MCP server running (e.g. via `scripts/prod.ps1`),
> you can start mcpo separately: `mcpo --port 8001 --config mcpo-config.json --api-key "top-secret"`

### Add to OpenWebUI

1. Open OpenWebUI (default: `http://localhost:8080`)
2. Click on your profile (bottom left) → **Admin Panel**
3. In top nav bar, click on **Settings** → **External Tools**
4. Click the plus icon next to **Manage Tool Servers**
5. Enter:
   - **URL**: `http://localhost:8001/azure-ai-search`
   - **API Key**: `top-secret` (or whatever you set when launching the script)
6. Click **Save**

The MCP tools will now be available in your OpenWebUI chats (you may need to enable them manually before submitting a prompt).

> **Note:** The mcpo proxy and the GitHub Copilot config both connect to the same
> running MCP server over streamable-http — they can run simultaneously without conflict.

## Troubleshooting

### "Missing required environment variables"

Ensure all three environment variables are set:

- `AZURE_SEARCH_ENDPOINT`
- `AZURE_SEARCH_API_KEY`
- `AZURE_SEARCH_INDEX_NAME`

### Semantic search configuration

Semantic search works with or without explicit semantic configuration:

- **With semantic configuration**: Uses Azure's semantic ranker for best results
- **Without semantic configuration**: Falls back to vector search if vectorizer is configured, otherwise uses standard search
- You don't need semantic configuration if you have a vectorizer configured in your index

### "Document with ID 'xxx' not found"

The document ID doesn't exist in your index. Use a search tool first to find valid document IDs.

## Development

### Project Structure

```
azure-ai-search-mcp/
├── main.py                    # MCP server entry point
├── pyproject.toml             # Project dependencies
├── .python-version            # Python version specification
├── azure_search_client.py      # Azure Search client utilities
├── mcpo-config.json            # mcpo config for OpenWebUI integration
├── scripts/
│   ├── dev.ps1                # Dev mode launcher (Windows)
│   ├── dev.sh                 # Dev mode launcher (macOS/Linux)
│   ├── openwebui_mcp.ps1      # OpenWebUI mcpo launcher (Windows)
│   ├── openwebui_mcp.sh       # OpenWebUI mcpo launcher (macOS/Linux)
│   ├── prod.ps1               # Prod mode launcher (Windows)
│   └── prod.sh                # Prod mode launcher (macOS/Linux)
├── azure/
│   ├── Dockerfile              # Multi-stage Docker build
│   ├── .dockerignore           # Build-context exclusions
│   ├── infra.bicep             # Phase 1: ACR + Log Analytics + Environment
│   ├── app.bicep               # Phase 2: Container App
│   ├── deploy.ps1              # One-command deployment script
│   └── README.md               # Deployment guide
├── tools/
│   ├── __init__.py
│   ├── semantic_search.py      # Semantic search tool
│   ├── hybrid_search.py        # Hybrid search tool
│   ├── text_search.py          # Text search tool
│   ├── filtered_search.py      # Filtered search tool
│   └── fetch_document.py       # Document fetch tool
└── README.md                  # This file
```

## Related Resources

- [Azure AI Search Documentation](https://docs.microsoft.com/azure/search/)
- [Model Context Protocol](https://modelcontextprotocol.io/)
- [Azure SDK for Python](https://docs.microsoft.com/python/azure/)

## Credits

- [Aryan Shah (SE Intern)](https://github.com/aryxenv): MCP Server Setup + Github Copilot MCP setup & integration + OpenWebUI MCP setup & integration + MCP Deployment + Documentation
- [Anass Gallass (SSP Intern)](https://github.com/anassgallass): Testing AI Search & GHCP MCP
- [Bertille Mathieu (SE Intern)](https://github.com/bertillessec): Testing AI Search & OpenWebUI MCP
