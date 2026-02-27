"""Cohere embedding client."""

import cohere
from config.settings import settings

# embed-english-v3.0 produces 1024-dimensional float vectors
EMBED_MODEL = "embed-english-v3.0"
EMBED_DIMENSION = 1024
_BATCH_SIZE = 96  # Cohere embed endpoint max texts per request

_client = cohere.AsyncClient(api_key=settings.cohere_api_key)


async def embed_texts(texts: list[str]) -> list[list[float]]:
    """
    Embed a list of texts using Cohere embed-english-v3.0.
    Automatically batches into groups of 96.
    Returns a list of 1024-dimensional float vectors.
    """
    all_embeddings: list[list[float]] = []

    for i in range(0, len(texts), _BATCH_SIZE):
        batch = texts[i : i + _BATCH_SIZE]
        response = await _client.embed(
            texts=batch,
            model=EMBED_MODEL,
            input_type="search_document",
        )
        all_embeddings.extend(response.embeddings)

    return all_embeddings
