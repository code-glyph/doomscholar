"""Course files endpoint (Canvas-backed)."""

from typing import Optional
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from services.canvas import canvas_service, CanvasAPIError

router = APIRouter()


# ── Response schemas ──────────────────────────────────────────────────────────

class CanvasFile(BaseModel):
    id: int
    display_name: str
    filename: str
    content_type: str
    size_kb: float
    url: str
    updated_at: Optional[str] = None


class CourseFilesResponse(BaseModel):
    course_id: int
    total_files: int
    files: list[CanvasFile]


# ── Endpoint ──────────────────────────────────────────────────────────────────

@router.get(
    "",
    response_model=CourseFilesResponse,
    summary="List all files in a Canvas course",
    description=(
        "Returns all files the authenticated student can access "
        "for the given course ID. Follows Canvas pagination automatically."
    ),
)
async def list_course_files(course_id: int) -> CourseFilesResponse:
    try:
        raw_files = await canvas_service.list_course_files(course_id)
    except CanvasAPIError as e:
        raise HTTPException(status_code=e.status_code, detail=e.body or str(e))

    files = [
        CanvasFile(
            id=f["id"],
            display_name=f.get("display_name", f.get("filename", "")),
            filename=f.get("filename", ""),
            content_type=f.get("content-type", "application/octet-stream"),
            size_kb=round(f.get("size", 0) / 1024, 2),
            url=f.get("url", ""),
            updated_at=f.get("updated_at"),
        )
        for f in raw_files
    ]

    return CourseFilesResponse(
        course_id=course_id,
        total_files=len(files),
        files=files,
    )
