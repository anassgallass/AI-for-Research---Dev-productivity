# ----------  Azure AI Search MCP Server  ----------
# Multi-stage build using uv for fast, reproducible installs.
# Runs the MCP server with streamable-http transport on port 8000.

# ---- Stage 1: build ----
FROM ghcr.io/astral-sh/uv:python3.11-bookworm-slim AS builder

WORKDIR /app

# Copy dependency manifests first for layer caching
COPY pyproject.toml uv.lock* ./

# Install dependencies (no dev extras, frozen lock if present)
RUN uv sync --no-dev --no-install-project

# Copy application source
COPY main.py azure_search_client.py ./
COPY tools/ ./tools/

# ---- Stage 2: runtime ----
FROM python:3.11-slim-bookworm AS runtime

WORKDIR /app

# Copy the full virtual-env and source from builder
COPY --from=builder /app /app

# The uv venv lives at /app/.venv – put it on PATH
ENV PATH="/app/.venv/bin:$PATH"

# Env vars the server needs at runtime (supplied via Container App secrets / env)
# AZURE_SEARCH_ENDPOINT, AZURE_SEARCH_API_KEY, AZURE_SEARCH_INDEX_NAME
# Optional: AZURE_SEARCH_EXCLUDE_FIELDS

# Expose the MCP streamable-http port
EXPOSE 8000

# Health-check: the /mcp endpoint should respond (GET returns 405 which is fine)
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/mcp')" || exit 1

# Run the MCP server – streamable-http on 0.0.0.0:8000
CMD ["python", "main.py", "--transport", "streamable-http", "--host", "0.0.0.0", "--port", "8000"]
