"""Ingestion pipeline: Canvas files → parse → chunk → embed → Qdrant."""

from services.canvas import canvas_service, CanvasAPIError
from services.parser import is_supported, parse_file
from services.chunker import chunk_sections
from services.cohere_client import embed_texts
from services import qdrant_client

# In-memory status store (fine for a single-process hackathon server)
_status_store: dict[int, dict] = {}


def get_status(course_id: int) -> dict:
    return _status_store.get(course_id, {"status": "not_started"})


async def ingest_course(course_id: int) -> None:
    """
    Full ingestion pipeline for one course.
    Designed to run as a FastAPI BackgroundTask.
    """
    _status_store[course_id] = {
        "status": "running",
        "files_total": 0,
        "files_processed": 0,
        "files_skipped": 0,
        "chunks_indexed": 0,
        "error": None,
    }

    try:
        await qdrant_client.ensure_collection()

        # 1. Fetch full file list from Canvas
        raw_files = await canvas_service.list_course_files(course_id)

        # 2. Filter to supported types only (PPTX, DOCX, TXT)
        supported_files = [f for f in raw_files if is_supported(f)]
        skipped = len(raw_files) - len(supported_files)

        _status_store[course_id]["files_total"] = len(supported_files)
        _status_store[course_id]["files_skipped"] = skipped

        for file_obj in supported_files:
            file_id = file_obj["id"]
            filename = file_obj.get("display_name", file_obj.get("filename", ""))

            # 3. Download file into memory stream (no disk writes)
            buffer = await canvas_service.download_file(file_obj)

            # 4. Parse into sections
            sections = parse_file(buffer, file_obj)
            if not sections:
                _status_store[course_id]["files_processed"] += 1
                continue

            # 5. Chunk sections
            chunks = chunk_sections(sections)
            if not chunks:
                _status_store[course_id]["files_processed"] += 1
                continue

            # 6. Embed all chunks via Cohere
            texts = [c["chunk_text"] for c in chunks]
            vectors = await embed_texts(texts)

            # 7. Build Qdrant point payloads and upsert
            points = [
                {
                    "vector": vectors[i],
                    "course_id": course_id,
                    "file_id": file_id,
                    "filename": filename,
                    "chunk_index": chunks[i]["chunk_index"],
                    "chunk_text": chunks[i]["chunk_text"],
                    "source_location": chunks[i]["source_location"],
                }
                for i in range(len(chunks))
            ]
            await qdrant_client.upsert_chunks(points)

            _status_store[course_id]["chunks_indexed"] += len(chunks)
            _status_store[course_id]["files_processed"] += 1

        _status_store[course_id]["status"] = "complete"

    except CanvasAPIError as e:
        _status_store[course_id]["status"] = "failed"
        _status_store[course_id]["error"] = f"Canvas error {e.status_code}: {e.body}"
    except Exception as e:
        _status_store[course_id]["status"] = "failed"
        _status_store[course_id]["error"] = str(e)
