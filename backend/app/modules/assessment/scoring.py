"""Rule-based scoring engine for Module 1 (pure Python, no web/DB code).

Transparent and explainable on purpose: every level can be traced back to a
rule in config.py. AI-assisted analysis is a later, optional layer.
"""

from datetime import date
from typing import Dict, List, Optional

from app import config
from app.modules.assessment import questions as qb
from app.modules.assessment.guidance import build_consultation, build_guidance
from app.modules.assessment.schemas import (
    AgeBandOut,
    AnswerIn,
    AnswerValue,
    AssessmentResult,
    ConcernLevel,
    DomainResult,
    FollowUp,
)


class ScoringError(ValueError):
    """Raised for invalid input (bad age, unknown / duplicate question ids)."""


# ------------------------------------------------------------------ helpers
def age_in_months(dob: date, today: Optional[date] = None) -> int:
    today = today or date.today()
    if dob > today:
        raise ScoringError("Date of birth cannot be in the future.")
    months = (today.year - dob.year) * 12 + (today.month - dob.month)
    if today.day < dob.day:
        months -= 1
    return max(months, 0)


def resolve_age(age_months: Optional[int], dob: Optional[date], today: Optional[date] = None) -> int:
    value = age_months if age_months is not None else age_in_months(dob, today)  # type: ignore[arg-type]
    if not (config.MIN_AGE_MONTHS <= value <= config.MAX_AGE_MONTHS):
        raise ScoringError(
            f"Age must be between 0 and 5 years (got {value} months). "
            "This tool supports children under 6 years."
        )
    return value


def band_out(band: qb.AgeBand) -> AgeBandOut:
    return AgeBandOut(id=band.id, label=band.label, min_months=band.min_months, max_months=band.max_months)


def question_points(q: qb.Question, answer: AnswerValue) -> Optional[int]:
    """Concern points for one answer: 0, 1 or 2 (None for 'not_sure')."""
    if answer == AnswerValue.not_sure:
        return None
    if q.polarity == "skill":
        return {AnswerValue.usually: 0, AnswerValue.sometimes: 1, AnswerValue.rarely: 2}[answer]
    # polarity == "concern"
    return {AnswerValue.usually: 2, AnswerValue.sometimes: 1, AnswerValue.rarely: 0}[answer]


def is_red_flag_triggered(q: qb.Question, answer: AnswerValue) -> bool:
    if not q.red_flag:
        return False
    if q.polarity == "skill":
        return answer == AnswerValue.rarely
    return answer == AnswerValue.usually


def level_from_pct(pct: float) -> ConcernLevel:
    if pct >= config.OVERALL_HIGH_THRESHOLD:
        return ConcernLevel.high
    if pct >= config.OVERALL_MODERATE_THRESHOLD:
        return ConcernLevel.moderate
    return ConcernLevel.low


_ORDER = {ConcernLevel.low: 0, ConcernLevel.moderate: 1, ConcernLevel.high: 2}


def _raise_to(current: ConcernLevel, minimum: ConcernLevel) -> ConcernLevel:
    return minimum if _ORDER[minimum] > _ORDER[current] else current


# --------------------------------------------------------------- main entry
def score_assessment(
    age_months: Optional[int],
    dob: Optional[date],
    answers: List[AnswerIn],
    today: Optional[date] = None,
) -> AssessmentResult:
    age = resolve_age(age_months, dob, today)
    band = qb.get_band_for_age(age)
    assert band is not None  # guaranteed by resolve_age
    band_questions = qb.get_questions_for_band(band.id)
    valid_ids = {q.id for q in band_questions}

    # --- validate answers
    seen = set()
    for a in answers:
        if a.question_id not in valid_ids:
            raise ScoringError(
                f"Question '{a.question_id}' does not belong to the {band.label} questionnaire."
            )
        if a.question_id in seen:
            raise ScoringError(f"Question '{a.question_id}' was answered more than once.")
        seen.add(a.question_id)

    answer_map: Dict[str, AnswerValue] = {a.question_id: a.answer for a in answers}

    # --- per-domain tallies
    stats = {d: {"answered": 0, "not_sure": 0, "points": 0} for d in qb.DOMAINS}
    red_flags: List[str] = []
    follow_ups: List[FollowUp] = []

    for q in band_questions:
        ans = answer_map.get(q.id)
        if ans is None:
            continue  # unanswered
        if ans == AnswerValue.not_sure:
            stats[q.domain]["not_sure"] += 1
            follow_ups.append(FollowUp(question_id=q.id, question_text=q.text, tip=q.clarify))
            continue
        stats[q.domain]["answered"] += 1
        stats[q.domain]["points"] += question_points(q, ans) or 0
        if is_red_flag_triggered(q, ans):
            red_flags.append(q.text)

    total_q = len(band_questions)
    answered = sum(s["answered"] for s in stats.values())
    not_sure = sum(s["not_sure"] for s in stats.values())
    total_points = sum(s["points"] for s in stats.values())
    max_total = answered * config.MAX_POINTS_PER_QUESTION
    overall_pct = (total_points / max_total) if max_total else 0.0

    # --- domain results
    domain_results: List[DomainResult] = []
    domain_pcts: Dict[str, float] = {}
    domain_levels: Dict[str, ConcernLevel] = {}
    for d in qb.DOMAINS:
        s = stats[d]
        max_pts = s["answered"] * config.MAX_POINTS_PER_QUESTION
        pct = (s["points"] / max_pts) if max_pts else 0.0
        lvl = level_from_pct(pct) if s["answered"] else ConcernLevel.insufficient_data
        domain_pcts[d] = pct
        domain_levels[d] = lvl
        domain_results.append(
            DomainResult(
                domain=d,
                label=qb.DOMAIN_LABELS[d],
                answered=s["answered"],
                not_sure=s["not_sure"],
                points=s["points"],
                max_points=max_pts,
                percentage=round(pct * 100, 1),
                level=lvl,
            )
        )

    # --- data sufficiency
    answered_fraction = answered / total_q
    insufficient = answered_fraction < config.MIN_ANSWERED_FRACTION
    unsure_fraction = not_sure / total_q
    confidence = "low" if (unsure_fraction > config.UNSURE_CLARIFICATION_FRACTION or insufficient) else "normal"

    # --- overall level + escalation rules
    escalation: List[str] = []
    if insufficient:
        level = ConcernLevel.insufficient_data
    else:
        level = level_from_pct(overall_pct)

        for d in qb.DOMAINS:
            if (
                stats[d]["answered"] >= config.DOMAIN_ESCALATION_MIN_ANSWERED
                and domain_pcts[d] >= config.DOMAIN_ESCALATION_THRESHOLD
            ):
                new = _raise_to(level, ConcernLevel.moderate)
                if new != level:
                    level = new
                escalation.append(
                    f"{qb.DOMAIN_LABELS[d]} answers show a strong concern pattern "
                    f"({round(domain_pcts[d] * 100)}%)."
                )

        if len(red_flags) >= config.RED_FLAGS_FOR_HIGH:
            level = _raise_to(level, ConcernLevel.high)
            escalation.append(f"{len(red_flags)} important early-warning items were flagged.")
        elif len(red_flags) >= config.RED_FLAGS_FOR_MODERATE:
            level = _raise_to(level, ConcernLevel.moderate)
            escalation.append("An important early-warning item was flagged.")

    consultation = build_consultation(level, len(red_flags), insufficient)
    guidance = [] if insufficient else build_guidance(domain_levels, domain_pcts)

    # --- plain-language summary
    if insufficient:
        summary = (
            "Not enough questions were answered to give a reliable result. "
            "Please answer more questions, using the tips for any you are unsure about."
        )
    else:
        label = level.value.capitalize()
        summary = f"Based on your answers, the developmental concern level is {label}."
        if confidence == "low":
            summary += (
                " Several answers were 'not sure', so this result is less certain. "
                "Try the observation tips and answer again."
            )

    return AssessmentResult(
        age_months=age,
        age_band=band_out(band),
        status="insufficient_data" if insufficient else "complete",
        concern_level=level,
        overall_percentage=round(overall_pct * 100, 1),
        confidence=confidence,
        total_questions=total_q,
        answered=answered,
        not_sure=not_sure,
        domains=domain_results,
        red_flags=red_flags,
        escalation_reasons=escalation,
        follow_up_questions=follow_ups,
        guidance=guidance,
        consultation=consultation,
        summary=summary,
        disclaimer=config.DISCLAIMER,
    )
