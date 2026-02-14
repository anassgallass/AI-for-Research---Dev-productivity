"""Azure Search client setup and utilities."""

import os
from azure.search.documents import SearchClient
from azure.search.documents.models import VectorizedQuery
from azure.core.credentials import AzureKeyCredential


def get_search_client() -> SearchClient:
    """Initialize and return Azure Search client."""
    endpoint = os.getenv("AZURE_SEARCH_ENDPOINT")
    api_key = os.getenv("AZURE_SEARCH_API_KEY")
    index_name = os.getenv("AZURE_SEARCH_INDEX_NAME")

    if not all([endpoint, api_key, index_name]):
        raise ValueError(
            "Missing required environment variables: "
            "AZURE_SEARCH_ENDPOINT, AZURE_SEARCH_API_KEY, AZURE_SEARCH_INDEX_NAME"
        )

    credential = AzureKeyCredential(api_key)
    return SearchClient(endpoint=endpoint, index_name=index_name, credential=credential)


def get_excluded_fields() -> set[str]:
    """Get set of fields to exclude from search results."""
    excluded = os.getenv("AZURE_SEARCH_EXCLUDE_FIELDS", "contentVector")
    return set(field.strip() for field in excluded.split(","))


def filter_document(doc: dict, excluded_fields: set[str]) -> dict:
    """Remove excluded fields from a document."""
    return {k: v for k, v in doc.items() if k not in excluded_fields}


def format_search_results(results, excluded_fields: set[str]) -> list[dict]:
    """Format search results by removing excluded fields."""
    formatted = []
    for result in results:
        doc = result.get("document", result)
        formatted.append(filter_document(doc, excluded_fields))
    return formatted


def format_fetch_results(doc: dict) -> dict:
    """Format fetch document results (always exclude contentVector)."""
    # fetch_document always excludes only contentVector
    always_excluded = {"contentVector"}
    return filter_document(doc, always_excluded)
