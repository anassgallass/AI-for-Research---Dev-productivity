#!/usr/bin/env bash
# -------------------------------------------------------
# Start Azure AI Search MCP server via mcpo for OpenWebUI
# Exposes the MCP tools as an OpenAPI endpoint.
#
# After starting, add in OpenWebUI:
#   Admin Panel > Settings > Tools > OpenAPI Servers > Add Connection
#   URL  : http://localhost:<PORT>/azure-ai-search
#   Key  : <API_KEY>
# -------------------------------------------------------
set -euo pipefail

PORT="${1:-8000}"
API_KEY="${2:-top-secret}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "================================================"
echo "  Azure AI Search MCP - OpenWebUI (via mcpo)"
echo "  mcpo endpoint : http://localhost:$PORT"
echo "  Tools docs    : http://localhost:$PORT/azure-ai-search/docs"
echo "================================================"
echo ""
echo "Add to OpenWebUI -> Admin -> Settings -> Tools -> OpenAPI Servers:"
echo "  URL : http://localhost:$PORT/azure-ai-search"
echo "  Key : $API_KEY"
echo ""

if [ -n "$API_KEY" ]; then
    mcpo --port "$PORT" --api-key "$API_KEY" --config mcpo-config.json
else
    mcpo --port "$PORT" --config mcpo-config.json
fi
