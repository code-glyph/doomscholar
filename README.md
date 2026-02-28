# DoomScholar

**DoomScholar** is a hybrid full‑stack academic assistant that combines
a SwiftUI iOS application with a Python AI backend to ingest course
materials, integrate with Canvas LMS, and generate intelligent quiz
questions using vector search and LLM-powered pipelines.

------------------------------------------------------------------------

## 🚀 Overview

DoomScholar is designed to streamline studying by pairing:

-   📱 A modern iOS app built with SwiftUI\
-   🧠 A Python backend for AI-powered ingestion and question
    generation\
-   📚 Canvas LMS integration\
-   🔎 Vector search using Qdrant\
-   ✨ LLM integration (Cohere)

The system ingests course content, parses and chunks documents, embeds
them into a vector database, and generates quiz questions for
interactive learning.

------------------------------------------------------------------------

## 📱 iOS App

Located in:

    DoomScholar/

### Features

-   Canvas authentication
-   Course dashboard
-   Embedded browser for LMS content
-   Quiz question display
-   Clean SwiftUI-based interface

### Requirements

-   Xcode (latest stable)
-   iOS 16+
-   Swift 5+

### Run the App

1.  Open `DoomScholar.xcodeproj` in Xcode.
2.  Configure API base URL if needed.
3.  Build and run on simulator or device.

------------------------------------------------------------------------

## 🧠 Backend (Python)

Located in:

    backend/

### Architecture

-   FastAPI-style API routes
-   Modular services layer
-   Canvas integration service
-   Text parsing & chunking pipeline
-   Cohere embeddings + LLM generation
-   Qdrant vector storage

### Key Directories

    backend/
    ├── api/routes/       # API endpoints
    ├── services/         # Business logic modules
    ├── config/           # App configuration
    ├── main.py           # Entry point
    ├── requirements.txt  # Dependencies
    ├── Dockerfile        # Container config

------------------------------------------------------------------------

## 🛠 Local Backend Setup

### 1. Create Virtual Environment

``` bash
python -m venv venv
source venv/bin/activate
```

### 2. Install Dependencies

``` bash
pip install -r requirements.txt
```

### 3. Configure Environment Variables

``` bash
cp .env.example .env
```

Fill in:

-   COHERE_API_KEY
-   QDRANT_URL
-   Canvas credentials
-   Any other required secrets

### 4. Run Server

``` bash
bash run.sh
```

or

``` bash
python main.py
```

API docs available at:

    http://localhost:8000/docs

------------------------------------------------------------------------

## 🐳 Docker Deployment

Inside `backend/`:

``` bash
docker build -t doomscholar-backend .
docker run -p 8000:8000 doomscholar-backend
```

------------------------------------------------------------------------

## 🔌 Core Capabilities

-   Canvas course syncing
-   Document ingestion
-   Intelligent text chunking
-   Embedding generation
-   Vector search retrieval
-   AI-generated quiz questions

------------------------------------------------------------------------

## 🧩 Tech Stack

**Frontend** - SwiftUI

**Backend** - Python - FastAPI-style routing - Cohere - Qdrant

------------------------------------------------------------------------

## 🧪 Future Improvements

-   Automated testing suite
-   CI/CD pipeline
-   Expanded documentation
-   Architecture diagram
-   UI screenshots
-   Production deployment guide

------------------------------------------------------------------------

## 📜 License

No license detected. Add a LICENSE file if open-sourcing.

------------------------------------------------------------------------

Built as a full-stack AI-powered academic assistant.
