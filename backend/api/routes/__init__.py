from fastapi import APIRouter

from api.routes import courses

router = APIRouter()
router.include_router(courses.router, prefix="/courses", tags=["courses"])
