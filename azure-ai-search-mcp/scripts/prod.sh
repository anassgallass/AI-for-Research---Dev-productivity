#!/usr/bin/env bash
# -------------------------------------------------------
# Start Azure AI Search MCP server in PRODUCTION / STDIO mode
# For use with GitHub Copilot, Claude Desktop, etc.
# -------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "======================================="
echo "  Azure AI Search MCP - PROD MODE"
echo "  Transport : stdio"
echo "======================================="
echo ""

uv run python main.py --transport stdio
