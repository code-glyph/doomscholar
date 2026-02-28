# DoomScholar backend — production image
FROM python:3.12-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Application code (no .env — use platform env vars)
COPY . .

# Run with 0.0.0.0 so the server is reachable from outside the container.
# Railway/Render set PORT; default 8000 for local runs.
ENV PORT=8000
EXPOSE 8000
CMD sh -c 'uvicorn app:app --host 0.0.0.0 --port ${PORT}'
