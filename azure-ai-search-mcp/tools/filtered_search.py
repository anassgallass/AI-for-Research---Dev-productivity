"""Filtered search tool - Search with OData filter expressions."""

from azure_search_client import get_search_client, get_excluded_fields, format_search_results


def filtered_search(query: str, filter: str, top: int = 5) -> dict:
    """
    Perform filtered search using Azure AI Search with OData expressions.
    
    Args:
        query: The search query string
        filter: OData filter expression (e.g., "category eq 'AI' and year ge 2020")
        top: Maximum number of results to return (default: 30)
    
    Returns:
        Dictionary containing search results
    """
    client = get_search_client()
    excluded_fields = get_excluded_fields()
    
    # Perform search with filter
    results = client.search(search_text=query, filter=filter, top=top)
    
    formatted_results = format_search_results(results, excluded_fields)
    
    return {
        "query": query,
        "filter": filter,
        "count": len(formatted_results),
        "results": formatted_results,
    }
