from datetime import date
from enum import Enum
from typing import Dict, List, Optional

from pydantic import BaseModel, Field, model_validator


class AnswerValue(str, Enum):
    usually = "usually"
    sometimes = "sometimes"
    rarely = "rarely"
    not_sure = "not_sure"


class ConcernLevel(str, Enum):
    low = "low"
    moderate = "moderate"
    high = "high"
    insufficient_data = "insufficient_data"


# ------------------------------------------------------------- questionnaire
class QuestionOut(BaseModel):
    id: str
    domain: str
    domain_label: str
    text: str
    clarify_tip: str


class AgeBandOut(BaseModel):
    id: str
    label: str
    min_months: int
    max_months: int


class QuestionnaireOut(BaseModel):
    age_months: int
    age_band: AgeBandOut
    answer_choices: List[str]
    total_questions: int
    questions: List[QuestionOut]
    disclaimer: str


# --------------------------------------------------------------- submission
class AnswerIn(BaseModel):
    question_id: str
    answer: AnswerValue


class ScoreRequest(BaseModel):
    age_months: Optional[int] = Field(default=None, ge=0, le=71)
    date_of_birth: Optional[date] = None
    answers: List[AnswerIn] = Field(min_length=1)

    @model_validator(mode="after")
    def need_age_or_dob(self):
        if self.age_months is None and self.date_of_birth is None:
            raise ValueError("Provide either age_months or date_of_birth.")
        return self


# ------------------------------------------------------------------- result
class DomainResult(BaseModel):
    domain: str
    label: str
    answered: int
    not_sure: int
    points: int
    max_points: int
    percentage: float
    level: ConcernLevel


class FollowUp(BaseModel):
    question_id: str
    question_text: str
    tip: str


class GuidanceItem(BaseModel):
    domain: str
    title: str
    tips: List[str]


class Consultation(BaseModel):
    recommended: bool
    urgency: str  # "routine" | "soon" | "prompt"
    message: str


class AssessmentResult(BaseModel):
    age_months: int
    age_band: AgeBandOut
    status: str  # "complete" | "insufficient_data"
    concern_level: ConcernLevel
    overall_percentage: float
    confidence: str  # "normal" | "low"
    total_questions: int
    answered: int
    not_sure: int
    domains: List[DomainResult]
    red_flags: List[str]
    escalation_reasons: List[str]
    follow_up_questions: List[FollowUp]
    guidance: List[GuidanceItem]
    consultation: Consultation
    summary: str
    disclaimer: str
