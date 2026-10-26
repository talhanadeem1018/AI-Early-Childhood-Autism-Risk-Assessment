# Early Development Assistant - Backend (Module 1, Step 1)

FastAPI backend for **Module 1: Developmental & Early Autism Risk Assessment**.
Step 1 = question bank + rule-based scoring + guidance + REST API (stateless, no database yet).

> Not a medical diagnosis. The tool only highlights possible developmental concerns.

## Run it

```bash
cd backend
python -m venv .venv
# Windows:  .venv\Scripts\activate      Mac/Linux:  source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Open http://127.0.0.1:8000/docs (interactive Swagger UI).

## Run the tests

```bash
pytest -v
```

## Endpoints (all under `/api/v1/assessment`)

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/health` | Service health |
| GET | `/age-bands` | The 5 supported age bands |
| GET | `/questionnaire?age_months=20` or `?date_of_birth=2025-01-10` | Age-based questionnaire (12 questions across 5 domains) |
| POST | `/score` | Submit answers, get concern level + domains + guidance + consultation advice |

Sample `POST /api/v1/assessment/score` body:

```json
{
  "age_months": 20,
  "answers": [
    {"question_id": "12_23m_com1", "answer": "usually"},
    {"question_id": "12_23m_soc1", "answer": "rarely"},
    {"question_id": "12_23m_com2", "answer": "not_sure"}
  ]
}
```

Answers: `usually | sometimes | rarely | not_sure`.

## How scoring works (all thresholds in `app/config.py`)

- Each answered question gives 0 / 1 / 2 concern points (skill questions: usually=0, rarely=2; concern behaviours: reversed).
- Overall % = points / max points of *answered* questions. `>= 20%` Moderate, `>= 40%` High.
- A domain at `>= 67%` raises the result to at least Moderate.
- Red-flag items: 1 triggered -> at least Moderate, 2+ -> High.
- `not_sure` answers are excluded from the score and returned as follow-up questions with an observation tip.
- If fewer than 60% of questions are answered -> `insufficient_data`.

## Prototype notice

The question wording and thresholds are an original prototype. Have them reviewed against validated
tools (CDC milestones, M-CHAT-R/F) by your supervisor / a clinician before any real-world use.
