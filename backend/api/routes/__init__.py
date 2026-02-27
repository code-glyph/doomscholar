from fastapi import APIRouter

from api.routes import courses, health

router = APIRouter()
router.include_router(health.router, tags=["health"])
router.include_router(courses.router, prefix="/courses", tags=["courses"])
