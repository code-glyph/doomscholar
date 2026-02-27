"""Application settings from environment."""

import os


def _str(name: str, default: str) -> str:
    return os.environ.get(name, default).strip()


class Settings:
    """Canvas and app configuration."""

    canvas_access_token: str = _str(
        "CANVAS_ACCESS_TOKEN",
        "your-canvas-access-token-here",
    )
    canvas_base_url: str = _str(
        "CANVAS_BASE_URL",
        "https://canvas.instructure.com",
    ).rstrip("/")


settings = Settings()
