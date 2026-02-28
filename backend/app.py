"""FastAPI application entry point."""

# Load .env as early as possible (deploy may rely on host env vars instead)
from config import settings  # noqa: F401 — triggers load_dotenv

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from api.routes import router as api_router
from api.routes import courses as courses_routes
from api.routes import files as files_routes
from api.routes import questions as questions_routes
from api.routes import questions_from_file as questions_from_file_routes

app = FastAPI(
    title="DoomScholar API",
    description="Backend for doomscrolling control app; Canvas integration.",
)

# CORS — open for local hackathon dev; lock down before deployment
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router)
# Also serve at /courses and /courses/... so clients without /api/v1 prefix work
app.include_router(courses_routes.router, prefix="/courses", tags=["Courses"])
app.include_router(
    files_routes.router,
    prefix="/courses/{course_id}/files",
    tags=["Files"],
)
app.include_router(questions_routes.router, prefix="/questions", tags=["Questions"])
app.include_router(questions_from_file_routes.router, prefix="/questions", tags=["Questions"])


@app.get("/", tags=["Meta"])
async def root():
    """List main API entry points."""
    return {
        "message": "DoomScholar API",
        "docs": "/docs",
        "health": "/health",
        "api_v1": {
            "courses": "GET /api/v1/courses",
            "course_files": "GET /api/v1/courses/{course_id}/files",
            "course_files_via_modules": "GET /api/v1/courses/{course_id}/files/via_modules",
            "get_question": "GET /api/v1/questions or GET /questions",
        },
    }


@app.get("/health", tags=["Meta"])
async def health():
    from config import settings
    token_set = bool(settings.canvas_access_token and settings.canvas_access_token.strip())
    return {
        "status": "ok",
        "canvas_configured": token_set,
        "hint": "If /courses fails, set CANVAS_ACCESS_TOKEN (and CANVAS_BASE_URL) in your host's environment variables.",
    }
