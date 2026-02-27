#!/usr/bin/env sh
# Run the API from the backend directory so imports (config, api, services) resolve.
# Use the venv if it exists.
set -e
cd "$(dirname "$0")"
if [ -d ".venv" ]; then
  . .venv/bin/activate
fi
exec uvicorn app:app --reload --host 0.0.0.0 --port 8000
