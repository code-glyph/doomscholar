"""Canvas LMS API client."""
import io
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

    async def list_course_files(
        self,
        course_id: int,
        *,
        per_page: int = 50,
    ) -> list[dict[str, Any]]:
        """
        Fetch all files for a course, following Canvas pagination.
        GET /api/v1/courses/:course_id/files
        """
        url = f"{self.base_url}/api/v1/courses/{course_id}/files"
        params: dict[str, Any] = {"per_page": per_page}
        all_files: list[dict[str, Any]] = []

        async with httpx.AsyncClient(timeout=self.timeout) as client:
            while url:
                response = await client.get(url, headers=self._headers(), params=params)

                if response.status_code == 401:
                    raise CanvasAPIError(401, "Canvas access token invalid or expired.")
                if response.status_code == 403:
                    raise CanvasAPIError(403, f"Access denied to files for course {course_id}.")
                if response.status_code == 404:
                    raise CanvasAPIError(404, f"Course {course_id} not found.")
                if response.status_code != 200:
                    raise CanvasAPIError(response.status_code, response.text)

                all_files.extend(response.json())

                # Follow Canvas Link header pagination
                url = None
                params = {}
                for part in response.headers.get("link", "").split(","):
                    if 'rel="next"' in part:
                        url = part.split(";")[0].strip().strip("<>")
                        break

        return all_files
    
    async def download_file(self, file_obj: dict[str, Any]) -> io.BytesIO:
        """
        Stream a Canvas file into an in-memory BytesIO buffer.
        Uses the 'url' field already present in the file object
        returned by list_course_files().
        """
        download_url = file_obj.get("url", "")
        display_name = file_obj.get("display_name", "unknown")

        if not download_url:
            raise CanvasAPIError(404, f"No download URL for file '{display_name}'.")

        async with httpx.AsyncClient(timeout=self.timeout) as client:
            async with client.stream("GET", download_url, headers=self._headers()) as response:
                if response.status_code == 401:
                    raise CanvasAPIError(401, "Canvas access token invalid or expired.")
                if response.status_code != 200:
                    raise CanvasAPIError(response.status_code, f"Failed to download '{display_name}'.")

                buffer = io.BytesIO()
                async for chunk in response.aiter_bytes(chunk_size=8192):
                    buffer.write(chunk)

        buffer.seek(0)
        return buffer

# Singleton for use by routes; can be overridden in tests
canvas_service = CanvasService()
