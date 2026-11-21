
from typing import Any


DISCLAIMER = (
    "This assessment is for developmental monitoring and early "
    "identification of concerns. It is not a diagnostic tool and "
    "does not determine whether a child has autism."
)


def calculate_assessment_score(
    questions: list[dict[str, Any]],
    scoring_rules: list[dict[str, Any]],
    answer_options: list[dict[str, Any]],
    answers: dict[str, str],
) -> dict[str, Any]:

    question_map = {q["id"]: q for q in questions}
    option_map = {o["id"]: o["option_value"] for o in answer_options}

    rules_map = {
        (rule["question_id"], rule["answer_option_id"]): rule
        for rule in scoring_rules
    }

    # Answers are now received as a dictionary.
    answer_map = answers

    developmental_questions = [
        q for q in questions
        if q["question_type"] == "developmental"
    ]

    parent_questions = [
        q for q in questions
        if q["question_type"] == "parent_concern"
    ]

    expected_ids = set(question_map)
    submitted_ids = set(answer_map)

    if submitted_ids != expected_ids:
        raise ValueError(
            "Please answer every question exactly once."
        )

    total_score = 0
    maximum_score = 0
    counted_answers = 0
    not_sure_answers = 0

    domain_totals = {}

    for question in developmental_questions:
        question_id = question["id"]
        answer_value = answer_map[question_id]

        option_id = next(
            (
                option_id
                for option_id, value in option_map.items()
                if value == answer_value
            ),
            None,
        )

        if option_id is None:
            raise ValueError(
                f"Invalid answer for question {question_id}."
            )

        rule = rules_map.get((question_id, option_id))

        if rule is None:
            raise ValueError(
                f"Scoring rule missing for question {question_id}."
            )

        if not rule["is_counted"]:
            not_sure_answers += 1
            continue

        score = rule["score"]

        if score is None:
            raise ValueError(
                f"Scoring value missing for question {question_id}."
            )

        total_score += score
        maximum_score += 2
        counted_answers += 1

        domain = question["domain"]

        if domain not in domain_totals:
            domain_totals[domain] = {
                "score": 0,
                "maximum_score": 0,
                "counted_questions": 0,
            }

        domain_totals[domain]["score"] += score
        domain_totals[domain]["maximum_score"] += 2
        domain_totals[domain]["counted_questions"] += 1

    if counted_answers == 0:
        raise ValueError(
            "Insufficient information: all developmental answers are Not sure."
        )

    percentage = round(
        (total_score / maximum_score) * 100,
        2,
    )

    if percentage < 20:
        concern_level = "low"
    elif percentage < 40:
        concern_level = "moderate"
    else:
        concern_level = "high"

    domain_results = {}

    for domain, values in domain_totals.items():
        domain_percentage = round(
            (values["score"] / values["maximum_score"]) * 100,
            2,
        )

        domain_results[domain] = {
            "concern_percentage": domain_percentage,
            "counted_questions": values["counted_questions"],
        }

    parent_concerns = [
        {
            "question_id": question["id"],
            "answer": answer_map[question["id"]],
        }
        for question in parent_questions
    ]

    return {
        "status": "complete",
        "concern_level": concern_level,
        "concern_percentage": percentage,
        "total_score": total_score,
        "maximum_score": maximum_score,
        "counted_answers": counted_answers,
        "not_sure_answers": not_sure_answers,
        "domains": domain_results,
        "parent_concerns": parent_concerns,
        "disclaimer": DISCLAIMER,
    }
