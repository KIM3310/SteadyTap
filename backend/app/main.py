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
    ProgressReportResponse,
    RuntimeScorecardResponse,
    ServiceBriefResponse,
    ServiceMetaResponse,
    ServiceReviewPackResponse,
    SessionUploadPayload,
    UploadSessionResponse,
)
from .runtime_store import build_runtime_summary, record_runtime_event
from .service import build_benchmark, build_coach_plan, build_progress_report

APP_TITLE = "SteadyTap Backend API"
APP_VERSION = "1.0.0"
API_KEY = os.getenv("STEADYTAP_API_KEY", "").strip()
DB_PATH = os.getenv("STEADYTAP_DB_PATH", "./data/steadytap.sqlite")
READINESS_CONTRACT = "steadytap-service-brief-v1"
REVIEW_PACK_CONTRACT = "steadytap-review-pack-v1"
RUNTIME_SCORECARD_CONTRACT = "steadytap-runtime-scorecard-v1"
COACH_REPORT_SCHEMA = "steadytap-coach-report-v1"
SERVICE_ROUTES = [
    "/v1/health",
    "/v1/meta",
    "/v1/runtime-brief",
    "/v1/runtime-scorecard",
    "/v1/progress-report",
    "/v1/review-pack",
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
    runtime_summary = build_runtime_summary()
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
            "runtime_events": runtime_summary["event_count"],
            "service_routes": len(SERVICE_ROUTES),
            "coach_actions": 4,
            "benchmark_surfaces": 3,
        },
        "review_flow": [
            "Open /v1/health or /v1/meta to confirm storage posture and auth mode.",
            "Read /v1/runtime-scorecard and /v1/runtime-brief before enabling cloud mode in the app.",
            "Use /v1/coach/plan and /v1/benchmarks with representative session history, then compare against local insights.",
            "Review queued uploads in the app before trusting remote guidance as the source of truth.",
        ],
        "two_minute_review": [
            "Open /v1/health or /v1/meta to confirm auth mode and storage posture.",
            "Read /v1/runtime-scorecard for event volume, busiest routes, and sync posture.",
            "Read /v1/runtime-brief for sync boundary and current watchouts.",
            "Compare /v1/coach/plan and /v1/benchmarks against recent local sessions before enabling cloud mode.",
            "Check the in-app sync queue and /v1/review-pack before treating remote guidance as authoritative.",
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
        "proof_assets": [
            {"label": "Health Surface", "href": "/v1/health"},
            {"label": "Runtime Scorecard", "href": "/v1/runtime-scorecard"},
            {"label": "Progress Report", "href": "/v1/progress-report?user_id=demo-user"},
            {"label": "Runtime Brief", "href": "/v1/runtime-brief"},
            {"label": "Review Pack", "href": "/v1/review-pack"},
            {"label": "Coach Schema", "href": "/v1/schema/coach-report"},
        ],
        "routes": SERVICE_ROUTES,
        "links": {
            "health": "/v1/health",
            "meta": "/v1/meta",
            "runtime_scorecard": "/v1/runtime-scorecard",
            "runtime_brief": "/v1/runtime-brief",
            "progress_report": "/v1/progress-report",
            "review_pack": "/v1/review-pack",
            "coach_schema": "/v1/schema/coach-report",
        },
    }


def build_review_pack() -> dict[str, object]:
    session_count = db.count_sessions()
    auth_mode = "bearer-required" if API_KEY else "open-review"
    runtime_summary = build_runtime_summary()
    return {
        "status": "ok",
        "service": "steadytap-backend",
        "generated_at": datetime.now(tz=timezone.utc),
        "readiness_contract": REVIEW_PACK_CONTRACT,
        "headline": (
            "Reviewer pack for SteadyTap cloud coaching: mobile-first sync boundary, auth posture, "
            "and remote guidance handoff in one contract."
        ),
        "proof_bundle": {
            "auth_mode": auth_mode,
            "storage_mode": "sqlite-local",
            "session_count": session_count,
            "runtime_event_count": runtime_summary["event_count"],
            "uploaded_surface_count": 5,
            "review_routes": [
                "/v1/health",
                "/v1/meta",
                "/v1/runtime-scorecard",
                "/v1/runtime-brief",
                "/v1/progress-report",
                "/v1/review-pack",
                "/v1/schema/coach-report",
            ],
        },
        "sync_boundary": [
            "Calibration raw samples, adaptive profile generation, and local history remain on device.",
            "Cloud sync uploads session summaries and adaptive profile outcomes, not full touch telemetry.",
            "Remote coach outputs should augment the mobile experience, not replace local fallback behavior.",
        ],
        "review_sequence": [
            "Open /v1/health or /v1/meta to confirm auth mode, storage posture, and route availability.",
            "Read /v1/runtime-scorecard, /v1/runtime-brief, and /v1/review-pack before enabling cloud mode for shared testing.",
            "Compare /v1/coach/plan and /v1/benchmarks against recent local sessions before adopting remote guidance.",
            "Keep queued uploads reviewable in the app so sync failures never become silent data loss.",
        ],
        "two_minute_review": [
            "Open /v1/health or /v1/meta to confirm auth and storage posture.",
            "Read /v1/runtime-scorecard for runtime event pressure and busiest sync surfaces.",
            "Read /v1/runtime-brief for sync boundary and watchouts.",
            "Read /v1/review-pack before enabling shared cloud testing.",
            "Compare remote coach outputs against local sessions before adopting them in the app.",
        ],
        "proof_assets": [
            {"label": "Health Surface", "href": "/v1/health"},
            {"label": "Runtime Scorecard", "href": "/v1/runtime-scorecard"},
            {"label": "Progress Report", "href": "/v1/progress-report?user_id=demo-user"},
            {"label": "Review Pack", "href": "/v1/review-pack"},
            {"label": "Coach Schema", "href": "/v1/schema/coach-report"},
            {"label": "Runtime Brief", "href": "/v1/runtime-brief"},
        ],
        "watchouts": [
            "A healthy backend does not prove the mobile device has current local history or a valid token configured.",
            "Uploaded summaries can drift from live motor performance if sessions are stale or sparse.",
            "Cloud review should always degrade to local/mock coaching when network or auth breaks.",
        ],
        "links": {
            "health": "/v1/health",
            "meta": "/v1/meta",
            "runtime_scorecard": "/v1/runtime-scorecard",
            "runtime_brief": "/v1/runtime-brief",
            "progress_report": "/v1/progress-report",
            "review_pack": "/v1/review-pack",
            "coach_schema": "/v1/schema/coach-report",
        },
    }


def build_runtime_scorecard() -> dict[str, object]:
    session_count = db.count_sessions()
    runtime_summary = build_runtime_summary()
    top_route = runtime_summary["top_routes"][0] if runtime_summary["top_routes"] else {"route": "n/a", "count": 0}
    runtime_score = max(45, 100 - min(int(runtime_summary["event_count"]), 30))
    return {
        "status": "ok",
        "service": "steadytap-backend",
        "generated_at": datetime.now(tz=timezone.utc),
        "readiness_contract": RUNTIME_SCORECARD_CONTRACT,
        "headline": (
            "Compact runtime scorecard for session uploads, remote coaching calls, and sync posture "
            "in the SteadyTap cloud backend."
        ),
        "summary": {
            "runtime_score": runtime_score,
            "auth_mode": "bearer-required" if API_KEY else "open-review",
            "storage_mode": "sqlite-local",
            "session_count": session_count,
            "runtime_event_count": runtime_summary["event_count"],
            "busiest_route": top_route,
        },
        "runtime": {
            "persistence": runtime_summary,
            "review_routes": [
                "/v1/health",
                "/v1/meta",
                "/v1/runtime-scorecard",
                "/v1/runtime-brief",
                "/v1/progress-report",
                "/v1/review-pack",
            ],
        },
        "links": {
            "health": "/v1/health",
            "meta": "/v1/meta",
            "runtime_scorecard": "/v1/runtime-scorecard",
            "runtime_brief": "/v1/runtime-brief",
            "progress_report": "/v1/progress-report",
            "review_pack": "/v1/review-pack",
            "coach_schema": "/v1/schema/coach-report",
        },
    }


@app.get("/v1/health", response_model=HealthResponse)
def health() -> HealthResponse:
    record_runtime_event(event_type="route_hit", route="/v1/health")
    return HealthResponse(
        status="ok",
        session_count=db.count_sessions(),
        timestamp=datetime.now(tz=timezone.utc),
        readiness_contract=READINESS_CONTRACT,
        report_contract=build_coach_report_schema(),
        links={
            "meta": "/v1/meta",
            "runtime_scorecard": "/v1/runtime-scorecard",
            "runtime_brief": "/v1/runtime-brief",
            "progress_report": "/v1/progress-report",
            "review_pack": "/v1/review-pack",
            "coach_schema": "/v1/schema/coach-report",
        },
    )


@app.get("/v1/meta", response_model=ServiceMetaResponse)
def meta() -> ServiceMetaResponse:
    record_runtime_event(event_type="route_hit", route="/v1/meta")
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
            "progress-report-surface",
            "user-session-history",
            "service-brief-surface",
            "runtime-scorecard-surface",
            "coach-report-schema",
            "review-pack-surface",
        ],
        routes=SERVICE_ROUTES,
    )


@app.get("/v1/runtime-brief", response_model=ServiceBriefResponse)
def runtime_brief() -> ServiceBriefResponse:
    record_runtime_event(event_type="route_hit", route="/v1/runtime-brief")
    return ServiceBriefResponse(**build_service_brief())


@app.get("/v1/runtime-scorecard", response_model=RuntimeScorecardResponse)
def runtime_scorecard() -> RuntimeScorecardResponse:
    record_runtime_event(event_type="route_hit", route="/v1/runtime-scorecard")
    return RuntimeScorecardResponse(**build_runtime_scorecard())


@app.get("/v1/progress-report", response_model=ProgressReportResponse)
def progress_report(user_id: str = "demo-user") -> ProgressReportResponse:
    record_runtime_event(event_type="route_hit", route="/v1/progress-report", user_id=user_id)
    recent = db.list_sessions(user_id, limit=8)
    aggregate = db.user_aggregate(user_id)
    coach_plan = build_coach_plan(user_id, recent, aggregate)
    benchmark = build_benchmark(user_id, recent, aggregate, db.global_average_delta())
    return ProgressReportResponse(
        status="ok",
        service="steadytap-backend",
        schema="steadytap-progress-report-v1",
        **build_progress_report(user_id, recent, coach_plan, benchmark),
    )


@app.get("/v1/review-pack", response_model=ServiceReviewPackResponse)
def review_pack() -> ServiceReviewPackResponse:
    record_runtime_event(event_type="route_hit", route="/v1/review-pack")
    return ServiceReviewPackResponse(**build_review_pack())


@app.get("/v1/schema/coach-report", response_model=CoachReportSchemaResponse)
def coach_report_schema() -> CoachReportSchemaResponse:
    record_runtime_event(event_type="route_hit", route="/v1/schema/coach-report")
    return CoachReportSchemaResponse(
        status="ok",
        service="steadytap-backend",
        generated_at=datetime.now(tz=timezone.utc),
        **build_coach_report_schema(),
    )


@app.post("/v1/sessions", response_model=UploadSessionResponse, dependencies=[Depends(verify_api_key)])
def upload_session(payload: SessionUploadPayload) -> UploadSessionResponse:
    db.insert_session(payload.model_dump(mode="json"))
    record_runtime_event(
        event_type="session_upload",
        route="/v1/sessions",
        user_id=payload.user_id,
        details={"session_id": payload.id},
    )
    return UploadSessionResponse(accepted=True)


@app.post("/v1/coach/plan", response_model=CoachPlanResponse, dependencies=[Depends(verify_api_key)])
def coach_plan(request: CoachPlanRequest) -> CoachPlanResponse:
    aggregate = db.user_aggregate(request.user_id)
    recent = [s.model_dump(mode="python") for s in request.recent_sessions]
    plan = build_coach_plan(request.user_id, recent, aggregate)
    record_runtime_event(
        event_type="coach_plan",
        route="/v1/coach/plan",
        user_id=request.user_id,
        details={"recent_sessions": len(recent)},
    )
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
    record_runtime_event(
        event_type="benchmark_snapshot",
        route="/v1/benchmarks",
        user_id=request.user_id,
        details={"recent_sessions": len(recent)},
    )
    return BenchmarkResponse(**snapshot)


@app.get("/v1/sessions/{user_id}", dependencies=[Depends(verify_api_key)])
def sessions(user_id: str, limit: int = 20) -> dict:
    limit = max(1, min(limit, 100))
    record_runtime_event(
        event_type="session_lookup",
        route="/v1/sessions/{user_id}",
        user_id=user_id,
        details={"limit": limit},
    )
    return {
        "user_id": user_id,
        "count": len(db.list_sessions(user_id, limit=limit)),
        "items": db.list_sessions(user_id, limit=limit),
    }
