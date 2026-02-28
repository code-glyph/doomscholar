# Shim so "uvicorn main:app" works on hosts that default to main (e.g. Railway, Render).
# The real app is in app.py; we just re-export it here.
from app import app

__all__ = ["app"]
