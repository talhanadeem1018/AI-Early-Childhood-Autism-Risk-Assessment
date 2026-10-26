from datetime import date
from typing import List, Optional

from fastapi import APIRouter, HTTPException, Query

from app import config
from app.modules.assessment import questions as qb
from app.modules.assessment.schemas import (
    AgeBandOut,
    AssessmentResult,
    QuestionnaireOut,
    QuestionOut,
    ScoreRequest,
)
from app.modules.assessment.scoring import ScoringError, band_out, resolve_age, score_assessment

router = APIRouter(prefix="/assessment", tags=["Module 1 - Assessment"])


@router.get("/age-bands", response_model=List[AgeBandOut])
def list_age_bands():
    """All supported age bands (used by the app to explain which questionnaire applies)."""
    return [band_out(b) for b in qb.AGE_BANDS]


@router.get("/questionnaire", response_model=QuestionnaireOut)
def get_questionnaire(
    age_months: Optional[int] = Query(default=None, ge=0, le=71, description="Child's age in months"),
    date_of_birth: Optional[date] = Query(default=None, description="Child's date of birth (YYYY-MM-DD)"),
):
    """Return the age-appropriate questionnaire. Provide age_months OR date_of_birth."""
    if age_months is None and date_of_birth is None:
        raise HTTPException(status_code=422, detail="Provide either age_months or date_of_birth.")
    try:
        age = resolve_age(age_months, date_of_birth)
    except ScoringError as e:
        raise HTTPException(status_code=422, detail=str(e))

    band = qb.get_band_for_age(age)
    items = qb.get_questions_for_band(band.id)
    return QuestionnaireOut(
        age_months=age,
        age_band=band_out(band),
        answer_choices=qb.ANSWER_CHOICES,
        total_questions=len(items),
        questions=[
            QuestionOut(
                id=q.id,
                domain=q.domain,
                domain_label=qb.DOMAIN_LABELS[q.domain],
                text=q.text,
                clarify_tip=q.clarify,
            )
            for q in items
        ],
        disclaimer=config.DISCLAIMER,
    )


@router.post("/score", response_model=AssessmentResult)
def score(payload: ScoreRequest):
    """Score submitted answers and return concern level, guidance and consultation advice.

    Stateless for now: nothing is stored yet (saving to Supabase comes in the next step).
    """
    try:
        return score_assessment(payload.age_months, payload.date_of_birth, payload.answers)
    except ScoringError as e:
        raise HTTPException(status_code=422, detail=str(e))
