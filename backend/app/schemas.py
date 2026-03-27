from __future__ import annotations

from datetime import datetime
from typing import Any, Optional, Union

from pydantic import BaseModel, Field


class SessionSummaryIn(BaseModel):
    id: str = Field(min_length=1)
    timestamp: datetime
    scoring_preset_raw_value: str = Field(min_length=1)
    challenge_intensity_raw_value: Optional[str] = None
    weekly_goal_target: Optional[int] = Field(default=None, ge=1, le=14)
    baseline_score: float = Field(ge=0, le=200)
    adaptive_score: float = Field(ge=0, le=200)
    baseline_accuracy: float = Field(ge=0, le=1)
    adaptive_accuracy: float = Field(ge=0, le=1)
    miss_delta: int
    time_delta: float


class CoachPlanRequest(BaseModel):
    user_id: str = Field(min_length=1)
    recent_sessions: list[SessionSummaryIn] = Field(default_factory=list)


class BenchmarkRequest(BaseModel):
    user_id: str = Field(min_length=1)
    recent_sessions: list[SessionSummaryIn] = Field(default_factory=list)


class SessionUploadPayload(BaseModel):
    id: str = Field(min_length=1)
    user_id: str = Field(min_length=1)
    timestamp: datetime
    scoring_preset_raw_value: str = Field(min_length=1)
    challenge_intensity_raw_value: Optional[str] = None
    weekly_goal_target: Optional[int] = Field(default=None, ge=1, le=14)
    baseline_score: float = Field(ge=0, le=200)
    adaptive_score: float = Field(ge=0, le=200)
    miss_delta: int
    time_delta: float
    stability_index: float = Field(ge=0, le=1)
    confidence_score: float = Field(ge=0, le=1)
    button_scale: float = Field(gt=0, le=5)
    hold_duration: float = Field(ge=0, le=5)
    swipe_threshold: float = Field(ge=0, le=200)


class CoachPlanResponse(BaseModel):
    generated_at: datetime
    focus_area: str
    rationale: str
    recommended_preset: str
    recommended_intensity: str = "standard"
    target_score_delta: float
    target_sessions_per_week: int
    confidence: float
    evidence_basis: list[str] = Field(default_factory=list)
    alignment_with_local: str = ""
    action_items: list[str]


class BenchmarkResponse(BaseModel):
    generated_at: datetime
    cohort_label: str
    percentile: int
    average_score_delta: float


class UploadSessionResponse(BaseModel):
    accepted: bool


class HealthResponse(BaseModel):
    status: str
    session_count: int
    timestamp: datetime
    readiness_contract: str
    report_contract: dict[str, Any]
    links: dict[str, str]


class ServiceMetaResponse(BaseModel):
    service: str
    version: str
    generated_at: datetime
    readiness_contract: str
    report_contract: dict[str, Any]
    auth: dict[str, bool]
    storage: dict[str, Union[str, int]]
    capabilities: list[str]
    routes: list[str]


class ServiceBriefResponse(BaseModel):
    status: str
    service: str
    generated_at: datetime
    readiness_contract: str
    headline: str
    report_contract: dict[str, Any]
    auth_mode: str
    storage_mode: str
    evidence_counts: dict[str, int]
    review_flow: list[str]
    two_minute_review: list[str]
    watchouts: list[str]
    trust_boundary: list[str]
    proof_assets: list[dict[str, str]]
    routes: list[str]
    links: dict[str, str]


class ServiceReviewPackResponse(BaseModel):
    status: str
    service: str
    generated_at: datetime
    readiness_contract: str
    headline: str
    proof_bundle: dict[str, Any]
    sync_boundary: list[str]
    review_sequence: list[str]
    two_minute_review: list[str]
    proof_assets: list[dict[str, str]]
    watchouts: list[str]
    links: dict[str, str]


class CoachReportSchemaResponse(BaseModel):
    status: str
    service: str
    generated_at: datetime
    schema_name: str = Field(alias="schema")
    required_sections: list[str]
    operator_rules: list[str]


class ProgressReportResponse(BaseModel):
    status: str
    service: str
    generated_at: datetime
    schema_name: str = Field(alias="schema")
    user_id: str
    weekly_cadence: dict[str, Any]
    benchmark: dict[str, Any]
    coach_delta: dict[str, Any]
    review_notes: list[str]
    copy_text: str


class RuntimeScorecardResponse(BaseModel):
    status: str
    service: str
    generated_at: datetime
    readiness_contract: str
    headline: str
    summary: dict[str, Any]
    runtime: dict[str, Any]
    links: dict[str, str]
