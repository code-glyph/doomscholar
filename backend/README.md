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

- **`CANVAS_ACCESS_TOKEN`** – Canvas API access token (user token from Profile → Settings → New Access Token, or from your OAuth flow). Default: placeholder; set this for real data.
- **`CANVAS_BASE_URL`** – Canvas instance base URL (e.g. `https://canvas.instructure.com` or your school’s `https://yourschool.instructure.com`). Default: `https://canvas.instructure.com`.

## Run

```bash
uvicorn app:app --reload
```

API: http://127.0.0.1:8000  
Docs: http://127.0.0.1:8000/docs

## Endpoints (Postman)

Base URL: `http://127.0.0.1:8000`

- **`GET /courses`** – List courses for the configured Canvas user. Optional query params (passed to Canvas):
  - `enrollment_state`: `active` | `invited_or_pending` | `completed`
  - `include`: list of includes (e.g. `syllabus_body`, `term`)
  - `per_page`: number of courses per page (Canvas default is 10)

OpenAPI schema: `GET /openapi.json` (for Postman import).
