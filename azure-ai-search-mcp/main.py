"""Azure AI Search MCP Server.

This server provides semantic search, hybrid search, text search, filtered search,
and document retrieval tools for AI agents using Azure AI Search.

Supports two transport modes:
  - stdio  (default): For use with GitHub Copilot, Claude Desktop, and other MCP clients
  - sse   : For HTTP-based streaming (development / web clients)

Usage:
  python main.py              # stdio mode (default)
  python main.py --transport stdio
  python main.py --transport sse --port 8080
"""

import argparse
import os
import json
import sys
from typing import Any

from dotenv import load_dotenv
from mcp.server.fastmcp import FastMCP # type: ignore

from tools import (
    semantic_search as tool_semantic_search,
    hybrid_search as tool_hybrid_search,
    text_search as tool_text_search,
    filtered_search as tool_filtered_search,
    fetch_document as tool_fetch_document,
)

# Load environment variables from .env in current dir and parent dir
load_dotenv()                          # ./azure-ai-search-mcp/.env
load_dotenv(dotenv_path="../.env")     # workspace root .env

# Validate env vars before starting
required_vars = [
    "AZURE_SEARCH_ENDPOINT",
    "AZURE_SEARCH_API_KEY",
    "AZURE_SEARCH_INDEX_NAME",
]
missing_vars = [var for var in required_vars if not os.getenv(var)]
if missing_vars:
    print(f"Error: Missing required environment variables: {', '.join(missing_vars)}", file=sys.stderr)
    sys.exit(1)

# Create FastMCP server instance
server = FastMCP("azure-ai-search-mcp")

@server.tool()
async def semantic_search(query: str, top: int = 30) -> str:
    """
    Performs AI-powered semantic search that understands context and meaning. 
    Works with or without semantic configuration.
    """
    result = tool_semantic_search(query=query, top=top)
    return json.dumps(result)

@server.tool()
async def hybrid_search(query: str, top: int = 30) -> str:
    """
    Combines full-text and vector search for balanced results.
    """
    result = tool_hybrid_search(query=query, top=top)
    return json.dumps(result)

@server.tool()
async def text_search(query: str, top: int = 30) -> str:
    """
    Traditional keyword-based text search.
    """
    result = tool_text_search(query=query, top=top)
    return json.dumps(result)

@server.tool()
async def filtered_search(query: str, filter: str, top: int = 30) -> str:
    """
    Search with OData filter expressions to narrow results.
    
    Args:
        query: The search query
        filter: OData filter expression (e.g., "category eq 'AI' and year ge 2020")
        top: Maximum results to return
    """
    result = tool_filtered_search(query=query, filter=filter, top=top)
    return json.dumps(result)

@server.tool()
async def fetch_document(document_id: str) -> str:
    """
    Retrieve a specific document by its unique ID. Returns the complete document with all fields.
    """
    result = tool_fetch_document(document_id=document_id)
    return json.dumps(result)

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Azure AI Search MCP Server")
    parser.add_argument(
        "--transport",
        choices=["stdio", "sse"],
        default="stdio",
        help="Transport protocol (default: stdio)",
    )
    parser.add_argument(
        "--port",
        type=int,
        default=8080,
        help="Port for SSE transport (default: 8080)",
    )
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()

    if args.transport == "sse":
        # SSE mode – useful for development with MCP Inspector or web clients
        server.run(transport="sse", port=args.port)
    else:
        # stdio mode – used by GitHub Copilot, Claude Desktop, etc.
        server.run(transport="stdio")