"""FastAPI application entry point."""

from fastapi import FastAPI

from api.routes import router as api_router

app = FastAPI(
    title="DoomScholar API",
    description="Backend for doomscrolling control app; Canvas integration.",
)
app.include_router(api_router)
