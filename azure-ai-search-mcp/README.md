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
.\scripts\dev.ps1              # default SSE port 8080
.\scripts\dev.ps1 -Port 9090   # custom port
```

**macOS / Linux:**

```bash
chmod +x scripts/dev.sh
./scripts/dev.sh            # default SSE port 8080
./scripts/dev.sh 9090       # custom port
```

The Inspector will open at **http://localhost:6274**.

### Prod Mode (stdio)

Prod mode runs the server over **stdio**, which is the transport expected by GitHub Copilot, Claude Desktop, and most MCP clients.

**Windows (PowerShell):**

```powershell
.\scripts\prod.ps1
```

**macOS / Linux:**

```bash
chmod +x scripts/prod.sh
./scripts/prod.sh
```

You can also run directly:

```bash
uv run python main.py                    # stdio (default)
uv run python main.py --transport sse    # SSE mode
uv run python main.py --transport sse --port 9090
```

## GitHub Copilot Integration

This server can be used as a **custom MCP server** in GitHub Copilot (VS Code).

### Option 1 — Workspace config (recommended)

A ready-to-use config is provided at `.vscode/mcp.json`. Open it and fill in your Azure credentials when prompted, **or** hardcode environment values:

```jsonc
// .vscode/mcp.json
{
  "servers": {
    "azure-ai-search": {
      "type": "stdio",
      "command": "uv",
      "args": [
        "run",
        "--directory",
        "${workspaceFolder}/azure-ai-search-mcp",
        "python",
        "main.py",
        "--transport",
        "stdio",
      ],
      "env": {
        "AZURE_SEARCH_ENDPOINT": "https://your-service.search.windows.net",
        "AZURE_SEARCH_API_KEY": "your-api-key",
        "AZURE_SEARCH_INDEX_NAME": "your-index-name",
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
        "type": "stdio",
        "command": "uv",
        "args": [
          "run",
          "--directory",
          "/absolute/path/to/azure-ai-search-mcp",
          "python",
          "main.py",
          "--transport",
          "stdio",
        ],
        "env": {
          "AZURE_SEARCH_ENDPOINT": "https://your-service.search.windows.net",
          "AZURE_SEARCH_API_KEY": "your-api-key",
          "AZURE_SEARCH_INDEX_NAME": "your-index-name",
        },
      },
    },
  },
}
```

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

OpenWebUI doesn't support MCP's stdio transport natively. We use [`mcpo`](https://pypi.org/project/mcpo/) to bridge the MCP server to an OpenAPI endpoint that OpenWebUI can consume.

### Prerequisites

```bash
pip install mcpo
```

### Run the mcpo proxy

From the `azure-ai-search-mcp` directory:

**Windows (PowerShell):**

```powershell
.\scripts\openwebui.ps1                        # default port 8000, api-key "top-secret"
.\scripts\openwebui.ps1 -Port 9000             # custom port
.\scripts\openwebui.ps1 -ApiKey "my-secret"    # custom api key
```

**macOS / Linux:**

```bash
chmod +x scripts/openwebui.sh
./scripts/openwebui.sh              # default port 8000, api-key "top-secret"
./scripts/openwebui.sh 9000         # custom port
./scripts/openwebui.sh 8000 my-key  # custom port + api key
```

### Add to OpenWebUI

1. Open OpenWebUI (default: `http://localhost:8080`)
2. Click on your profile (bottom left) → **Admin Panel**
3. In top nav bar, click on **Settings** → **External Tools**
4. Click the plus icon next to **Manage Tool Servers**
5. Enter:
   - **URL**: `http://localhost:8000/azure-ai-search`
   - **API Key**: `top-secret` (or whatever you set when launching the script)
6. Click **Save**

The MCP tools will now be available in your OpenWebUI chats (you may need to enable them manually before submitting a prompt).

> **Note:** The mcpo proxy and the GitHub Copilot stdio config are completely independent — they spawn separate processes and do not interfere with each other.

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
├── .env.example               # Example environment variables
├── .python-version            # Python version specification
├── azure_search_client.py      # Azure Search client utilities
├── mcpo-config.json            # mcpo config for OpenWebUI integration
├── scripts/
│   ├── dev.ps1                # Dev mode launcher (Windows)
│   ├── dev.sh                 # Dev mode launcher (macOS/Linux)
│   ├── openwebui.ps1          # OpenWebUI mcpo launcher (Windows)
│   ├── openwebui.sh           # OpenWebUI mcpo launcher (macOS/Linux)
│   ├── prod.ps1               # Prod mode launcher (Windows)
│   └── prod.sh                # Prod mode launcher (macOS/Linux)
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

- [Aryan Shah (SE Intern)](https://github.com/aryxenv): MCP Server Setup + Github Copilot MCP setup & integration + OpenWebUI MCP setup & integration + Documentation
- [Anass Gallass (SSP Intern)](https://github.com/anassgallass): Testing AI Search & GHCP MCP
- [Bertille Mathieu (SE Intern)](https://github.com/bertillessec): Testing AI Search & OpenWebUI MCP
