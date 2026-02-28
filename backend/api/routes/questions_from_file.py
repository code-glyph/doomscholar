"""
Question-from-file endpoint: pick a random active course, a (recent) file from it,
and generate one question via OpenAI from the file content. Same response shape as /questions.
"""

from fastapi import APIRouter, HTTPException

from api.routes.questions import MCQQuestion, QuestionResponse
from services.question_from_file import generate_question_from_file

router = APIRouter()


@router.get(
    "/from-file",
    response_model=QuestionResponse,
    summary="Get a question generated from a course file",
    description=(
        "Picks a random active course, a supported file from its modules (preferring recent), "
        "extracts text, and uses OpenAI to generate one question in the same format as GET /questions. "
        "Requires OPENAI_API_KEY and Canvas to be configured."
    ),
)
async def get_question_from_file() -> QuestionResponse:
    try:
        data = await generate_question_from_file()
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    mcq = data.get("mcq")
    return QuestionResponse(
        id=data["id"],
        topic=data["topic"],
        hint=data["hint"],
        answer=data["answer"],
        mcq=MCQQuestion(
            question=mcq["question"],
            options=mcq["options"],
            correct_index=mcq["correct_index"],
        ) if mcq else None,
    )
