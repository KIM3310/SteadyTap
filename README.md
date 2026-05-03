# SteadyTap

An accessibility-focused iOS coaching app with an optional FastAPI backend for sync, coach-plan generation, and cohort benchmarks.

Works in two modes:

1. Fully local, offline-first app
2. App + backend with API contracts for cloud sync and coaching

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                   iOS App (Swift)                    │
│                                                     │
│  ┌──────────────┐  ┌───────────────┐  ┌──────────┐ │
│  │ Calibration   │  │ Practice      │  │ Results  │ │
│  │ Engine        │  │ (Baseline +   │  │ & Trends │ │
│  │ (tap/drag)    │  │  Adaptive)    │  │          │ │
│  └──────┬───────┘  └───────┬───────┘  └─────┬────┘ │
│         │                  │                │      │
│  ┌──────▼──────────────────▼────────────────▼────┐ │
│  │            AppViewModel (orchestrator)         │ │
│  │  - session history    - sync queue             │ │
│  │  - weekly goals       - streak tracking        │ │
│  └──────────────────────┬────────────────────────┘ │
│                         │                          │
│  ┌──────────────────────▼────────────────────────┐ │
│  │         BackendClient (protocol)              │ │
│  │  MockBackendClient  │  CloudBackendClient     │ │
│  └─────────────────────┼────────────────────────┘ │
│                        │ HTTP (when Cloud mode)    │
└────────────────────────┼───────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────┐
│              FastAPI Backend (Python)                │
│                                                     │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────┐ │
│  │ /v1/sessions│  │ /v1/coach/   │  │ /v1/       │ │
│  │ (upload &   │  │   plan       │  │ benchmarks │ │
│  │  history)   │  │              │  │            │ │
│  └──────┬──────┘  └──────┬───────┘  └─────┬──────┘ │
│         │                │               │        │
│  ┌──────▼────────────────▼───────────────▼──────┐ │
│  │           service.py (business logic)         │ │
│  │  - coach plan generation                      │ │
│  │  - benchmark percentile calculation           │ │
│  │  - progress report assembly                   │ │
│  └──────────────────────┬───────────────────────┘ │
│                         │                          │
│  ┌──────────────────────▼────────────────────────┐ │
│  │         SQLite (sessions, aggregates)          │ │
│  └───────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

**Data flow:** The iOS app runs calibration and challenges locally. Session summaries are optionally uploaded via the sync queue to the FastAPI backend, which stores them in SQLite and uses them to generate coach plans, benchmarks, and progress reports. The app falls back to mock/local behavior when the backend is unreachable.

## Getting started

If this is your first time looking at the repo:

- iOS app: `Package.swift`, `SteadyTapApp.swift`, `Core/`, `Views/`
- Backend: `backend/` for sync, coach-plan, and benchmark APIs
- Landing page: `site/` plus `docs/deployment/CLOUDFLARE_PAGES.md`

## What's included

- Swift App Playground for calibration, baseline/adaptive challenges, and results
- Local persistence, sync queue, and backend settings
- FastAPI backend under `backend/`
- HTTP contract for session upload, coach plans, and benchmarks

## Setup

### iOS App

1. Open the Swift package in Xcode or Swift Playgrounds with App Playground support.
2. Update `teamIdentifier` in `Package.swift` if signing is needed.
3. Run on iPhone or iPad simulator.

If you only need the mobile flow, you can ignore `backend/` and `site/`.

### Backend

**Prerequisites:** Python 3.11+

```bash
cd backend
python3.11 -m venv .venv
source .venv/bin/activate
python -m pip install -U pip
python -m pip install -e ".[dev]"
```

**Run the server:**

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8080 --reload
```

**Environment variables:**

| Variable | Purpose | Default |
|---|---|---|
| `STEADYTAP_API_KEY` | Bearer token for protected endpoints | (empty = open) |
| `STEADYTAP_DB_PATH` | SQLite database file path | `./data/steadytap.sqlite` |
| `STEADYTAP_RUNTIME_STORE_PATH` | Runtime event log path | `./data/runtime-events.jsonl` |

**Run tests and lint:**

```bash
cd backend
source .venv/bin/activate
python -m pytest -v
python -m ruff check .
```

## User flow

1. Tap calibration
2. Drag calibration
3. Calibration review
4. Baseline challenge
5. Adaptive challenge
6. Before/after report

## Key features

- Adaptive `swipeThreshold` filtering to reject unstable tap drags
- Three scoring presets: `Mistake-first`, `Balanced`, `Speed-first`
- Challenge intensity modes: `Supportive`, `Standard`, `Advanced`
- Local history, streak, trend, and weekly goal tracking
- Optional cloud sync queue with retry controls
- Remote coach-plan and cohort benchmark cards
- Readiness score, trend direction, and next-intensity recommendation

## Backend API

- `GET /v1/health`
- `GET /v1/meta`
- `GET /v1/runtime-brief`
- `GET /v1/runtime-scorecard`
- `GET /v1/review-pack`
- `GET /v1/progress-report?user_id={user_id}`
- `GET /v1/review-queue?user_id={user_id}`
- `GET /v1/schema/coach-report`
- `POST /v1/sessions` (protected)
- `POST /v1/coach/plan` (protected)
- `POST /v1/benchmarks` (protected)
- `GET /v1/sessions/{user_id}` (protected)

## Cloud mode in the app

From the home settings screen:

- `Local AI`: local/mock backend behavior only
- `Cloud API`: HTTP API with local fallback when URL is missing

Recommended simulator URL: `http://127.0.0.1:8080`

If `STEADYTAP_API_KEY` is set on the backend, paste the same bearer token into the app settings.

## Tests

Backend test suite: **10 tests, all passing**

```
tests/test_api.py::test_health_and_meta_report_runtime_state PASSED
tests/test_api.py::test_progress_report_tracks_weekly_cadence_and_coach_delta PASSED
tests/test_api.py::test_protected_routes_require_bearer_token_when_api_key_is_configured PASSED
tests/test_api.py::test_coach_plan_low_delta_yields_precision_focus PASSED
tests/test_api.py::test_coach_plan_high_delta_yields_speed_focus PASSED
tests/test_api.py::test_benchmark_percentile_reflects_delta PASSED
tests/test_api.py::test_coach_plan_moderate_delta_yields_balanced PASSED
tests/test_api.py::test_sync_queue_upload_lookup_and_dedup PASSED
tests/test_api.py::test_input_validation_rejects_invalid_payloads PASSED
tests/test_api.py::test_structured_error_response_format PASSED
```

Lint: `ruff check .` passes clean.

## CI/CD

- `.github/workflows/backend-ci.yml`: Python 3.11 -- install, compile check, ruff lint, pytest
- `.github/workflows/app-ci.yml`: macOS -- Swift build

## Repo layout

```text
SteadyTap/
  Package.swift
  SteadyTapApp.swift
  RootView.swift
  Core/
  Views/
  backend/
    README.md
    app/
    tests/
    requirements.txt
    requirements-dev.txt
  site/
  docs/deployment/CLOUDFLARE_PAGES.md
  docs/product/DECISION_LOG.md
```

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
- `backend/tests/test_api.py`: backend test coverage

## Cloud + AI Architecture

This repository includes a neutral cloud and AI engineering blueprint that maps the current proof surface to runtime boundaries, data contracts, model-risk controls, deployment posture, and validation hooks.

- [Cloud + AI architecture blueprint](docs/cloud-ai-architecture.md)
- [Machine-readable architecture manifest](docs/architecture/blueprint.json)
- Validation command: `python3 scripts/validate_architecture_blueprint.py`
