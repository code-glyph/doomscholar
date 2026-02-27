"""Canvas LMS API client."""

from typing import Any

import httpx

from config import settings


class CanvasAPIError(Exception):
    """Canvas API returned an error."""

    def __init__(self, status_code: int, body: str | None = None):
        self.status_code = status_code
        self.body = body or ""
        super().__init__(f"Canvas API error: {status_code} - {self.body[:200]}")


class CanvasService:
    """Calls Canvas REST API with the configured access token."""

    def __init__(
        self,
        *,
        base_url: str | None = None,
        access_token: str | None = None,
        timeout: float = 30.0,
    ):
        self.base_url = (base_url or settings.canvas_base_url).rstrip("/")
        self.access_token = access_token or settings.canvas_access_token
        self.timeout = timeout

    def _headers(self) -> dict[str, str]:
        return {"Authorization": f"Bearer {self.access_token}"}

    async def list_courses(
        self,
        *,
        enrollment_state: str | None = None,
        include: list[str] | None = None,
        per_page: int | None = None,
    ) -> list[dict[str, Any]]:
        """Fetch courses for the authenticated user."""
        url = f"{self.base_url}/api/v1/courses"
        params: dict[str, Any] = {}
        if enrollment_state:
            params["enrollment_state"] = enrollment_state
        if include:
            params["include[]"] = include
        if per_page is not None:
            params["per_page"] = per_page

        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.get(
                url,
                headers=self._headers(),
                params=params,
            )

        if response.status_code == 401:
            raise CanvasAPIError(401, "Canvas access token invalid or expired")
        if response.status_code != 200:
            raise CanvasAPIError(response.status_code, response.text)

        return response.json()


# Singleton for use by routes; can be overridden in tests
canvas_service = CanvasService()
