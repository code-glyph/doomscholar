"""Course endpoints (Canvas-backed)."""

from typing import Any

from fastapi import APIRouter, HTTPException

from services.canvas import canvas_service
from services.canvas import CanvasAPIError

router = APIRouter()


@router.get("", response_model=list[dict[str, Any]])
async def list_courses(
    enrollment_state: str | None = None,
    include: list[str] | None = None,
    per_page: int | None = None,
) -> list[dict[str, Any]]:
    """
    List courses for the current user (Canvas).
    Query params are forwarded to Canvas; e.g. enrollment_state=active.
    """
    try:
        return await canvas_service.list_courses(
            enrollment_state=enrollment_state,
            include=include,
            per_page=per_page,
        )
    except CanvasAPIError as e:
        raise HTTPException(status_code=e.status_code, detail=e.body or str(e))
