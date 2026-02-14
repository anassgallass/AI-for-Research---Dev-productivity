"""Fetch document tool - Retrieve a specific document by its unique ID."""

from azure_search_client import get_search_client, format_fetch_results


def fetch_document(document_id: str) -> dict:
    """
    Retrieve a specific document by its unique ID from Azure Search.
    Returns the complete document with all fields (excludes only contentVector).
    
    Args:
        document_id: The document's unique identifier
    
    Returns:
        Dictionary containing the document
    """
    client = get_search_client()
    
    try:
        # Fetch the document by ID
        doc = client.get_document(document_id)
        
        formatted_doc = format_fetch_results(doc)
        
        return {
            "document_id": document_id,
            "found": True,
            "document": formatted_doc,
        }
    except Exception as e:
        return {
            "document_id": document_id,
            "found": False,
            "error": f"Document with ID '{document_id}' not found: {str(e)}",
        }
