from __future__ import annotations

import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

from fastapi import Depends, FastAPI, Header, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from .db import Database
from .schemas import (
    BenchmarkRequest,
    BenchmarkResponse,
    CoachReportSchemaResponse,
    CoachPlanRequest,
    CoachPlanResponse,
    HealthResponse,
    ServiceBriefResponse,
    ServiceMetaResponse,
    SessionUploadPayload,
    UploadSessionResponse,
)
from .service import build_benchmark, build_coach_plan

APP_TITLE = "SteadyTap Backend API"
APP_VERSION = "1.0.0"
API_KEY = os.getenv("STEADYTAP_API_KEY", "").strip()
DB_PATH = os.getenv("STEADYTAP_DB_PATH", "./data/steadytap.sqlite")
READINESS_CONTRACT = "steadytap-service-brief-v1"
COACH_REPORT_SCHEMA = "steadytap-coach-report-v1"
SERVICE_ROUTES = [
    "/v1/health",
    "/v1/meta",
    "/v1/runtime-brief",
    "/v1/schema/coach-report",
    "/v1/sessions",
    "/v1/coach/plan",
    "/v1/benchmarks",
    "/v1/sessions/{user_id}",
]

app = FastAPI(title=APP_TITLE, version=APP_VERSION)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


db = Database(DB_PATH)


def verify_api_key(authorization: Optional[str] = Header(default=None)) -> None:
    if not API_KEY:
        return

    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")

    token = authorization.removeprefix("Bearer ").strip()
    if token != API_KEY:
        raise HTTPException(status_code=401, detail="Invalid token")


def build_coach_report_schema() -> dict[str, object]:
    return {
        "schema": COACH_REPORT_SCHEMA,
        "required_sections": [
            "focus_area",
            "rationale",
            "recommended_preset",
            "recommended_intensity",
            "target_score_delta",
            "target_sessions_per_week",
            "confidence",
            "action_items",
        ],
        "operator_rules": [
            "Review local session history before trusting remote coach recommendations.",
            "Cloud mode uploads run summaries only; calibration raw samples remain on device.",
            "If API key protection is enabled, the same bearer token must be configured in the app settings.",
        ],
    }


def build_service_brief() -> dict[str, object]:
    session_count = db.count_sessions()
    return {
        "status": "ok",
        "service": "steadytap-backend",
        "generated_at": datetime.now(tz=timezone.utc),
        "readiness_contract": READINESS_CONTRACT,
        "headline": (
            "Accessibility-first coaching backend that accepts run summaries, generates coach plans, "
            "and exposes explicit sync boundaries for the mobile app."
        ),
        "report_contract": build_coach_report_schema(),
        "auth_mode": "bearer-required" if API_KEY else "open-review",
        "storage_mode": "sqlite-local",
        "evidence_counts": {
            "session_count": session_count,
            "service_routes": len(SERVICE_ROUTES),
            "coach_actions": 4,
            "benchmark_surfaces": 2,
        },
        "review_flow": [
            "Open /v1/health or /v1/meta to confirm storage posture and auth mode.",
            "Read /v1/runtime-brief before enabling cloud mode in the app.",
            "Use /v1/coach/plan and /v1/benchmarks with representative session history, then compare against local insights.",
            "Review queued uploads in the app before trusting remote guidance as the source of truth.",
        ],
        "watchouts": [
            "The backend stores run summaries, not raw calibration traces or full touch telemetry.",
            "Coach and benchmark outputs depend on the quality and recency of uploaded session summaries.",
            "Cloud mode should degrade gracefully to local/mock behavior when the API is unavailable.",
        ],
        "trust_boundary": [
            "On-device calibration and local history remain available without network dependency.",
            "Uploaded payloads are limited to session summaries and adaptive profile outcomes.",
            "Bearer-token protection is optional for local review but should be enabled for shared environments.",
        ],
        "routes": SERVICE_ROUTES,
    }


@app.get("/v1/health", response_model=HealthResponse)
def health() -> HealthResponse:
    return HealthResponse(
        status="ok",
        session_count=db.count_sessions(),
        timestamp=datetime.now(tz=timezone.utc),
        readiness_contract=READINESS_CONTRACT,
        report_contract=build_coach_report_schema(),
        links={
            "meta": "/v1/meta",
            "runtime_brief": "/v1/runtime-brief",
            "coach_schema": "/v1/schema/coach-report",
        },
    )


@app.get("/v1/meta", response_model=ServiceMetaResponse)
def meta() -> ServiceMetaResponse:
    return ServiceMetaResponse(
        service="steadytap-backend",
        version=APP_VERSION,
        generated_at=datetime.now(tz=timezone.utc),
        readiness_contract=READINESS_CONTRACT,
        report_contract=build_coach_report_schema(),
        auth={
            "api_key_required": bool(API_KEY),
        },
        storage={
            "db_path": str(Path(DB_PATH)),
            "session_count": db.count_sessions(),
        },
        capabilities=[
            "session-ingestion",
            "coach-plan-generation",
            "benchmark-snapshots",
            "user-session-history",
            "service-brief-surface",
            "coach-report-schema",
        ],
        routes=SERVICE_ROUTES,
    )


@app.get("/v1/runtime-brief", response_model=ServiceBriefResponse)
def runtime_brief() -> ServiceBriefResponse:
    return ServiceBriefResponse(**build_service_brief())


@app.get("/v1/schema/coach-report", response_model=CoachReportSchemaResponse)
def coach_report_schema() -> CoachReportSchemaResponse:
    return CoachReportSchemaResponse(
        status="ok",
        service="steadytap-backend",
        generated_at=datetime.now(tz=timezone.utc),
        **build_coach_report_schema(),
    )


@app.post("/v1/sessions", response_model=UploadSessionResponse, dependencies=[Depends(verify_api_key)])
def upload_session(payload: SessionUploadPayload) -> UploadSessionResponse:
    db.insert_session(payload.model_dump(mode="json"))
    return UploadSessionResponse(accepted=True)


@app.post("/v1/coach/plan", response_model=CoachPlanResponse, dependencies=[Depends(verify_api_key)])
def coach_plan(request: CoachPlanRequest) -> CoachPlanResponse:
    aggregate = db.user_aggregate(request.user_id)
    recent = [s.model_dump(mode="python") for s in request.recent_sessions]
    plan = build_coach_plan(request.user_id, recent, aggregate)
    return CoachPlanResponse(**plan)


@app.post("/v1/benchmarks", response_model=BenchmarkResponse, dependencies=[Depends(verify_api_key)])
def benchmarks(request: BenchmarkRequest) -> BenchmarkResponse:
    aggregate = db.user_aggregate(request.user_id)
    recent = [s.model_dump(mode="python") for s in request.recent_sessions]
    snapshot = build_benchmark(
        request.user_id,
        recent,
        aggregate,
        db.global_average_delta(),
    )
    return BenchmarkResponse(**snapshot)


@app.get("/v1/sessions/{user_id}", dependencies=[Depends(verify_api_key)])
def sessions(user_id: str, limit: int = 20) -> dict:
    limit = max(1, min(limit, 100))
    return {
        "user_id": user_id,
        "count": len(db.list_sessions(user_id, limit=limit)),
        "items": db.list_sessions(user_id, limit=limit),
    }
