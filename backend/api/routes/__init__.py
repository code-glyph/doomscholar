from fastapi import APIRouter

from api.routes import courses, health, files

router = APIRouter()
router.include_router(health.router, tags=["health"])
router.include_router(courses.router, prefix="/courses", tags=["courses"])
router.include_router(files.router, prefix="/courses/{course_id}/files", tags=["Files"])
