# SteadyTap

SteadyTap is an accessibility-first iOS App Playground with an integrated FastAPI service for cloud sync, coach-plan generation, and cohort benchmarks.

The product is designed to be reviewable in two modes:

1. fully local, offline-first app behavior
2. app + backend mode with explicit API contracts and reproducible verification

## Portfolio posture
- Treat this repo as a native accessibility product; the public page is only the front door.
- The strongest proof is the iOS flow plus the backend contract, not the landing page by itself.

## What this repo includes

- Swift App Playground for calibration, baseline/adaptive challenges, and results review
- local persistence, sync queue, and backend settings UX
- integrated FastAPI backend under `backend/`
- stable HTTP contract for session upload, coach plans, and benchmark snapshots

## User flow

1. Tap calibration
2. Drag calibration
3. Calibration review
4. Baseline challenge
5. Adaptive challenge
6. Before/after report

## Key product behaviors

- adaptive `swipeThreshold` filtering to reject unstable tap drags
- three scoring presets: `Mistake-first`, `Balanced`, `Speed-first`
- challenge intensity modes: `Supportive`, `Standard`, `Advanced`
- local history, streak, trend, and weekly goal tracking
- optional cloud sync queue with retry controls
- remote coach-plan and cohort benchmark cards
- readiness score, trend direction, and next-intensity recommendation

## Repository layout

```text
SteadyTap/
  Package.swift
  Core/
  Views/
  backend/
    app/
    tests/
    requirements.txt
    requirements-dev.txt
  DECISION_LOG.md
```

## Run the app

1. Open the Swift package in Xcode or Swift Playgrounds with App Playground support.
2. Update `teamIdentifier` in `Package.swift` if signing is needed.
3. Run on iPhone or iPad simulator.

## Run the backend

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -U pip
python -m pip install -e ".[dev]"
uvicorn app.main:app --host 0.0.0.0 --port 8080 --reload
```

Backend API surface:

- `GET /v1/health`
- `GET /v1/meta`
- `GET /v1/runtime-brief`
- `GET /v1/review-pack`
- `GET /v1/schema/coach-report`
- `POST /v1/sessions`
- `POST /v1/coach/plan`
- `POST /v1/benchmarks`
- `GET /v1/sessions/{user_id}`

Service-grade surfaces:

- backend service brief for sync boundary, auth mode, trust boundary, and review flow
- backend review pack for mobile/cloud handoff, auth posture, and queue-safe sync checks
- coach-report schema route for explicit remote coaching contract
- app home dashboard cards that surface backend posture and review pack before cloud mode is enabled

## Review Flow

1. Open `/v1/health` or `/v1/meta` to confirm auth mode and storage posture.
2. Read `/v1/runtime-brief` for sync boundary and current watchouts.
3. Compare `/v1/coach/plan` and `/v1/benchmarks` against recent local sessions before enabling cloud mode.
4. Check the in-app sync queue and `/v1/review-pack` before treating remote guidance as authoritative.

## Proof Assets

- `/v1/health`
- `/v1/runtime-brief`
- `/v1/review-pack`
- `/v1/schema/coach-report`

## Cloud mode in the app

From the home settings screen:

- `Local AI`: local/mock backend behavior only
- `Cloud API`: HTTP API with local fallback when URL is missing

Recommended simulator URL:

- `http://127.0.0.1:8080`

If `STEADYTAP_API_KEY` is set on the backend, paste the same bearer token into the app settings.

## Why this structure is intentional

- the app remains reviewable by itself
- the service contract is explicit and testable
- mobile UI and backend logic live in one canonical repo without hiding deployment boundaries

## Main files

- `Package.swift`: App Playground product setup
- `Core/BackendClient.swift`: remote/mock backend client layer
- `Core/PersistenceStore.swift`: local persistence, preferences, sync queue
- `Core/AppViewModel.swift`: app orchestration and remote insight state
- `Core/CalibrationEngine.swift`: touch metric analysis and adaptive profile generation
- `Views/IntroView.swift`: home dashboard and backend settings panel
- `Views/PracticeView.swift`: baseline/adaptive challenge
- `Views/ResultsView.swift`: before/after report
- `backend/app/main.py`: FastAPI service entrypoint
- `backend/app/service.py`: coach-plan and benchmark logic
- `backend/tests/test_api.py`: backend contract coverage

## Verification

App:

- open in Xcode
- confirm offline flow works without backend
- switch to `Cloud API` mode and confirm coach-plan / benchmark cards load

Backend:

```bash
cd backend
python -m pip install -U pip
python -m pip install -e ".[dev]"
python -m compileall -q .
python -m pytest
```
