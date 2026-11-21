
from datetime import date
from typing import Any

from app.modules.children.service import get_parent_supabase_client
from app.modules.assessment.age_calculator import calculate_child_age
from app.modules.assessment.scoring import calculate_assessment_score


def get_child_for_assessment(
    access_token: str,
    child_id: str,
) -> dict[str, Any]:

    client = get_parent_supabase_client(access_token)

    response = (
        client.table("children")
        .select("id, date_of_birth")
        .eq("id", child_id)
        .limit(1)
        .execute()
    )

    if not response.data:
        raise ValueError(
            "Child not found or you do not have permission to access this child."
        )

    return response.data[0]


def get_child_questionnaire(
    access_token: str,
    child_id: str,
) -> dict[str, Any]:

    client = get_parent_supabase_client(access_token)

    child = get_child_for_assessment(access_token, child_id)

    dob = date.fromisoformat(child["date_of_birth"])
    age_data = calculate_child_age(dob)

    total_months = age_data["total_months"]

    questions_response = (
        client.table("assessment_questions")
        .select("*")
        .eq("is_active", True)
        .lte("min_age_months", total_months)
        .gte("max_age_months", total_months)
        .order("sort_order")
        .execute()
    )

    questions = questions_response.data

    if len(questions) != 12:
        raise ValueError(
            "The questionnaire for this age group is incomplete."
        )

    options_response = (
        client.table("assessment_answer_options")
        .select("*")
        .eq("is_active", True)
        .execute()
    )

    return {
        "child_id": child["id"],
        "age": age_data,
        "questions": questions,
        "answer_options": options_response.data,
    }


def save_assessment_history(
    access_token: str,
    parent_id: str,
    child_id: str,
    answers: dict[str, str],
    result: dict[str, Any],
) -> dict[str, Any]:

    client = get_parent_supabase_client(access_token)

    age = result["age"]

    history_data = {
        "child_id": child_id,
        "parent_id": parent_id,
        "age_years": age["age_years"],
        "age_months": age["age_months"],
        "total_months": age["total_months"],
        "age_group": age["age_group"],
        "answers": answers,
        "concern_level": result["concern_level"],
        "concern_percentage": result["concern_percentage"],
        "total_score": result["total_score"],
        "maximum_score": result["maximum_score"],
        "counted_answers": result["counted_answers"],
        "not_sure_answers": result["not_sure_answers"],
        "domains": result["domains"],
        "parent_concerns": result["parent_concerns"],
        "disclaimer": result["disclaimer"],
    }

    response = (
        client.table("assessment_history")
        .insert(history_data)
        .execute()
    )

    if not response.data:
        raise ValueError("Assessment history could not be saved.")

    return response.data[0]


def get_assessment_history(
    access_token: str,
    child_id: str,
) -> list[dict[str, Any]]:

    client = get_parent_supabase_client(access_token)

    get_child_for_assessment(access_token, child_id)

    response = (
        client.table("assessment_history")
        .select("*")
        .eq("child_id", child_id)
        .order("created_at", desc=True)
        .execute()
    )

    return response.data


def calculate_child_assessment(
    access_token: str,
    child_id: str,
    answers: dict[str, str],
) -> dict[str, Any]:

    client = get_parent_supabase_client(access_token)

    questionnaire = get_child_questionnaire(
        access_token,
        child_id,
    )

    questions = questionnaire["questions"]

    developmental_ids = [
        question["id"]
        for question in questions
        if question["question_type"] == "developmental"
    ]

    if not developmental_ids:
        raise ValueError("No developmental questions were found.")

    rules_response = (
        client.table("assessment_question_scoring")
        .select("*")
        .in_("question_id", developmental_ids)
        .execute()
    )

    result = calculate_assessment_score(
        questions=questions,
        scoring_rules=rules_response.data,
        answer_options=questionnaire["answer_options"],
        answers=answers,
    )

    result["child_id"] = child_id
    result["age"] = questionnaire["age"]

    return result
