# SteadyTap

SteadyTap is an accessibility-aware touch-practice utility for iPhone and iPad. It calibrates tap and drag input, compares baseline and adaptive rounds, and keeps App Store release data on the device.

## Distribution boundary

- **App Store Release:** local-only operation with no account, ads, tracking, analytics, or network upload.
- **Debug development:** optional FastAPI integration for testing sync and aggregate comparison contracts.

The release boundary is enforced in `Core/DistributionPolicy.swift` and checked by `scripts/validate_app_store_readiness.py`.

## System Overview

An on-device practice app with a separate, developer-only backend sandbox.

| Area | Details |
|---|---|
| Users | People practicing touch precision and teams evaluating adaptive mobile interaction patterns. |
| Technical path | Build the SwiftUI app, run the calibration flow, and inspect the release-policy validation. |
| System scope | SwiftUI app, local persistence, adaptive profile generation, and a debug-only FastAPI sandbox. |
| Operating boundary | App Store builds remain local-only; debug API work uses synthetic or explicitly approved test data. |
| Evaluation path | Run the iOS Release build and automated App Store readiness checks before testing the optional backend. |

## Evaluation Path

- **Start here:** Open the app and complete calibration, baseline practice, adaptive practice, and result review.
- **Release check:** Run `make verify-app-store`.
- **Core regression:** Run `./scripts/verify_cli.sh`.
- **Backend sandbox:** Run `make verify-backend` only when evaluating the developer API.

## Service Launch Playbook

- [Service launch playbook](docs/service-launch-playbook.md) maps the repository to intended audiences, operating gates, operating boundaries, and risk controls.

## Architecture Notes

- [Architecture guide](docs/architecture-evidence-map.md) summarizes the system scope, first files to inspect, runtime commands, and known boundaries.
- [Quality notes](docs/quality-gate.md) lists the local checks, CI surface, and release expectations for this repository.
- [Enterprise readiness notes](docs/enterprise-readiness.md) outlines security, data, operations, integration, and handoff expectations.
- [Repository positioning](docs/repository-positioning.md) explains why this repository is archived/supporting and where the current technical entry points live.

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

**Data flow:** The App Store release runs calibration, practice, history, and suggestions locally. Debug builds can opt into the FastAPI sandbox, which stores synthetic or approved test summaries in SQLite and returns plan and benchmark fixtures.

## Getting started

If this is your first time looking at the repo:

- iOS app: `Package.swift`, `SteadyTapApp.swift`, `Core/`, `Views/`
- Backend: `backend/` for sync, coach-plan, and benchmark APIs
- Landing page: `site/` plus `docs/deployment/CLOUDFLARE_PAGES.md`

## What's included

- Swift App Playground for calibration, baseline/adaptive challenges, and results
- Local persistence and complete local-data deletion
- Privacy manifest, production icon catalog, and submission metadata
- Debug-only FastAPI sandbox under `backend/`

## Setup

### iOS App

1. Open the Swift package in Xcode or Swift Playgrounds with App Playground support.
2. Set `teamIdentifier` in `Package.swift` when preparing a signed archive.
3. Run on iPhone or iPad simulator.

If you only need the mobile flow, you can ignore `backend/` and `site/`.

### Backend

**Prerequisites:** Python 3.11+

```bash
make verify-backend
```

If your default `python3` is older than 3.11, run `make BOOTSTRAP_PYTHON=/path/to/python3.11 verify-backend`.

**Run the server:**

```bash
cd backend
.venv/bin/python -m uvicorn app.main:app --host 0.0.0.0 --port 8080 --reload
```

**Environment variables:**

| Variable | Purpose | Default |
|---|---|---|
| `STEADYTAP_API_KEY` | Bearer token for protected endpoints | (empty = open) |
| `STEADYTAP_DB_PATH` | SQLite database file path | `./data/steadytap.sqlite` |
| `STEADYTAP_RUNTIME_STORE_PATH` | Runtime event log path | `./data/runtime-events.jsonl` |

**Run tests and lint:**

```bash
make verify-backend
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
- Release-safe local persistence and deletion controls
- Debug-only sync, plan, and benchmark inspection cards
- Readiness score, trend direction, and next-intensity recommendation

## Backend API

- `GET /v1/health`
- `GET /v1/meta`
- `GET /v1/runtime-brief`
- `GET /v1/runtime-scorecard`
- `GET /v1/architecture-pack`
- `GET /v1/progress-report?user_id={user_id}`
- `GET /v1/review-queue?user_id={user_id}`
- `GET /v1/schema/coach-report`
- `POST /v1/sessions` (protected)
- `POST /v1/coach/plan` (protected)
- `POST /v1/benchmarks` (protected)
- `GET /v1/sessions/{user_id}` (protected)

## Developer API mode

Developer API controls are compiled for debug workflows and hidden from Release users:

- `On-device`: local behavior only
- `Developer API`: test HTTP API with local fallback when its URL is missing

Recommended simulator URL: `http://127.0.0.1:8080`

If `STEADYTAP_API_KEY` is set on the backend, use the same bearer token only in a debug build. Never place it in source control.

## Tests

Run current checks instead of relying on a recorded status:

```bash
make verify-app-store
./scripts/verify_cli.sh
make verify-backend
```

## CI/CD

- `.github/workflows/backend-ci.yml`: Python 3.11 -- install, compile check, ruff lint, pytest
- `.github/workflows/app-ci.yml`: macOS -- Swift build and tests
- `.github/workflows/app-store-readiness.yml`: metadata, privacy, icon, Swift tests, and unsigned iOS Release build

## Repo layout

```text
SteadyTap/
  Package.swift
  SteadyTapApp.swift
  RootView.swift
  Core/
  Views/
  Resources/
  app-store/
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
- `Core/DistributionPolicy.swift`: Release and debug feature boundary
- `Core/BackendClient.swift`: developer backend client layer
- `Core/PersistenceStore.swift`: local persistence, preferences, sync queue
- `Core/AppViewModel.swift`: app orchestration and remote insight state
- `Core/CalibrationEngine.swift`: touch metric analysis and adaptive profile generation
- `Views/IntroView.swift`: practice home, preferences, privacy, and debug-only settings
- `Views/PracticeView.swift`: baseline/adaptive challenge
- `Views/ResultsView.swift`: before/after report
- `backend/app/main.py`: FastAPI service entrypoint
- `backend/app/service.py`: coach-plan and benchmark logic
- `backend/tests/test_api.py`: backend test coverage
- `Resources/PrivacyInfo.xcprivacy`: required-reason API and privacy declarations
- `app-store/metadata.json`: submission copy, privacy answers, and reviewer notes

## Cloud + AI Architecture

- [Cloud + AI architecture blueprint](docs/cloud-ai-architecture.md)
- [Machine-readable architecture manifest](docs/architecture/blueprint.json)
- Validation command: `python3 scripts/validate_architecture_blueprint.py`

## Enterprise Productization

- [Product operating model](docs/product-operating-model.md) defines the product scope, trust boundary, operating checks, and service path for this repository.

## System Architecture

- [System architecture](docs/system-architecture.md) maps the runtime boundary, data/control flow, cloud or local deployment surface, and operating assumptions for this repository.

## Service Architecture

- [Service architecture](docs/service-architecture.md) defines the cloud resources, account information, cost controls, and production guardrails needed to turn this repo into a scoped service without publishing public financial assumptions.

<!-- search-growth-readme:start -->

## Search And Service Surface

- Public entry: free local-first mobile demo and static explainer
- Paid boundary: fixed-scope private prototype customization for one audience-specific workflow
- Canonical URL: https://steadytap.pages.dev/
- Lead capture: https://kim3310-doeon-kim-portfolio.pages.dev/?offer=SteadyTap&inquiry=consumer-prototype-customization#private-inquiry
- Resource route: https://kim3310-doeon-kim-portfolio.pages.dev/resources/SteadyTap/
- Commercial route: https://kim3310-doeon-kim-portfolio.pages.dev/?offer=SteadyTap#service-offers
- Machine-readable offer: [docs/service-offer.json](docs/service-offer.json)
- Search growth implementation: [docs/search-growth-implementation.md](docs/search-growth-implementation.md)
- Revenue architecture: [docs/revenue-architecture.md](docs/revenue-architecture.md)

<!-- search-growth-readme:end -->

<!-- KIM3310:AD-DATA-PIVOT:START -->
## Free Resource, Advertising, and Aggregate Data

- [Public utility and architecture checklist](https://kim3310-doeon-kim-portfolio.pages.dev/resources/SteadyTap/)
- Revenue model: contextual advertising on the policy-eligible central resource page.
- Aggregate value: anonymous aggregate habit-design resource demand and CTA counts
- Boundary: ads allowed only on public habit-design articles and resource pages; personal routine tracking, reminders, and result screens are ad-free
- Consent defaults off, DNT/GPC fail closed, and personal or sensitive data is never sold.
<!-- KIM3310:AD-DATA-PIVOT:END -->
