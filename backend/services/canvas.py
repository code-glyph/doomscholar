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
                    # Canvas often returns JSON with "message"; surface it for debugging
                    try:
                        body = response.json()
                        msg = body.get("message", body.get("errors", response.text))
                    except Exception:
                        msg = response.text
                    raise CanvasAPIError(
                        403,
                        f"Access denied to course files (course_id={course_id}). "
                        f"Canvas says: {msg}. "
                        "Often the token's user role (e.g. Student) lacks 'read_course_content'; "
                        "try a token from a Teacher/Designer account or check institutional permissions.",
                    )
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

    async def list_course_files_via_modules(
        self,
        course_id: int,
        *,
        per_page: int = 50,
    ) -> list[dict[str, Any]]:
        """
        List files that appear in course modules (student-accessible).
        Uses Modules + Module Items API instead of the direct files endpoint,
        so it works with student tokens when list_course_files returns 403.
        Returns one dict per File module item: file_id, title, module_id, module_name, etc.
        """
        base = self.base_url
        headers = self._headers()
        result: list[dict[str, Any]] = []

        async with httpx.AsyncClient(timeout=self.timeout) as client:
            # Paginate through modules
            modules_url = f"{base}/api/v1/courses/{course_id}/modules"
            params: dict[str, Any] = {"per_page": per_page}
            while modules_url:
                mod_resp = await client.get(
                    modules_url, headers=headers, params=params
                )
                if mod_resp.status_code == 401:
                    raise CanvasAPIError(
                        401, "Canvas access token invalid or expired"
                    )
                if mod_resp.status_code == 403:
                    try:
                        body = mod_resp.json()
                        msg = body.get("message", body.get("errors", mod_resp.text))
                    except Exception:
                        msg = mod_resp.text
                    raise CanvasAPIError(
                        403,
                        f"Access denied to course modules (course_id={course_id}). Canvas: {msg}",
                    )
                if mod_resp.status_code == 404:
                    raise CanvasAPIError(404, f"Course {course_id} not found.")
                if mod_resp.status_code != 200:
                    raise CanvasAPIError(mod_resp.status_code, mod_resp.text)

                modules = mod_resp.json()
                for mod in modules:
                    mod_id = mod.get("id")
                    mod_name = mod.get("name", "")

                    # Paginate through items in this module
                    items_url = f"{base}/api/v1/courses/{course_id}/modules/{mod_id}/items"
                    item_params: dict[str, Any] = {"per_page": per_page}
                    while items_url:
                        item_resp = await client.get(
                            items_url, headers=headers, params=item_params
                        )
                        if item_resp.status_code != 200:
                            break
                        items = item_resp.json()
                        for it in items:
                            if it.get("type") != "File":
                                continue
                            result.append({
                                "file_id": it.get("content_id"),
                                "module_item_id": it.get("id"),
                                "title": it.get("title", ""),
                                "module_id": mod_id,
                                "module_name": mod_name,
                                "position": it.get("position"),
                                "html_url": it.get("html_url", ""),
                                "url": it.get("url", ""),
                            })
                        items_url = None
                        item_params = {}
                        for part in item_resp.headers.get("link", "").split(","):
                            if 'rel="next"' in part:
                                items_url = part.split(";")[0].strip().strip("<>")
                                break

                modules_url = None
                params = {}
                for part in mod_resp.headers.get("link", "").split(","):
                    if 'rel="next"' in part:
                        modules_url = part.split(";")[0].strip().strip("<>")
                        break

        return result


# Singleton for use by routes; can be overridden in tests
canvas_service = CanvasService()
