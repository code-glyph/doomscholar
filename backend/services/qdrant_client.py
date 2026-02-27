"""Qdrant vector store client."""

import uuid
from qdrant_client import AsyncQdrantClient
from qdrant_client.models import Distance, VectorParams, PointStruct

from config.settings import settings
from services.cohere_client import EMBED_DIMENSION

_client = AsyncQdrantClient(
    url=settings.qdrant_url,
    api_key=settings.qdrant_api_key,
)

_UPSERT_BATCH = 100  # points per upsert call


async def ensure_collection() -> None:
    """Create the Qdrant collection if it does not already exist."""
    exists = await _client.collection_exists(settings.qdrant_collection_name)
    if not exists:
        await _client.create_collection(
            collection_name=settings.qdrant_collection_name,
            vectors_config=VectorParams(
                size=EMBED_DIMENSION,
                distance=Distance.COSINE,
            ),
        )


async def upsert_chunks(points_data: list[dict]) -> None:
    """
    Upsert a list of chunk dicts into Qdrant.
    Each dict must have a 'vector' key (list[float]) plus any
    payload fields (course_id, file_id, chunk_text, etc.).
    """
    points = [
        PointStruct(
            id=str(uuid.uuid4()),
            vector=p["vector"],
            payload={k: v for k, v in p.items() if k != "vector"},
        )
        for p in points_data
    ]

    # Upsert in batches to avoid request size limits
    for i in range(0, len(points), _UPSERT_BATCH):
        await _client.upsert(
            collection_name=settings.qdrant_collection_name,
            points=points[i : i + _UPSERT_BATCH],
            wait=True,
        )
