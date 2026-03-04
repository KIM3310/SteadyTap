# SteadyTap Backend (FastAPI)

Production-ready starter backend for SteadyTap cloud mode.

## Features

- `POST /v1/sessions`: ingest session uploads from the app
- `POST /v1/coach/plan`: return a personalized coach plan
- Coach plan includes recommended preset + recommended intensity + action items
- `POST /v1/benchmarks`: return cohort benchmark snapshot
- `GET /v1/health`: health check
- Optional bearer-token auth via `STEADYTAP_API_KEY`
- SQLite persistence for uploaded sessions
- Session storage includes challenge intensity and weekly goal target

## Run locally

```bash
cd /Users/kim/SteadyTap-backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8080 --reload
```

## Environment variables

- `STEADYTAP_API_KEY`: optional bearer token for all `/v1/*` protected routes
- `STEADYTAP_DB_PATH`: sqlite db path (default: `./data/steadytap.sqlite`)

## Cloud mode setup in app

In `SteadyTap` app settings:
1. Set backend mode to `Cloud API`.
2. Set API base URL to `http://127.0.0.1:8080` (simulator local test).
3. If `STEADYTAP_API_KEY` is set, paste it into app `Bearer Token`.
4. Run sessions and trigger `Sync Now`.

<!-- codex:local-verification:start -->
## Local Verification
```bash
/Library/Developer/CommandLineTools/usr/bin/python3 -m venv .venv
source .venv/bin/activate
python -m pip install -U pip
python -m pip install -r requirements.txt
python -m compileall -q .
```

## Repository Hygiene
- Keep runtime artifacts out of commits (`.codex_runs/`, cache folders, temporary venvs).
- Prefer running verification commands above before opening a PR.

_Last updated: 2026-03-04_
<!-- codex:local-verification:end -->
