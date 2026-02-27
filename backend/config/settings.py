"""Application settings from environment (and optional .env file)."""

import os
from pathlib import Path
from dotenv import load_dotenv

_backend_dir = Path(__file__).resolve().parent.parent
load_dotenv(_backend_dir / ".env")

def _str(name: str, default: str) -> str:
    value = os.environ.get(name, default)
    return (value or "").strip()


class Settings:
    """Canvas, Cohere, and Qdrant configuration."""

    canvas_access_token: str = _str("CANVAS_ACCESS_TOKEN", "")
    canvas_base_url: str = _str("CANVAS_BASE_URL", "https://psu.instructure.com").rstrip("/")

    # Cohere
    cohere_api_key: str = _str("COHERE_API_KEY", "")

    # Qdrant
    qdrant_url: str = _str("QDRANT_URL", "")
    qdrant_api_key: str = _str("QDRANT_API_KEY", "")
    qdrant_collection_name: str = _str("QDRANT_COLLECTION_NAME", "doomscholar")


settings = Settings()
