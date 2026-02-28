# Deploying the DoomScholar Backend

The backend is a FastAPI app. You can deploy it with **Docker** or as a **Python service**. Set all required environment variables on your host (no `.env` file in production).

---

## ⚠️ "Could not import module main" — fix

The app lives in **`app.py`**, not `main.py`. If your host tries to run `uvicorn main:app`, set the **Start Command** to:

```bash
uvicorn app:app --host 0.0.0.0 --port $PORT
```

- **Railway:** Service → **Settings** → **Deploy** → **Custom Start Command** → paste the line above.
- **Render:** Service → **Settings** → **Build & Deploy** → **Start Command** → paste the line above.

Then redeploy.

## Environment variables (set these on your host)

| Variable | Required | Description |
|----------|----------|-------------|
| `CANVAS_ACCESS_TOKEN` | Yes (for Canvas) | Canvas API token |
| `CANVAS_BASE_URL` | No | Default: `https://psu.instructure.com` |
| `COHERE_API_KEY` | If using Cohere | Cohere API key |
| `QDRANT_URL` | If using Qdrant | Qdrant cluster URL |
| `QDRANT_API_KEY` | If using Qdrant | Qdrant API key |
| `QDRANT_COLLECTION_NAME` | No | Default: `doomscholar` |
| `PORT` | No | Server port (default 8000; Render/Railway set this) |

---

## Option 1: Railway (recommended — simple)

1. **Sign up:** [railway.app](https://railway.app) (GitHub login).
2. **New project → Deploy from GitHub repo** and select your `doomscholar` repo.
3. **Root directory:** Set to `backend` (so Railway uses the `backend/` folder).
4. **Start command (important):** In the service → **Settings** → set **Custom Start Command** to:
   ```bash
   uvicorn app:app --host 0.0.0.0 --port $PORT
   ```
   (The app is in `app.py`, not `main.py`; without this you may see "Could not import module main".)
5. **Build:** Railway will use the Dockerfile in `backend/` or auto-detect Python. Either way, set the start command as above.
6. **Variables:** In the service → **Variables**, add every env var from the table above.
6. **Deploy:** Push to your repo or click Deploy. Railway will assign a URL like `https://your-app.up.railway.app`.

**Use the URL** in your iOS app (e.g. `https://your-app.up.railway.app/courses`, `/questions`, etc.).

---

## Option 2: Render

1. **Sign up:** [render.com](https://render.com) (GitHub login).
2. **New → Web Service**, connect your GitHub repo.
3. **Settings:**
   - **Root Directory:** `backend`
   - **Environment:** Docker (if using the Dockerfile) or Python.
   - **Build:** (Docker) leave default. (Python) Build: `pip install -r requirements.txt`, Start: `uvicorn app:app --host 0.0.0.0 --port $PORT`.
4. **Environment:** Add all variables from the table above in the **Environment** section.
5. **Deploy:** Save; Render builds and deploys. You get a URL like `https://your-service.onrender.com`.

---

## Option 3: Docker (any host)

Build and run locally or on any server with Docker:

```bash
cd backend
docker build -t doomscholar-backend .
docker run -p 8000:8000 \
  -e CANVAS_ACCESS_TOKEN="your-token" \
  -e CANVAS_BASE_URL="https://psu.instructure.com" \
  -e COHERE_API_KEY="optional" \
  -e QDRANT_URL="optional" \
  -e QDRANT_API_KEY="optional" \
  doomscholar-backend
```

On a VPS (DigitalOcean, AWS EC2, etc.), set env vars in a file or use `-e` for each, then put the container behind a reverse proxy (nginx/Caddy) with HTTPS.

---

## Option 4: Run without Docker (VPS or your machine)

```bash
cd backend
python -m venv .venv
source .venv/bin/activate   # or .venv\Scripts\activate on Windows
pip install -r requirements.txt
export CANVAS_ACCESS_TOKEN="..."
export CANVAS_BASE_URL="https://psu.instructure.com"
# ... other env vars
uvicorn app:app --host 0.0.0.0 --port 8000
```

Use a process manager (systemd, supervisord) and a reverse proxy for production.

---

## After deploy

- **Health:** `GET https://your-url/health` → `{"status":"ok"}`.
- **API root:** `GET https://your-url/` → list of endpoints.
- **Docs:** `https://your-url/docs` (Swagger).
- In your iOS app, set the base URL to `https://your-url` (no trailing slash).

## CORS

The app currently allows all origins (`allow_origins=["*"]`). For production, restrict this to your app’s origin(s) in `app.py`:

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://your-app-domain.com"],  # or your iOS app scheme
    ...
)
```
