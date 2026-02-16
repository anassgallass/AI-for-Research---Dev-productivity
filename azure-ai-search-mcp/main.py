"""Azure AI Search MCP Server.

This server provides semantic search, hybrid search, text search, filtered search,
and document retrieval tools for AI agents using Azure AI Search.

Supports three transport modes:
  - streamable-http (default): HTTP endpoint for GitHub Copilot, Claude Desktop,
                                remote/containerised deployments, and mcpo proxy
  - stdio  : Legacy local-process mode (fallback only)
  - sse    : Legacy SSE streaming (fallback only)

Usage:
  python main.py                                          # streamable-http on 0.0.0.0:8000
  python main.py --port 9000                              # custom port
  python main.py --host 127.0.0.1                         # localhost only
  python main.py --transport stdio                        # legacy stdio
  python main.py --transport sse --port 8000              # legacy SSE
"""

import argparse
import os
import json
import sys
from typing import Any

from dotenv import load_dotenv
from mcp.server.fastmcp import FastMCP # type: ignore
from mcp.server.transport_security import TransportSecuritySettings # type: ignore

from tools import (
    semantic_search as tool_semantic_search,
    hybrid_search as tool_hybrid_search,
    text_search as tool_text_search,
    filtered_search as tool_filtered_search,
    fetch_document as tool_fetch_document,
)

# Load environment variables from .env in current dir and parent dir
# load_dotenv()                          # if env is in ./azure-ai-search-mcp/.env
load_dotenv(dotenv_path="../.env")     # if env is in workspace root

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


def _build_transport_security(host: str) -> TransportSecuritySettings | None:
    """Build transport security settings based on the bind host.

    - localhost binds: enable DNS rebinding protection (SDK default behaviour).
    - 0.0.0.0 / other: disable protection so the server works behind reverse
      proxies (e.g. Azure Container Apps) where the Host header won't match.
    """
    if host in ("127.0.0.1", "localhost", "::1"):
        return TransportSecuritySettings(
            enable_dns_rebinding_protection=True,
            allowed_hosts=[f"{host}:*", "localhost:*", "127.0.0.1:*", "[::1]:*"],
            allowed_origins=[f"http://{host}:*", "http://localhost:*", "http://127.0.0.1:*", "http://[::1]:*"],
        )
    # Behind a reverse proxy – disable host-header checks
    return TransportSecuritySettings(enable_dns_rebinding_protection=False)


def create_server(host: str = "0.0.0.0", port: int = 8000) -> FastMCP:
    """Create and configure the FastMCP server instance.

    We must pass host/port at construction time so FastMCP computes
    transport_security correctly (DNS rebinding protection).
    """
    transport_security = _build_transport_security(host)

    server = FastMCP(
        "azure-ai-search-mcp",
        host=host,
        port=port,
        transport_security=transport_security,
    )

    # -- Register tools ---------------------------------------------------

    # for demo purposes, we only keep hybrid_search tool.
    # You can uncomment the others to enable them as well.

    # @server.tool()
    # async def semantic_search(query: str, top: int = 5) -> str:
    #     """
    #     Performs AI-powered semantic search that understands context and meaning.
    #     Works with or without semantic configuration.
    #     """
    #     result = tool_semantic_search(query=query, top=top)
    #     return json.dumps(result)

    @server.tool()
    async def hybrid_search(query: str, top: int = 5) -> str:
        """
        Combines full-text and vector search for balanced results.
        """
        result = tool_hybrid_search(query=query, top=top)
        return json.dumps(result)

    # @server.tool()
    # async def text_search(query: str, top: int = 5) -> str:
    #     """
    #     Traditional keyword-based text search.
    #     """
    #     result = tool_text_search(query=query, top=top)
    #     return json.dumps(result)

    # @server.tool()
    # async def filtered_search(query: str, filter: str, top: int = 5) -> str:
    #     """
    #     Search with OData filter expressions to narrow results.
    #
    #     Args:
    #         query: The search query
    #         filter: OData filter expression (e.g., "category eq 'AI' and year ge 2020")
    #         top: Maximum results to return
    #     """
    #     result = tool_filtered_search(query=query, filter=filter, top=top)
    #     return json.dumps(result)

    # @server.tool()
    # async def fetch_document(document_id: str) -> str:
    #     """
    #     Retrieve a specific document by its unique ID. Returns the complete document with all fields.
    #     """
    #     result = tool_fetch_document(document_id=document_id)
    #     return json.dumps(result)

    return server

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Azure AI Search MCP Server")
    parser.add_argument(
        "--transport",
        choices=["stdio", "sse", "streamable-http"],
        default="streamable-http",
        help="Transport protocol (default: streamable-http)",
    )
    parser.add_argument(
        "--host",
        type=str,
        default="0.0.0.0",
        help="Host to bind to (default: 0.0.0.0)",
    )
    parser.add_argument(
        "--port",
        type=int,
        default=8000,
        help="Port for HTTP/SSE transport (default: 8000)",
    )
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()

    server = create_server(host=args.host, port=args.port)

    if args.transport == "streamable-http":
        # Streamable HTTP - primary mode for remote / containerised deployments,
        # GitHub Copilot ("type": "http"), Claude Desktop, and mcpo proxy.
        server.run(transport="streamable-http")
    elif args.transport == "sse":
        # SSE mode - legacy; useful for MCP Inspector or older web clients
        server.run(transport="sse")
    else:
        # stdio mode - legacy local-process mode
        server.run(transport="stdio")