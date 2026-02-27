"""Ingestion trigger and status endpoints."""

from fastapi import APIRouter, BackgroundTasks, HTTPException
from pydantic import BaseModel
from services.ingestion import ingest_course, get_status

router = APIRouter()


class IngestStartedResponse(BaseModel):
    course_id: int
    message: str


@router.post(
    "",
    response_model=IngestStartedResponse,
    status_code=202,
    summary="Trigger background ingestion for a course",
    description=(
        "Starts downloading, parsing, chunking, embedding, and indexing "
        "all supported files (PPTX, DOCX, TXT) for the given course. "
        "Runs in the background. Poll the /status endpoint to check progress."
    ),
)
async def start_ingestion(
    course_id: int,
    background_tasks: BackgroundTasks,
) -> IngestStartedResponse:
    status = get_status(course_id)
    if status.get("status") == "running":
        raise HTTPException(
            status_code=409,
            detail=f"Ingestion is already running for course {course_id}.",
        )

    background_tasks.add_task(ingest_course, course_id)

    return IngestStartedResponse(
        course_id=course_id,
        message="Ingestion started. Poll /status to check progress.",
    )


@router.get(
    "/status",
    summary="Get ingestion status for a course",
    description="Returns current status, file counts, and chunk count for a course ingestion.",
)
async def ingestion_status(course_id: int) -> dict:
    return get_status(course_id)
