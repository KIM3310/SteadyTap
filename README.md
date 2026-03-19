# SteadyTap

SteadyTap is an accessibility-first iOS coaching app with an optional FastAPI backend for sync, coach-plan generation, and cohort benchmarks.

The product is designed to be reviewable in two modes:

1. fully local, offline-first app behavior
2. app + backend mode with explicit API contracts and reproducible verification

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

## One concrete review story
A reviewer can picture a user with an unsteady hand starting with calibration on device, finishing one baseline challenge, then deciding whether cloud coaching is worth turning on. That keeps the handoff readable: local confidence first, backend guidance second.

## Portfolio posture
- Treat this repo like a care workflow that lives on device first and speaks to the backend second.
- The landing page matters, but the convincing proof is still calibration, challenge, and trend review on the app itself.

## Role signals
- **AI engineer / product systems:** the repo shows native interaction design, telemetry, and coaching loops in one accessibility-first workflow.
- **Solutions architect:** app behavior and backend contract stay aligned instead of being buried in separate prototypes.
- **Field / solutions engineer:** the reviewer path is short: landing page -> README -> simulator/device proof.


## Portfolio context
- **Portfolio family:** human-centered intelligent products
- **This repo's role:** accessibility and coaching product branch in the portfolio.
- **Related repos:** `the-savior`, `ecotide`

## Start here
If this is your first pass through the repo, read the surfaces in this order:

- Primary app surface: the iOS App Playground at the repo root (`Package.swift`, `SteadyTapApp.swift`, `Core/`, `Views/`)
- Optional backend surface: `backend/` for sync, coach-plan, and benchmark APIs
- Review/deploy surface: `site/` plus `docs/deployment/CLOUDFLARE_PAGES.md` for the static Pages wrapper

## What this repo includes

- Swift App Playground for calibration, baseline/adaptive challenges, and results review
- local persistence, sync queue, and backend settings UX
- integrated FastAPI backend under `backend/`
- stable HTTP contract for session upload, coach plans, and benchmark snapshots

## Setup Instructions

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

**Optional environment variables:**

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

## Key product behaviors

- adaptive `swipeThreshold` filtering to reject unstable tap drags
- three scoring presets: `Mistake-first`, `Balanced`, `Speed-first`
- challenge intensity modes: `Supportive`, `Standard`, `Advanced`
- local history, streak, trend, and weekly goal tracking
- optional cloud sync queue with retry controls
- remote coach-plan and cohort benchmark cards
- readiness score, trend direction, and next-intensity recommendation

## Backend API Surface

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

Service-grade surfaces:

- backend service brief for sync boundary, auth mode, trust boundary, and review flow
- backend review pack for mobile/cloud handoff, auth posture, and queue-safe sync checks
- backend progress report for clinician/reviewer cadence, streak adherence, and coach-plan delta review
- backend review queue for clinician/reviewer handoff, stale-user visibility, and safe cloud enablement
- coach-report schema route for explicit remote coaching contract
- app home dashboard cards that surface backend posture and review pack before cloud mode is enabled

## Repository map

Most root files belong to the Swift app. The backend and static Pages surface are intentionally isolated in their own folders.

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

## Docs map

- `README.md`: top-level product, run, and verification guide
- `backend/README.md`: backend-specific setup, env, and API notes
- `docs/deployment/CLOUDFLARE_PAGES.md`: static Pages deployment notes for the review surface
- `docs/product/DECISION_LOG.md`: implementation and product tradeoff history

## Review Flow

1. Open `/v1/health` or `/v1/meta` to confirm auth mode and storage posture.
2. Read `/v1/runtime-brief` for sync boundary and current watchouts.
3. Open `/v1/review-queue?user_id=demo-user` to identify stale users and reviewer follow-up before trusting remote guidance.
4. Compare `/v1/coach/plan` and `/v1/benchmarks` against recent local sessions before enabling cloud mode.
5. Check the in-app sync queue and `/v1/review-pack` before treating remote guidance as authoritative.

## Proof Assets

- `/v1/health`
- `/v1/runtime-brief`
- `/v1/review-pack`
- `/v1/review-queue?user_id=demo-user`
- `/v1/schema/coach-report`

## Cloud mode in the app

From the home settings screen:

- `Local AI`: local/mock backend behavior only
- `Cloud API`: HTTP API with local fallback when URL is missing

Recommended simulator URL:

- `http://127.0.0.1:8080`

If `STEADYTAP_API_KEY` is set on the backend, paste the same bearer token into the app settings.

## Test Evidence

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

Coverage areas:
- All API endpoints (health, meta, brief, scorecard, review-queue, progress-report, review-pack, coach-schema, sessions, coach/plan, benchmarks)
- Calibration/coaching logic (low/moderate/high delta thresholds)
- Benchmark percentile calculation
- Sync queue behavior (upload, lookup, deduplication)
- Input validation (Pydantic field constraints)
- Structured error responses
- Auth/bearer token enforcement

Lint: `ruff check .` passes with zero errors.

## CI/CD

- `.github/workflows/backend-ci.yml`: Python 3.11 -- install, compile check, ruff lint, pytest
- `.github/workflows/app-ci.yml`: macOS -- Swift build

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
