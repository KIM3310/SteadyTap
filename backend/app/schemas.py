from __future__ import annotations

from datetime import datetime
from typing import Any, Optional, Union
from pydantic import BaseModel, Field


class SessionSummaryIn(BaseModel):
    id: str
    timestamp: datetime
    scoring_preset_raw_value: str
    challenge_intensity_raw_value: Optional[str] = None
    weekly_goal_target: Optional[int] = None
    baseline_score: float
    adaptive_score: float
    baseline_accuracy: float
    adaptive_accuracy: float
    miss_delta: int
    time_delta: float


class CoachPlanRequest(BaseModel):
    user_id: str = Field(min_length=1)
    recent_sessions: list[SessionSummaryIn] = Field(default_factory=list)


class BenchmarkRequest(BaseModel):
    user_id: str = Field(min_length=1)
    recent_sessions: list[SessionSummaryIn] = Field(default_factory=list)


class SessionUploadPayload(BaseModel):
    id: str
    user_id: str
    timestamp: datetime
    scoring_preset_raw_value: str
    challenge_intensity_raw_value: Optional[str] = None
    weekly_goal_target: Optional[int] = None
    baseline_score: float
    adaptive_score: float
    miss_delta: int
    time_delta: float
    stability_index: float
    confidence_score: float
    button_scale: float
    hold_duration: float
    swipe_threshold: float


class CoachPlanResponse(BaseModel):
    generated_at: datetime
    focus_area: str
    rationale: str
    recommended_preset: str
    recommended_intensity: str = "standard"
    target_score_delta: float
    target_sessions_per_week: int
    confidence: float
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
    watchouts: list[str]
    trust_boundary: list[str]
    routes: list[str]


class ServiceReviewPackResponse(BaseModel):
    status: str
    service: str
    generated_at: datetime
    readiness_contract: str
    headline: str
    proof_bundle: dict[str, Any]
    sync_boundary: list[str]
    review_sequence: list[str]
    watchouts: list[str]
    links: dict[str, str]


class CoachReportSchemaResponse(BaseModel):
    status: str
    service: str
    generated_at: datetime
    schema_name: str = Field(alias="schema")
    required_sections: list[str]
    operator_rules: list[str]
