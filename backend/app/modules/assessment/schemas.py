
from datetime import date
from typing import Literal
from pydantic import BaseModel, Field


AnswerValue = Literal[
    "usually",
    "sometimes",
    "rarely",
    "not_sure"
]


class AssessmentSubmission(BaseModel):
    child_id: str
    answers: dict[str, AnswerValue] = Field(
        ...,
        description="Question ID mapped to the parent's selected answer."
    )


class AssessmentResult(BaseModel):
    status: str
    concern_level: str
    concern_percentage: float
    total_score: int
    maximum_score: int
    counted_answers: int
    not_sure_answers: int
    domains: dict
    parent_concerns: list[dict]
    disclaimer: str
