
from datetime import date

from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials

from app.modules.assessment.age_calculator import calculate_child_age
from app.modules.assessment.schemas import AssessmentSubmission
from app.modules.assessment.service import (
    get_child_questionnaire,
    calculate_child_assessment,
    save_assessment_history,
    get_assessment_history,
)
from app.modules.auth.dependencies import get_current_parent, security


router = APIRouter(
    prefix="/assessment",
    tags=["Assessment"]
)


@router.post("/calculate-age")
async def calculate_age(date_of_birth: date):
    try:
        result = calculate_child_age(date_of_birth)

        return {
            "success": True,
            "message": "Child age calculated successfully.",
            "data": result
        }

    except ValueError as error:
        raise HTTPException(
            status_code=422,
            detail=str(error)
        )


@router.get("/questionnaire/{child_id}")
async def get_questionnaire(
    child_id: str,
    credentials: HTTPAuthorizationCredentials = Depends(security),
    parent=Depends(get_current_parent),
):
    try:
        result = get_child_questionnaire(
            access_token=credentials.credentials,
            child_id=child_id,
        )

        return {
            "success": True,
            "message": "Questionnaire retrieved successfully.",
            "data": result,
        }

    except ValueError as error:
        raise HTTPException(
            status_code=422,
            detail=str(error)
        )

    except Exception:
        raise HTTPException(
            status_code=500,
            detail="Unable to retrieve questionnaire."
        )



@router.post("/submit")
async def submit_assessment(
    request: AssessmentSubmission,
    credentials: HTTPAuthorizationCredentials = Depends(security),
    parent=Depends(get_current_parent),
):
    try:
        result = calculate_child_assessment(
            access_token=credentials.credentials,
            child_id=request.child_id,
            answers=request.answers,
        )

        # Save assessment result in Supabase history
        save_assessment_history(
            access_token=credentials.credentials,
            parent_id=str(parent.id),
            child_id=request.child_id,
            answers=request.answers,
            result=result,
        )

        return {
            "success": True,
            "message": "Assessment calculated and saved successfully.",
            "data": result,
        }

    except ValueError as error:
        raise HTTPException(
            status_code=422,
            detail=str(error)
        )

    except Exception as error:
        print("Assessment submission error:", str(error))
        raise HTTPException(
            status_code=500,
            detail="Unable to calculate and save assessment."
        )

@router.get("/history/{child_id}")
async def assessment_history(
    child_id: str,
    credentials: HTTPAuthorizationCredentials = Depends(security),
    parent=Depends(get_current_parent),
):
    try:
        history = get_assessment_history(
            access_token=credentials.credentials,
            child_id=child_id,
        )

        return {
            "success": True,
            "message": "Assessment history retrieved successfully.",
            "data": history,
        }

    except ValueError as error:
        raise HTTPException(
            status_code=422,
            detail=str(error)
        )

    except Exception as error:
        print("Assessment history error:", str(error))
        raise HTTPException(
            status_code=500,
            detail="Unable to retrieve assessment history."
        )
