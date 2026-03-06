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
    CoachPlanRequest,
    CoachPlanResponse,
    HealthResponse,
    ServiceMetaResponse,
    SessionUploadPayload,
    UploadSessionResponse,
)
from .service import build_benchmark, build_coach_plan

APP_TITLE = "SteadyTap Backend API"
APP_VERSION = "1.0.0"
API_KEY = os.getenv("STEADYTAP_API_KEY", "").strip()
DB_PATH = os.getenv("STEADYTAP_DB_PATH", "./data/steadytap.sqlite")

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


@app.get("/v1/health", response_model=HealthResponse)
def health() -> HealthResponse:
    return HealthResponse(
        status="ok",
        session_count=db.count_sessions(),
        timestamp=datetime.now(tz=timezone.utc),
    )


@app.get("/v1/meta", response_model=ServiceMetaResponse)
def meta() -> ServiceMetaResponse:
    return ServiceMetaResponse(
        service="steadytap-backend",
        version=APP_VERSION,
        generated_at=datetime.now(tz=timezone.utc),
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
        ],
        routes=[
            "/v1/health",
            "/v1/meta",
            "/v1/sessions",
            "/v1/coach/plan",
            "/v1/benchmarks",
            "/v1/sessions/{user_id}",
        ],
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
