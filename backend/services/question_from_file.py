"""
Generate one quiz question from a random active course and a (recent) file in that course.
Uses Canvas (courses + files via modules), file download, parser, and OpenAI to produce
the same format as the static questions (topic, hint, answer, mcq).

Caching: questions are cached in memory by Canvas file_id (TTL 24h). Cache hits skip
download + OpenAI and return in milliseconds. For multi-worker deployments use Redis
or a shared cache keyed by file_id.
"""

import asyncio
import json
import os
import random
import time
from typing import Any

# Limit work to keep latency down: try one course first; fetch this many file metas in parallel
MAX_COURSES_TO_TRY = 1
MAX_FILE_METAS_PARALLEL = 8

# In-memory cache: file_id -> (expiry_ts, question_payload). TTL in seconds.
_QUESTION_CACHE: dict[int | str, tuple[float, dict[str, Any]]] = {}
_CACHE_TTL_SECONDS = 24 * 60 * 60  # 24 hours

from openai import AsyncOpenAI

from services.canvas import canvas_service
from services.canvas import CanvasAPIError
from services.canvas_file_client import get_file_metadata
from services.canvas_file_client import CanvasFileClientError
from services.parser import is_supported
from services.parser import parse_file


def _get_openai_key() -> str:
    """Read at request time so deploy env (Railway/Render/etc.) is always used."""
    return os.environ.get("OPENAI_API_KEY", "").strip()


def _get_openai_model() -> str:
    return os.environ.get("OPENAI_QUESTION_MODEL", "gpt-4o-mini").strip() or "gpt-4o-mini"


def _cache_get(file_id: int | str) -> dict[str, Any] | None:
    entry = _QUESTION_CACHE.get(file_id)
    if not entry:
        return None
    expiry_ts, payload = entry
    if time.time() > expiry_ts:
        del _QUESTION_CACHE[file_id]
        return None
    return payload


def _cache_set(file_id: int | str, payload: dict[str, Any]) -> None:
    _QUESTION_CACHE[file_id] = (time.time() + _CACHE_TTL_SECONDS, payload)


async def _pick_course_and_file() -> tuple[dict[str, Any], dict[str, Any]]:
    """Try up to MAX_COURSES_TO_TRY courses; use parallel file metadata fetches to reduce latency."""
    courses = await canvas_service.list_courses(enrollment_state="active")
    if not courses:
        raise ValueError("No active courses found for the configured Canvas user.")
    random.shuffle(courses)
    to_consider = courses[:MAX_COURSES_TO_TRY]
    for course in to_consider:
        course_id = course.get("id")
        course_name = course.get("name", "Course")
        if not course_id:
            continue
        module_files = await canvas_service.list_course_files_via_modules(course_id)
        if not module_files:
            # Fallback: direct course files (works for teachers; 403 for students)
            try:
                direct_files = await canvas_service.list_course_files(course_id)
            except CanvasAPIError:
                direct_files = []
            if direct_files:
                supported = [f for f in direct_files if is_supported(f)]
                if supported:
                    for f in supported:
                        f["_course_id"] = course_id
                        f["_course_name"] = course_name
                    def _updated_at(m: dict) -> str:
                        return m.get("updated_at") or m.get("created_at") or ""
                    supported.sort(key=_updated_at, reverse=True)
                    return course, supported[0]
            continue
        # Fetch metadata in parallel for first N refs (much faster than sequential)
        random.shuffle(module_files)
        to_try = module_files[:MAX_FILE_METAS_PARALLEL]

        async def _fetch_meta(ref: dict) -> dict[str, Any] | None:
            file_id = ref.get("file_id")
            if not file_id:
                return None
            try:
                meta = await get_file_metadata(file_id)
            except CanvasFileClientError:
                return None
            if not is_supported(meta):
                return None
            meta["_module_title"] = ref.get("title", "")
            meta["_course_id"] = course_id
            meta["_course_name"] = course_name
            return meta

        results = await asyncio.gather(*[_fetch_meta(ref) for ref in to_try])
        file_metas = [m for m in results if m is not None]
        if file_metas:
            def _updated_at(m: dict) -> str:
                return m.get("updated_at") or m.get("created_at") or ""
            file_metas.sort(key=_updated_at, reverse=True)
            return course, file_metas[0]

    raise ValueError(
        "No usable files found in any active course. "
        "Add a PPTX/DOCX/TXT/PDF file to a course module, or use a teacher token."
    )


async def generate_question_from_file() -> dict[str, Any]:
    """
    Pick a random active course, pick a supported file (prefer recent), extract text,
    call OpenAI to generate one question in our standard format. Returns a dict
    with id, topic, hint, answer, mcq (question, options, correct_index).
    """
    api_key = _get_openai_key()
    if not api_key:
        raise ValueError(
            "OPENAI_API_KEY is not set. Set it in the environment to generate questions from course files."
        )
    course, file_meta = await _pick_course_and_file()
    file_id = file_meta.get("id")
    if file_id is not None:
        cached = _cache_get(file_id)
        if cached is not None:
            return cached
    course_id = file_meta["_course_id"]
    course_name = file_meta["_course_name"]
    buffer = await canvas_service.download_file(file_meta)
    sections = parse_file(buffer, file_meta)
    if not sections:
        raise ValueError("File could not be parsed or produced no text.")
    combined_text = "\n\n".join(
        f"[{s.get('source_location', '')}]\n{s.get('text', '')}" for s in sections
    )
    # Cap size for API
    if len(combined_text) > 12000:
        combined_text = combined_text[:12000] + "\n\n[... truncated for length ...]"
    client = AsyncOpenAI(api_key=api_key)
    prompt = f"""You are a graduate-level exam question writer. Below is excerpted course material from the course "{course_name}".

Generate exactly ONE multiple-choice question that can be answered from this material. Output valid JSON only, no markdown or explanation, in this exact shape:
{{
  "topic": "short topic name (e.g. Convolutional Neural Networks)",
  "hint": "one short hint for the student (1 sentence)",
  "answer": "a clear 1-3 sentence explanation of the correct answer",
  "mcq": {{
    "question": "the multiple choice question text",
    "options": ["option A", "option B", "option C", "option D"],
    "correct_index": 0
  }}
}}
correct_index must be 0, 1, 2, or 3 (the index of the correct option in options). Give exactly 4 options.

Course material:
---
{combined_text}
---"""

    response = await client.chat.completions.create(
        model=_get_openai_model(),
        messages=[{"role": "user", "content": prompt}],
        temperature=0.5,
    )
    raw = response.choices[0].message.content
    if not raw:
        raise ValueError("OpenAI returned empty content.")
    raw = raw.strip()
    if raw.startswith("```"):
        raw = raw.split("\n", 1)[-1] if "\n" in raw else raw[3:]
    if raw.endswith("```"):
        raw = raw.rsplit("```", 1)[0].strip()
    data = json.loads(raw)
    topic = data.get("topic", "Course material")
    hint = data.get("hint", "")
    answer = data.get("answer", "")
    mcq = data.get("mcq") or {}
    q = mcq.get("question", "")
    options = list(mcq.get("options") or [])[:4]
    correct_index = int(mcq.get("correct_index", 0))
    if correct_index < 0 or correct_index >= len(options):
        correct_index = 0
    gen_id = f"gen-{course_id}-{file_meta.get('id', '')}-{int(time.time())}"
    result = {
        "id": gen_id,
        "topic": topic,
        "hint": hint,
        "answer": answer,
        "mcq": {
            "question": q,
            "options": options,
            "correct_index": correct_index,
        },
    }
    if file_id is not None:
        _cache_set(file_id, result)
    return result
