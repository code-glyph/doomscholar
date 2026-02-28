# DoomScholar Backend

FastAPI server for Canvas integration. For the demo, it uses a single configured access token to proxy Canvas API requests.

## Layout

- **`app.py`** – FastAPI app; mounts routers (no `main` module).
- **`config/`** – Settings from env (Canvas token, base URL).
- **`services/canvas.py`** – Canvas API client; used by routes.
- **`api/routes/`** – Route modules (e.g. `courses.py` → `GET /courses`). Add new routers here and register in `api/routes/__init__.py`.

## Setup

```bash
cd backend
python -m venv .venv
source .venv/bin/activate   # or `.venv\Scripts\activate` on Windows
pip install -r requirements.txt
```

## Configuration

Settings are read from the environment. For local testing, use a `.env` file (see below).

- **`CANVAS_ACCESS_TOKEN`** – Canvas API access token. Create one at [PSU Canvas → Profile → Settings → + New Access Token](https://psu.instructure.com/profile/settings).
- **`CANVAS_BASE_URL`** – Canvas instance base URL. Default: `https://psu.instructure.com`.

**Testing with a .env file**

```bash
cd backend
cp .env.example .env
# Edit .env and set CANVAS_ACCESS_TOKEN to your token
```

The app loads `.env` automatically; `.env` is gitignored.

## Run

**Option A – from `backend/` (recommended)**

```bash
cd backend
source .venv/bin/activate
uvicorn app:app --reload --host 0.0.0.0 --port 8000
```

Or use the script (activates venv if present, then starts uvicorn):

```bash
./backend/run.sh
```

**Option B – from repo root**

```bash
uvicorn app:app --reload --app-dir backend --host 0.0.0.0 --port 8000
```

Use the **same Python** that has `pip install -r requirements.txt` (e.g. your `backend/.venv`). If you get `ModuleNotFoundError: No module named 'fastapi'`, activate the venv or use `backend/.venv/bin/uvicorn` with `--app-dir backend`.

API: http://127.0.0.1:8000  
Docs: http://127.0.0.1:8000/docs

## Endpoints (Postman)

Base URL: `http://127.0.0.1:8000`. **API routes are under `/api/v1`.**

1. **`GET /health`** – Check that the app is up and Canvas is configured.
2. **`GET /api/v1/courses`** – List courses for the configured Canvas user. Optional query params (passed to Canvas):
   - `enrollment_state`: `active` | `invited_or_pending` | `completed`
   - `include`: list of includes (e.g. `syllabus_body`, `term`)
   - `per_page`: number of courses per page (Canvas default is 10)
3. **`GET /api/v1/courses/{course_id}/files`** – List all course files (often 403 for student tokens).
4. **`GET /api/v1/courses/{course_id}/files/via_modules`** – List files from modules (works with student tokens).

- **404** – Use `/api/v1/...` paths, not `/courses` alone.
- **401 on courses** – Token invalid or expired. Create a new token at PSU Canvas → Profile → Settings → + New Access Token and update `.env`.
- OpenAPI: `GET /openapi.json` (for Postman import).
