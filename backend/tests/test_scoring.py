from datetime import date

import pytest

from app.modules.assessment import questions as qb
from app.modules.assessment.schemas import AnswerIn, AnswerValue, ConcernLevel
from app.modules.assessment.scoring import (
    ScoringError,
    age_in_months,
    question_points,
    score_assessment,
)


def best_answers(band_id: str):
    """All-healthy answers: skills 'usually', concerns 'rarely'."""
    out = []
    for q in qb.get_questions_for_band(band_id):
        out.append(AnswerIn(question_id=q.id, answer=AnswerValue.usually if q.polarity == "skill" else AnswerValue.rarely))
    return out


def worst_answers(band_id: str):
    out = []
    for q in qb.get_questions_for_band(band_id):
        out.append(AnswerIn(question_id=q.id, answer=AnswerValue.rarely if q.polarity == "skill" else AnswerValue.usually))
    return out


# ------------------------------------------------------------ question bank
def test_every_band_has_all_domains_and_unique_ids():
    ids = [q.id for q in qb.QUESTIONS]
    assert len(ids) == len(set(ids))
    for band in qb.AGE_BANDS:
        items = qb.get_questions_for_band(band.id)
        assert len(items) == 12
        assert {q.domain for q in items} == set(qb.DOMAINS)


def test_age_bands_cover_0_to_71_without_gaps():
    for m in range(0, 72):
        assert qb.get_band_for_age(m) is not None
    assert qb.get_band_for_age(72) is None


# -------------------------------------------------------------------- age
def test_age_in_months():
    assert age_in_months(date(2024, 1, 15), today=date(2025, 1, 15)) == 12
    assert age_in_months(date(2024, 1, 16), today=date(2025, 1, 15)) == 11
    assert age_in_months(date(2025, 1, 15), today=date(2025, 1, 15)) == 0


def test_future_dob_rejected():
    with pytest.raises(ScoringError):
        age_in_months(date(2030, 1, 1), today=date(2025, 1, 1))


def test_age_out_of_range_rejected():
    with pytest.raises(ScoringError):
        score_assessment(72, None, best_answers("36_71m"))


# ----------------------------------------------------------------- points
def test_question_points_polarity():
    skill = qb.get_question("12_23m_com1")
    concern = qb.get_question("12_23m_beh1")
    assert question_points(skill, AnswerValue.usually) == 0
    assert question_points(skill, AnswerValue.rarely) == 2
    assert question_points(concern, AnswerValue.usually) == 2
    assert question_points(concern, AnswerValue.rarely) == 0
    assert question_points(skill, AnswerValue.not_sure) is None


# ---------------------------------------------------------------- scoring
@pytest.mark.parametrize("band", [b.id for b in qb.AGE_BANDS])
def test_all_healthy_is_low(band):
    age = qb.AGE_BANDS[[b.id for b in qb.AGE_BANDS].index(band)].min_months
    r = score_assessment(age, None, best_answers(band))
    assert r.concern_level == ConcernLevel.low
    assert r.overall_percentage == 0
    assert r.red_flags == []
    assert r.consultation.recommended is False


@pytest.mark.parametrize("band", [b.id for b in qb.AGE_BANDS])
def test_all_worst_is_high(band):
    age = qb.AGE_BANDS[[b.id for b in qb.AGE_BANDS].index(band)].min_months
    r = score_assessment(age, None, worst_answers(band))
    assert r.concern_level == ConcernLevel.high
    assert r.overall_percentage == 100
    assert r.consultation.recommended is True
    assert r.consultation.urgency == "prompt"


def test_moderate_by_overall_percentage():
    band = "24_35m"
    answers = best_answers(band)
    # make 3 skill questions 'rarely' (3*2=6 pts of 24 -> 25%) -> Moderate, no red flags
    changed = 0
    for a in answers:
        q = qb.get_question(a.question_id)
        if q.polarity == "skill" and not q.red_flag and changed < 3:
            a.answer = AnswerValue.rarely
            changed += 1
    r = score_assessment(30, None, answers)
    assert r.overall_percentage == 25.0
    assert r.concern_level == ConcernLevel.moderate


def test_single_red_flag_escalates_to_moderate():
    band = "12_23m"
    answers = best_answers(band)
    for a in answers:
        if a.question_id == "12_23m_soc1":  # responds to name (red flag)
            a.answer = AnswerValue.rarely
    r = score_assessment(18, None, answers)
    assert len(r.red_flags) == 1
    assert r.overall_percentage < 20  # would be Low by percentage alone
    assert r.concern_level == ConcernLevel.moderate
    assert r.consultation.recommended is True


def test_two_red_flags_escalate_to_high():
    answers = best_answers("12_23m")
    for a in answers:
        if a.question_id in ("12_23m_soc1", "12_23m_soc2"):
            a.answer = AnswerValue.rarely
    r = score_assessment(18, None, answers)
    assert len(r.red_flags) == 2
    assert r.concern_level == ConcernLevel.high


def test_concern_polarity_red_flag_loss_of_skills():
    answers = best_answers("12_23m")
    for a in answers:
        if a.question_id == "12_23m_beh2":
            a.answer = AnswerValue.usually
    r = score_assessment(18, None, answers)
    assert len(r.red_flags) == 1


def test_domain_escalation():
    answers = best_answers("36_71m")
    for a in answers:
        if a.question_id.startswith("36_71m_mot"):
            a.answer = AnswerValue.rarely  # motor 100%, overall 4/24 = 16.7% (Low)
    r = score_assessment(48, None, answers)
    assert r.overall_percentage < 20
    assert r.concern_level == ConcernLevel.moderate
    assert any("Motor" in e for e in r.escalation_reasons)


# ----------------------------------------------------------- data quality
def test_not_sure_generates_followups_and_low_confidence():
    answers = best_answers("24_35m")
    for a in answers[:4]:
        a.answer = AnswerValue.not_sure  # 4/12 = 33% unsure (>25% -> low confidence)
    r = score_assessment(30, None, answers)
    assert r.not_sure == 4
    assert len(r.follow_up_questions) == 4
    assert r.confidence == "low"
    assert r.status == "complete"  # 8/12 answered = 67% (>= 60% minimum)


def test_too_many_not_sure_is_insufficient():
    answers = best_answers("24_35m")
    for a in answers[:5]:
        a.answer = AnswerValue.not_sure  # only 7/12 = 58% answered (< 60% minimum)
    r = score_assessment(30, None, answers)
    assert r.status == "insufficient_data"
    assert len(r.follow_up_questions) == 5


def test_insufficient_data_when_too_few_answered():
    answers = best_answers("24_35m")[:4]  # 4/12 = 33% answered
    r = score_assessment(30, None, answers)
    assert r.status == "insufficient_data"
    assert r.concern_level == ConcernLevel.insufficient_data
    assert r.guidance == []


def test_partial_but_sufficient_answers_ok():
    answers = best_answers("24_35m")[:9]  # 75% answered
    r = score_assessment(30, None, answers)
    assert r.status == "complete"
    assert r.concern_level == ConcernLevel.low


# ------------------------------------------------------------- validation
def test_unknown_question_rejected():
    with pytest.raises(ScoringError):
        score_assessment(30, None, [AnswerIn(question_id="nope", answer=AnswerValue.usually)])


def test_question_from_other_band_rejected():
    with pytest.raises(ScoringError):
        score_assessment(30, None, [AnswerIn(question_id="12_23m_com1", answer=AnswerValue.usually)])


def test_duplicate_answer_rejected():
    a = AnswerIn(question_id="24_35m_com1", answer=AnswerValue.usually)
    with pytest.raises(ScoringError):
        score_assessment(30, None, [a, a])


def test_dob_used_when_age_missing():
    r = score_assessment(None, date(2024, 1, 1), best_answers("24_35m"), today=date(2026, 7, 1))
    assert r.age_months == 30
    assert r.age_band.id == "24_35m"
