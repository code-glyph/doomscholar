"""FastAPI application entry point."""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from api.routes import router as api_router

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


@app.get("/health", tags=["Meta"])
async def health():
    return {"status": "ok"}
