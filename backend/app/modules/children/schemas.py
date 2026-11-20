
from datetime import date

from pydantic import BaseModel, Field


class ChildCreateRequest(BaseModel):
    child_name: str = Field(min_length=1, max_length=100)
    date_of_birth: date
    gender: str | None = None


class ChildUpdateRequest(BaseModel):
    child_name: str | None = Field(default=None, min_length=1, max_length=100)
    date_of_birth: date | None = None
    gender: str | None = None
