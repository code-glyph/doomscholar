"""API route registry."""

from fastapi import APIRouter
from api.routes import courses, files, ingest, questions

router = APIRouter(prefix="/api/v1")

router.include_router(courses.router, prefix="/courses", tags=["Courses"])
router.include_router(files.router, prefix="/courses/{course_id}/files", tags=["Files"])
router.include_router(ingest.router, prefix="/courses/{course_id}/ingest", tags=["Ingestion"])
router.include_router(questions.router, prefix="/questions", tags=["Questions"])

