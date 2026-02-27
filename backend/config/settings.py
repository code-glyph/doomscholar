"""Application settings from environment (and optional .env file)."""

import os

from pathlib import Path

from dotenv import load_dotenv

# Load .env from backend directory so token can be stored there for local testing
_backend_dir = Path(__file__).resolve().parent.parent
load_dotenv(_backend_dir / ".env")

def _str(name: str, default: str) -> str:
    value = os.environ.get(name, default)
    return (value or "").strip()


class Settings:
    """Canvas and app configuration."""

    canvas_access_token: str = _str(
        "CANVAS_ACCESS_TOKEN",
        "your-canvas-access-token-here",
    )
    canvas_base_url: str = _str(
        "CANVAS_BASE_URL",
        "https://psu.instructure.com",
    ).rstrip("/")


settings = Settings()
