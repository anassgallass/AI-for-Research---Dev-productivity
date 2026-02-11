# Azure AI Search MCP Server

A Python-based Model Context Protocol (MCP) server that integrates Azure AI Search capabilities into agentic workflows. This server provides semantic search, hybrid search, text search, filtered search, and document retrieval tools for AI agents.

## Features

- 🔍 **Semantic Search**: AI-powered search that understands context and meaning
- 🔀 **Hybrid Search**: Combines full-text and vector search for balanced results
- 📝 **Text Search**: Traditional keyword-based search
- 🔎 **Filtered Search**: Search with OData filter expressions
- 📄 **Document Fetch**: Retrieve specific documents by ID
- 📊 **Index Schema Resource**: Access to index field definitions and metadata

## Installation

### Prerequisites

- uv
- Python 3.11 or higher
- Azure AI Search Service
- API keys (see `.env.example`)

### From Source

```bash
git clone https://github.com/anassgallass/AI-for-Research---Dev-productivity.git
cd mcp-server
uv sync
```

## Configuration

### Environment Variables

Create a `.env` file in your workspace root (parent of `mcp-server` directory) with these variables:

```env
AZURE_SEARCH_ENDPOINT=https://your-search-service.search.windows.net
AZURE_SEARCH_API_KEY=your-api-key-here
AZURE_SEARCH_INDEX_NAME=your-index-name

# Optional: Comma-separated list of fields to exclude from search results
# Default: content,content_vector
AZURE_SEARCH_EXCLUDE_FIELDS=content,content_vector
```

### Required Azure Resources

1. **Azure AI Search Service**: Create a search service in the Azure Portal
2. **Search Index**: Configure an index with your data
3. **API Key**: Get the admin or query key from the Azure Portal

Optional for enhanced semantic search:
- **Semantic Configuration**: Enables Azure's semantic ranker (recommended but not required)
- **Vectorizer**: Enables vector-based semantic search (works without semantic configuration)

## Usage

### Run the Server

```bash
uv run main.py
```

The server will listen on stdio and communicate via the Model Context Protocol.

### With VSCode

Add to your VSCode configuration:

**Config file**: `.vscode/mcp.json`

```json
{
    "mcpServers": {
        "azure-ai-search": {
            "command": "uv",
            "args": [
                "run",
                "--env-file",
                "../.env",
                "mcp",
                "run",
                "main.py"
            ],
            "cwd": "${workspaceFolder}/mcp-server"
        }
    }
}
```

Ensure the `.vscode` directory exists in your workspace root.

## Available Tools

### 1. `semantic_search`

Performs AI-powered semantic search that understands context and meaning. Works with or without semantic configuration - will use vectorizer if semantic configuration is not available.

**Parameters:**
- `query` (string, required): The search query
- `top` (number, optional): Maximum results to return (default: 30)

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
- `top` (number, optional): Maximum results to return (default: 30)

**Example:**
```json
{
  "query": "artificial intelligence trends",
  "top": 30
}
```

### 3. `text_search`

Traditional keyword-based text search.

**Parameters:**
- `query` (string, required): The search query
- `top` (number, optional): Maximum results to return (default: 30)

**Example:**
```json
{
  "query": "data science",
  "top": 30
}
```

### 4. `filtered_search`

Search with OData filter expressions to narrow results.

**Parameters:**
- `query` (string, required): The search query
- `filter` (string, required): OData filter expression
- `top` (number, optional): Maximum results to return (default: 30)

**Example:**
```json
{
  "query": "technology",
  "filter": "category eq 'AI' and year ge 2020",
  "top": 30
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

- **Search tools** (`semantic_search`, `hybrid_search`, `text_search`, `filtered_search`): Return document summaries without fields specified in `AZURE_SEARCH_EXCLUDE_FIELDS` environment variable (default: `content`, `content_vector`)
- **Fetch document**: Always returns full document with only `content` and `content_vector` fields excluded

You can customize which fields are excluded via the `AZURE_SEARCH_EXCLUDE_FIELDS` environment variable. The `fetch_document` tool always excludes only `content` and `content_vector` for security.

## Security Notes

- **API Keys**: Never commit API keys to version control
- **Environment Variables**: Use environment variables or secure secret management
- **Access Control**: Use Azure RBAC and query keys (not admin keys) in production
- **Rate Limiting**: Be aware of Azure Search service tier limits
- **Field Exclusion**: Use `AZURE_SEARCH_EXCLUDE_FIELDS` to prevent sensitive data from being returned in search results
- **Data Privacy**: The `content` and `content_vector` fields are always excluded from search results by default

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
mcp-server/
├── main.py                    # MCP server entry point
├── pyproject.toml             # Project dependencies
├── .env.example               # Example environment variables
├── .python-version            # Python version specification
├── azure_search_client.py      # Azure Search client utilities
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
