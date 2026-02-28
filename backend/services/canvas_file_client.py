"""
Minimal Canvas file-by-ID client. Used to fetch file metadata (url, content-type)
for use with canvas_service.download_file and parser, without modifying canvas.py.
"""

from typing import Any

import httpx

from config import settings


class CanvasFileClientError(Exception):
    """Raised when file fetch fails."""
    pass


async def get_file_metadata(file_id: int) -> dict[str, Any]:
    """
    GET /api/v1/files/:id and return the file object (url, content-type, display_name, etc.).
    Required so we can download and check is_supported; via_modules does not include content-type.
    """
    base = settings.canvas_base_url.rstrip("/")
    url = f"{base}/api/v1/files/{file_id}"
    headers = {"Authorization": f"Bearer {settings.canvas_access_token}"}
    async with httpx.AsyncClient(timeout=30.0) as client:
        resp = await client.get(url, headers=headers)
    if resp.status_code != 200:
        raise CanvasFileClientError(f"Canvas files/{file_id} returned {resp.status_code}: {resp.text[:200]}")
    return resp.json()
