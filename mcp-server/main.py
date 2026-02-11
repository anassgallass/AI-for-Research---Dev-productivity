"""Azure AI Search MCP Server.

This server provides semantic search, hybrid search, text search, filtered search,
and document retrieval tools for AI agents using Azure AI Search.
"""

import os
import json
import sys
from typing import Any

from dotenv import load_dotenv
from mcp.server.fastmcp import FastMCP

from tools import (
    semantic_search as tool_semantic_search,
    hybrid_search as tool_hybrid_search,
    text_search as tool_text_search,
    filtered_search as tool_filtered_search,
    fetch_document as tool_fetch_document,
)

# Load environment variables
load_dotenv()

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

if __name__ == "__main__":
    # fastmcp handles the running logic automatically
    server.run()