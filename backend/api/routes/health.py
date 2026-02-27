"""Health and config check (for Postman / debugging)."""

from fastapi import APIRouter

from config import settings

router = APIRouter()


@router.get("/health")
def health() -> dict:
    """
    Confirm app is up and Canvas is configured.
    Does not expose the token; use this in Postman to verify before calling /courses.
    """
    token_set = bool(
        settings.canvas_access_token
        and settings.canvas_access_token != "your-canvas-access-token-here"
    )
    return {
        "status": "ok",
        "canvas_base_url": settings.canvas_base_url,
        "canvas_token_configured": token_set,
    }
