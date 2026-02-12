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
3. Create Azure RG called `ai_for_research`

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
13. in the `.env` on field `AZURE_SEARCH_INDEX_NAME`, rename that to your index name, by default if not changed, use `vector-index`.
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

## MCP

1. Navigate to [`azure-ai-search-mcp`](./azure-ai-search-mcp/), this will now be your main directory.
2. Install dependencies with uv:

```bash
uv sync
```

### Run the MCP server

You must run these from the `azure-ai-search-mcp` directory for the scripts to work.

**Option A: Use the scripts**

```powershell
# Dev server
./scripts/dev_server.ps1

# Prod server
./scripts/prod_server.ps1
```

**Option B: Run directly with uv**

```bash
# Dev mode
uv run mcp dev main.py # add flag `--env-file ../.env` between `run` and `mcp` for env file handling, but currently buggy (not fixed yet)

# Prod mode
uv run mcp run main.py # add flag `--env-file ../.env` between `run` and `mcp` for env file handling, but currently buggy (not fixed yet)
```

### GitHub Copilot MCP setup

1. No setup needed, already available in [`.vscode/mcp.json`](./.vscode/mcp.json).
2. Just click on `Start Server` and now Github Copilot can use the MCP server in the chat. (Note: currently not working due to an unresolved bug)

> [!NOTE]
> You may need to reload VS Code or the window so GitHub Copilot picks up the MCP server.

## Credits

[Aryan Shah (SE Intern)](https://github.com/aryxenv): RAG Pipeline + Azure Setup + Foundry Setup + MCP Server Setup + Documentation
[Anass Gallass (SSP Intern)](https://github.com/anassgallass): Github MCP setup & integration
[Bertille Mathieu (SE Intern)](https://github.com/bertillessec): OpenWebUI MCP setup & integration
