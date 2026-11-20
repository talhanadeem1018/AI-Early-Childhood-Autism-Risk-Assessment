# Project Checklist

Status of the Early Childhood Autism Risk Assessment system.
`[x]` = implemented, `[ ]` = not started yet.

## Backend — Module 1: Developmental & Early Autism Risk Assessment (DONE)

Step 1 is complete: FastAPI service with an age-based question bank, rule-based
scoring, personalised guidance and a REST API. It is stateless — no database yet.

### Project setup
- [x] FastAPI app (`backend/app/main.py`) with CORS enabled for Flutter web/emulators
- [x] Central config for thresholds, age limits and disclaimer (`backend/app/config.py`)
- [x] Dependencies listed in `backend/requirements.txt` (FastAPI, Uvicorn, Pydantic, pytest, httpx)
- [x] Swagger UI available at `/docs`
- [x] Health check endpoint `GET /health`
- [x] Project documentation (`backend/README.md`)

### Question bank
- [x] 5 age bands: 0-5m, 6-11m, 12-23m, 24-35m, 36-71m
- [x] 12 questions per band (60 total) across 5 domains: communication, social, cognitive, motor, behavioral
- [x] Skill vs. concern polarity per question
- [x] Red-flag items (e.g. lost skills, no response to name)
- [x] "How to observe this" clarification tip on every question (shown when a parent answers "not sure")
- [x] Answer scale: `usually | sometimes | rarely | not_sure`

### Scoring engine (`backend/app/modules/assessment/scoring.py`)
- [x] Age resolution from `age_months` or `date_of_birth`, with 0-71 month validation
- [x] Input validation: unknown question IDs, duplicate answers, wrong-band questions
- [x] Per-question concern points (0/1/2) and per-domain percentages
- [x] Overall concern level: Low / Moderate / High
- [x] Domain escalation (a domain at >= 67% raises the result to at least Moderate)
- [x] Red-flag escalation (1 -> at least Moderate, 2+ -> High)
- [x] `insufficient_data` status when fewer than 60% of questions are answered
- [x] Low-confidence flag when too many "not sure" answers
- [x] `not_sure` answers excluded from scoring and returned as follow-up questions with tips
- [x] Plain-language result summary and escalation reasons

### Guidance & consultation advice (`backend/app/modules/assessment/guidance.py`)
- [x] Domain-specific home activity tips for every domain with any concern, highest concern first
- [x] General encouragement tips when no concern is found
- [x] Consultation recommendation with urgency: `routine` / `soon` / `prompt`
- [x] Medical disclaimer on every questionnaire and result

### REST API (`/api/v1/assessment`)
- [x] `GET /api/v1/assessment/age-bands` — list supported age bands
- [x] `GET /api/v1/assessment/questionnaire?age_months=20` (or `?date_of_birth=YYYY-MM-DD`) — age-appropriate questionnaire
- [x] `POST /api/v1/assessment/score` — submit answers, get full assessment result
- [x] Pydantic request/response schemas with 422 errors for invalid input

### Tests
- [x] Scoring unit tests (`backend/tests/test_scoring.py`)
- [x] API tests (`backend/tests/test_api.py`)
- [x] 41 test cases collected on the last pytest run

## Not done yet (next steps)

### Backend
- [ ] Database persistence of assessments (Supabase/Postgres) — endpoint notes say "saving comes next"
- [ ] User accounts / authentication and parent-child profiles
- [ ] Save history of past assessments and progress tracking
- [ ] Restrict CORS before deployment and deploy the API
- [ ] Clinical review/calibration of question wording and thresholds (prototype values)

### Flutter app
- [ ] Replace the default Flutter counter app (`lib/main.dart`) with the real UI
- [ ] API client for the assessment endpoints
- [ ] Age/date-of-birth entry and questionnaire screens
- [ ] Results screen (concern level, domains, guidance, consultation advice) with disclaimer
- [ ] "Not sure" clarification tips and follow-up question UI

### Other modules
- [ ] Behavioral observation module
- [ ] Screen-time monitoring module
- [ ] AI-assisted analysis / personalized guidance layer
