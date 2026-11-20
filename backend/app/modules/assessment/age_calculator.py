
from datetime import date
import calendar


def add_months(original_date: date, months: int) -> date:
    """Add or subtract calendar months while handling month-end dates."""

    month_index = original_date.month - 1 + months

    year = original_date.year + month_index // 12
    month = month_index % 12 + 1

    day = min(
        original_date.day,
        calendar.monthrange(year, month)[1]
    )

    return date(year, month, day)


def calculate_child_age(
    date_of_birth: date,
    today: date | None = None
) -> dict:
    """Calculate exact child age and automatically assign an age group."""

    if today is None:
        today = date.today()

    if date_of_birth > today:
        raise ValueError("Date of birth cannot be in the future.")

    minimum_date = add_months(today, -60)

    if date_of_birth < minimum_date:
        raise ValueError("Child age must not exceed 60 months.")

    total_months = (
        (today.year - date_of_birth.year) * 12
        + today.month - date_of_birth.month
    )

    anniversary_date = add_months(date_of_birth, total_months)

    if anniversary_date > today:
        total_months -= 1
        anniversary_date = add_months(date_of_birth, total_months)

    age_years = total_months // 12
    remaining_months = total_months % 12

    if total_months <= 5:
        age_group = "0-5 months"
    elif total_months <= 11:
        age_group = "6-11 months"
    elif total_months <= 23:
        age_group = "12-23 months"
    elif total_months <= 35:
        age_group = "24-35 months"
    else:
        age_group = "36-60 months"

    return {
        "date_of_birth": date_of_birth.isoformat(),
        "age_years": age_years,
        "age_months": remaining_months,
        "total_months": total_months,
        "age_group": age_group
    }
