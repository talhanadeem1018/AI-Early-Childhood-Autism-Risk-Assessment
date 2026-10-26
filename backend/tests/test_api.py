from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health():
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json()["status"] == "ok"


def test_age_bands():
    r = client.get("/api/v1/assessment/age-bands")
    assert r.status_code == 200
    assert len(r.json()) == 5


def test_questionnaire_by_age():
    r = client.get("/api/v1/assessment/questionnaire", params={"age_months": 20})
    assert r.status_code == 200
    body = r.json()
    assert body["age_band"]["id"] == "12_23m"
    assert body["total_questions"] == 12
    assert body["answer_choices"] == ["usually", "sometimes", "rarely", "not_sure"]
    assert "diagnosis" in body["disclaimer"].lower()


def test_questionnaire_by_dob():
    r = client.get("/api/v1/assessment/questionnaire", params={"date_of_birth": "2020-01-01"})
    assert r.status_code in (200, 422)  # depends on today's date; must never be 500


def test_questionnaire_requires_age_or_dob():
    assert client.get("/api/v1/assessment/questionnaire").status_code == 422


def test_questionnaire_age_out_of_range():
    assert client.get("/api/v1/assessment/questionnaire", params={"age_months": 100}).status_code == 422


def _full_answers(age_months, healthy=True):
    q = client.get("/api/v1/assessment/questionnaire", params={"age_months": age_months}).json()
    from app.modules.assessment import questions as qb

    out = []
    for item in q["questions"]:
        pol = qb.get_question(item["id"]).polarity
        if healthy:
            ans = "usually" if pol == "skill" else "rarely"
        else:
            ans = "rarely" if pol == "skill" else "usually"
        out.append({"question_id": item["id"], "answer": ans})
    return out


def test_full_flow_healthy():
    r = client.post("/api/v1/assessment/score", json={"age_months": 20, "answers": _full_answers(20, True)})
    assert r.status_code == 200
    body = r.json()
    assert body["concern_level"] == "low"
    assert body["status"] == "complete"
    assert len(body["domains"]) == 5


def test_full_flow_concerning():
    r = client.post("/api/v1/assessment/score", json={"age_months": 20, "answers": _full_answers(20, False)})
    body = r.json()
    assert r.status_code == 200
    assert body["concern_level"] == "high"
    assert body["consultation"]["recommended"] is True
    assert len(body["guidance"]) >= 1
    assert body["disclaimer"]


def test_score_bad_question_id_422():
    r = client.post(
        "/api/v1/assessment/score",
        json={"age_months": 20, "answers": [{"question_id": "bad", "answer": "usually"}]},
    )
    assert r.status_code == 422


def test_score_bad_answer_value_422():
    r = client.post(
        "/api/v1/assessment/score",
        json={"age_months": 20, "answers": [{"question_id": "12_23m_com1", "answer": "maybe"}]},
    )
    assert r.status_code == 422


def test_score_missing_age_and_dob_422():
    r = client.post(
        "/api/v1/assessment/score",
        json={"answers": [{"question_id": "12_23m_com1", "answer": "usually"}]},
    )
    assert r.status_code == 422


def test_score_empty_answers_422():
    assert client.post("/api/v1/assessment/score", json={"age_months": 20, "answers": []}).status_code == 422
