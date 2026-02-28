DoomScholar
DoomScholar is a hybrid full-stack academic assistant that combines a SwiftUI iOS app with a Python AI backend to ingest course materials, connect with Canvas LMS, and generate interactive quiz questions using vector search and LLM-based pipelines.
📚 Project Overview
DoomScholar’s goal is to streamline learning workflows by providing a mobile interface for students paired with an intelligent backend that:
Connects securely with Canvas LMS
Ingests course files and web content
Parses and chunks text for embedding
Stores vectors in Qdrant
Uses an LLM (e.g., Cohere) to generate quiz questions and summaries
This hybrid approach brings together iOS usability and backend AI workflows to help users review and engage with course materials efficiently.
📱 App – iOS (SwiftUI)
Features
Canvas single sign-on & authentication
Dashboard of courses and materials
Embedded web browser (Canvas content)
Display and interaction with generated quiz questions
Uses SwiftUI for modern, declarative UIs
Requirements
Xcode latest stable version
iOS 16.0+
Swift 5+
Running
Open DoomScholar.xcodeproj in Xcode.
Configure any necessary API base URLs.
Run on a simulator or physical device.
🧠 Backend – Python AI Service
Architecture
The backend is structured with:
FastAPI-style routes
Canvas LMS integration
File ingestion and parsing
Chunking & embedding via Cohere
Vector storage in Qdrant
Key folders
backend/
├─ api/routes/         # FastAPI endpoints
├─ services/           # Logic modules (Canvas, ingestion, parser, Qdrant)
├─ core/               # Configuration & environment
├─ tests/              # Test suite
├─ run.sh              # Launch script
├─ requirements.txt    # Python dependencies
Running Locally
# Create venv
python -m venv venv
source venv/bin/activate

# Install deps
pip install -r requirements.txt

# Create .env based on .env.example
cp .env.example .env
# Fill in keys: COHERE_API_KEY, QDRANT_URL, CANVAS creds

# Start service
bash run.sh
🐳 Docker Deployment
You can containerize the backend:
docker build -t doomscholar-backend .
docker run -p 8000:8000 doomscholar-backend
🔌 APIs & Integration
The backend exposes endpoints for:
Authentication & health checks
File uploads and ingestion
Canvas course sync
Quiz question generation
Vector search & retrieval
Documentation (OpenAPI) is available at /docs when backend is running.
🧩 Dependencies
FastAPI – backend web framework
Cohere – LLM & embedder
Qdrant – vector database
SwiftUI – iOS app UI
🚀 Contribution
Contributions are welcome!
Report bugs or issues
Suggest features
Improve docs and tests
