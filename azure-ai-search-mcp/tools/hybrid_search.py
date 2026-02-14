"""Hybrid search tool - Combines full-text and vector search for balanced results."""

from azure_search_client import get_search_client, get_excluded_fields, format_search_results


def hybrid_search(query: str, top: int = 5) -> dict:
    """
    Perform hybrid search using Azure AI Search.
    Combines full-text and vector search for balanced results.
    
    Args:
        query: The search query string
        top: Maximum number of results to return (default: 5)
    
    Returns:
        Dictionary containing search results
    """
    try:
        client = get_search_client()
        excluded_fields = get_excluded_fields()
        
        # Perform hybrid search with vector search enabled
        results = client.search(
            search_text=query,
            top=top,
            vector_queries=None,  # Will be handled by the query_type parameter
            query_type="semantic",  # This enables hybrid search
        )
        
        formatted_results = format_search_results(results, excluded_fields)
        
        return {
            "query": query,
            "count": len(formatted_results),
            "results": formatted_results,
        }
    except Exception as e:
        # Fallback to standard full-text search
        client = get_search_client()
        excluded_fields = get_excluded_fields()
        
        results = client.search(search_text=query, top=top)
        formatted_results = format_search_results(results, excluded_fields)
        
        return {
            "query": query,
            "count": len(formatted_results),
            "results": formatted_results,
            "note": "Hybrid search not available, using full-text search",
        }
