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


class ModuleFileRef(BaseModel):
    """A file exposed to the student via a course module (student-accessible)."""
    file_id: int
    module_item_id: int
    title: str
    module_id: int
    module_name: str
    position: Optional[int] = None
    html_url: str = ""
    url: str = ""


class CourseFilesViaModulesResponse(BaseModel):
    course_id: int
    total_files: int
    files: list[ModuleFileRef]
    note: str = "Files listed from course modules; works with student tokens."


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


@router.get(
    "/via_modules",
    response_model=CourseFilesViaModulesResponse,
    summary="List course files via modules (student-accessible)",
    description=(
        "Returns files that appear in the course's modules. Uses the Modules API "
        "instead of the direct course files endpoint, so it works with student tokens "
        "when GET /courses/:id/files returns 403."
    ),
)
async def list_course_files_via_modules(
    course_id: int,
) -> CourseFilesViaModulesResponse:
    try:
        raw = await canvas_service.list_course_files_via_modules(course_id)
    except CanvasAPIError as e:
        raise HTTPException(status_code=e.status_code, detail=e.body or str(e))
    refs = [
        ModuleFileRef(
            file_id=r["file_id"],
            module_item_id=r["module_item_id"],
            title=r["title"],
            module_id=r["module_id"],
            module_name=r["module_name"],
            position=r.get("position"),
            html_url=r.get("html_url", ""),
            url=r.get("url", ""),
        )
        for r in raw
    ]
    return CourseFilesViaModulesResponse(
        course_id=course_id,
        total_files=len(refs),
        files=refs,
    )
