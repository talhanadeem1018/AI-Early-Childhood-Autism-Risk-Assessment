
from datetime import date

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.modules.assessment.age_calculator import calculate_child_age


router = APIRouter(
    prefix="/assessment",
    tags=["Assessment"]
)


class AgeCalculationRequest(BaseModel):
    date_of_birth: date


@router.post("/calculate-age")
async def calculate_age(request: AgeCalculationRequest):
    try:
        result = calculate_child_age(request.date_of_birth)
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
