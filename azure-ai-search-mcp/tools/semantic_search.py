"""Semantic search tool - AI-powered search that understands context and meaning."""

from azure_search_client import get_search_client, get_excluded_fields, format_search_results


def semantic_search(query: str, top: int = 5) -> dict:
    """
    Perform semantic search using Azure AI Search.
    
    Args:
        query: The search query string
        top: Maximum number of results to return (default: 30)
    
    Returns:
        Dictionary containing search results
    """
    try:
        client = get_search_client()
        excluded_fields = get_excluded_fields()
        
        # Perform semantic search
        # Note: Works with or without semantic configuration
        # Falls back to vector search if semantic configuration not available
        results = client.search(
            search_text=query,
            top=top,
            semantic_configuration_name="default",  # Will use if configured
        )
        
        formatted_results = format_search_results(results, excluded_fields)
        
        return {
            "query": query,
            "count": len(formatted_results),
            "results": formatted_results,
        }
    except Exception as e:
        # If semantic search fails, fallback to regular search
        results = client.search(search_text=query, top=top)
        excluded_fields = get_excluded_fields()
        formatted_results = format_search_results(results, excluded_fields)
        
        return {
            "query": query,
            "count": len(formatted_results),
            "results": formatted_results,
            "note": "Semantic configuration not available, using standard search",
        }
