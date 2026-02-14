"""Text search tool - Traditional keyword-based search."""

from azure_search_client import get_search_client, get_excluded_fields, format_search_results


def text_search(query: str, top: int = 5) -> dict:
    """
    Perform traditional text/keyword search using Azure AI Search.
    
    Args:
        query: The search query string
        top: Maximum number of results to return (default: 30)
    
    Returns:
        Dictionary containing search results
    """
    client = get_search_client()
    excluded_fields = get_excluded_fields()
    
    # Perform standard full-text search
    results = client.search(search_text=query, top=top)
    
    formatted_results = format_search_results(results, excluded_fields)
    
    return {
        "query": query,
        "count": len(formatted_results),
        "results": formatted_results,
    }
