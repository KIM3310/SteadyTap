from __future__ import annotations

import importlib
import os
import sys
from pathlib import Path

from fastapi.testclient import TestClient

BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))


def load_main_module(tmp_path: Path, api_key: str = ""):
    os.environ["STEADYTAP_DB_PATH"] = str(tmp_path / "steadytap.sqlite")
    os.environ["STEADYTAP_RUNTIME_STORE_PATH"] = str(tmp_path / "runtime-events.jsonl")
    if api_key:
        os.environ["STEADYTAP_API_KEY"] = api_key
    else:
        os.environ.pop("STEADYTAP_API_KEY", None)

    sys.modules.pop("app.main", None)
    sys.modules.pop("app.runtime_store", None)
    module = importlib.import_module("app.main")
    return importlib.reload(module)


SAMPLE_SESSION_PAYLOAD = {
    "id": "sess-001",
    "user_id": "kim",
    "timestamp": "2026-03-10T09:00:00Z",
    "scoring_preset_raw_value": "balanced",
    "challenge_intensity_raw_value": "standard",
    "weekly_goal_target": 4,
    "baseline_score": 72,
    "adaptive_score": 81,
    "miss_delta": 2,
    "time_delta": -1.8,
    "stability_index": 0.74,
    "confidence_score": 0.8,
    "button_scale": 1.0,
    "hold_duration": 0.15,
    "swipe_threshold": 24,
}


# ---------------------------------------------------------------------------
# 1. Health and meta endpoints return expected contract fields
# ---------------------------------------------------------------------------
def test_health_and_meta_report_runtime_state(tmp_path: Path):
    main = load_main_module(tmp_path)
    client = TestClient(main.app)

    health = client.get("/v1/health")
    meta = client.get("/v1/meta")
    brief = client.get("/v1/runtime-brief")
    scorecard = client.get("/v1/runtime-scorecard")
    progress_report = client.get("/v1/progress-report?user_id=kim")
    review_pack = client.get("/v1/review-pack")
    schema = client.get("/v1/schema/coach-report")

    assert health.status_code == 200
    assert health.json()["session_count"] == 0
    assert health.json()["readiness_contract"] == "steadytap-service-brief-v1"
    assert health.json()["report_contract"]["schema"] == "steadytap-coach-report-v1"
    assert health.json()["links"]["runtime_brief"] == "/v1/runtime-brief"
    assert health.json()["links"]["runtime_scorecard"] == "/v1/runtime-scorecard"
    assert health.json()["links"]["review_queue"] == "/v1/review-queue?user_id=demo-user"
    assert health.json()["links"]["progress_report"] == "/v1/progress-report"
    assert health.json()["links"]["review_pack"] == "/v1/review-pack"

    assert meta.status_code == 200
    body = meta.json()
    assert body["service"] == "steadytap-backend"
    assert body["auth"]["api_key_required"] is False
    assert body["storage"]["db_path"].endswith("steadytap.sqlite")
    assert "/v1/meta" in body["routes"]
    assert "/v1/runtime-brief" in body["routes"]
    assert "/v1/runtime-scorecard" in body["routes"]
    assert "/v1/review-queue" in body["routes"]
    assert "/v1/progress-report" in body["routes"]
    assert "/v1/review-pack" in body["routes"]
    assert body["readiness_contract"] == "steadytap-service-brief-v1"
    assert body["report_contract"]["schema"] == "steadytap-coach-report-v1"
    assert "runtime-scorecard-surface" in body["capabilities"]
    assert "review-queue-surface" in body["capabilities"]
    assert "review-pack-surface" in body["capabilities"]

    assert brief.status_code == 200
    brief_body = brief.json()
    assert brief_body["readiness_contract"] == "steadytap-service-brief-v1"
    assert brief_body["report_contract"]["schema"] == "steadytap-coach-report-v1"
    assert brief_body["evidence_counts"]["service_routes"] >= 8
    assert brief_body["evidence_counts"]["runtime_events"] >= 3
    assert len(brief_body["two_minute_review"]) == 6
    assert brief_body["proof_assets"][0]["href"] == "/v1/health"
    assert brief_body["proof_assets"][1]["href"] == "/v1/runtime-scorecard"
    assert brief_body["proof_assets"][2]["href"] == "/v1/review-queue?user_id=demo-user"
    assert brief_body["links"]["review_queue"] == "/v1/review-queue?user_id=demo-user"
    assert brief_body["links"]["progress_report"] == "/v1/progress-report"

    assert scorecard.status_code == 200
    scorecard_body = scorecard.json()
    assert scorecard_body["readiness_contract"] == "steadytap-runtime-scorecard-v1"
    assert scorecard_body["summary"]["runtime_event_count"] >= 4
    assert scorecard_body["links"]["review_queue"] == "/v1/review-queue?user_id=demo-user"
    assert scorecard_body["links"]["runtime_scorecard"] == "/v1/runtime-scorecard"

    review_queue = client.get("/v1/review-queue?user_id=kim")
    assert review_queue.status_code == 200
    review_queue_body = review_queue.json()
    assert review_queue_body["contract_version"] == "steadytap-review-queue-v1"
    assert review_queue_body["summary"]["queue_items"] >= 1
    assert review_queue_body["summary"]["blocked"] is True
    assert review_queue_body["links"]["review_queue"] == "/v1/review-queue?user_id=kim"

    assert progress_report.status_code == 200
    progress_body = progress_report.json()
    assert progress_body["schema"] == "steadytap-progress-report-v1"
    assert progress_body["user_id"] == "kim"
    assert progress_body["weekly_cadence"]["sessions_completed"] == 0
    assert progress_body["weekly_cadence"]["streak_days"] == 0

    assert review_pack.status_code == 200
    review_pack_body = review_pack.json()
    assert review_pack_body["readiness_contract"] == "steadytap-review-pack-v1"
    assert review_pack_body["proof_bundle"]["auth_mode"] in {"open-review", "bearer-required"}
    assert "/v1/runtime-scorecard" in review_pack_body["proof_bundle"]["review_routes"]
    assert "/v1/review-queue" in review_pack_body["proof_bundle"]["review_routes"]
    assert "/v1/progress-report" in review_pack_body["proof_bundle"]["review_routes"]
    assert "/v1/review-pack" in review_pack_body["proof_bundle"]["review_routes"]
    assert isinstance(review_pack_body["review_sequence"], list)
    assert len(review_pack_body["two_minute_review"]) == 6
    assert review_pack_body["proof_assets"][0]["href"] == "/v1/health"
    assert review_pack_body["proof_assets"][1]["href"] == "/v1/runtime-scorecard"
    assert review_pack_body["proof_assets"][2]["href"] == "/v1/review-queue?user_id=demo-user"

    assert schema.status_code == 200
    schema_body = schema.json()
    assert schema_body["schema"] == "steadytap-coach-report-v1"
    assert "action_items" in schema_body["required_sections"]
    assert "evidence_basis" in schema_body["required_sections"]
    assert "alignment_with_local" in schema_body["required_sections"]

    coach_plan = client.post(
        "/v1/coach/plan",
        json={
            "user_id": "kim",
            "recent_sessions": [
                {
                    "id": "sess-1",
                    "timestamp": "2026-03-16T00:00:00Z",
                    "scoring_preset_raw_value": "balanced",
                    "challenge_intensity_raw_value": "standard",
                    "weekly_goal_target": 4,
                    "baseline_score": 72.0,
                    "adaptive_score": 81.0,
                    "baseline_accuracy": 0.82,
                    "adaptive_accuracy": 0.9,
                    "miss_delta": -2,
                    "time_delta": -3.5,
                }
            ],
        },
    )
    assert coach_plan.status_code == 200
    coach_body = coach_plan.json()
    assert isinstance(coach_body["evidence_basis"], list)
    assert len(coach_body["evidence_basis"]) >= 3
    assert coach_body["alignment_with_local"]


# ---------------------------------------------------------------------------
# 2. Progress report tracks weekly cadence and coach delta after session uploads
# ---------------------------------------------------------------------------
def test_progress_report_tracks_weekly_cadence_and_coach_delta(tmp_path: Path):
    main = load_main_module(tmp_path)
    client = TestClient(main.app)

    payload = dict(SAMPLE_SESSION_PAYLOAD)
    client.post("/v1/sessions", json=payload)
    payload["id"] = "sess-002"
    payload["timestamp"] = "2026-03-11T09:00:00Z"
    payload["adaptive_score"] = 84
    client.post("/v1/sessions", json=payload)

    response = client.get("/v1/progress-report?user_id=kim")
    assert response.status_code == 200
    body = response.json()
    assert body["weekly_cadence"]["sessions_completed"] == 2
    assert body["weekly_cadence"]["target_sessions"] == 4
    assert body["coach_delta"]["current_average_delta"] >= 9
    assert "copy_text" in body

    review_queue = client.get("/v1/review-queue?user_id=kim")
    assert review_queue.status_code == 200
    queue_body = review_queue.json()
    assert queue_body["summary"]["blocked"] is False
    assert queue_body["summary"]["session_count"] == 2
    assert queue_body["items"][0]["queue_id"].startswith("kim-")


# ---------------------------------------------------------------------------
# 3. Protected routes require bearer token when API key is configured
# ---------------------------------------------------------------------------
def test_protected_routes_require_bearer_token_when_api_key_is_configured(tmp_path: Path):
    main = load_main_module(tmp_path, api_key="top-secret")
    client = TestClient(main.app)

    unauthorized = client.post("/v1/benchmarks", json={"user_id": "kim", "recent_sessions": []})
    authorized = client.get("/v1/meta")

    assert unauthorized.status_code == 401
    assert authorized.status_code == 200
    assert authorized.json()["auth"]["api_key_required"] is True


# ---------------------------------------------------------------------------
# 4. Coach plan calibration logic: low delta yields precision focus
# ---------------------------------------------------------------------------
def test_coach_plan_low_delta_yields_precision_focus(tmp_path: Path):
    main = load_main_module(tmp_path)
    client = TestClient(main.app)

    response = client.post(
        "/v1/coach/plan",
        json={
            "user_id": "test-user",
            "recent_sessions": [
                {
                    "id": "s1",
                    "timestamp": "2026-03-10T00:00:00Z",
                    "scoring_preset_raw_value": "balanced",
                    "baseline_score": 70.0,
                    "adaptive_score": 73.0,
                    "baseline_accuracy": 0.8,
                    "adaptive_accuracy": 0.85,
                    "miss_delta": -1,
                    "time_delta": -0.5,
                },
            ],
        },
    )
    assert response.status_code == 200
    body = response.json()
    assert body["focus_area"] == "Precision stabilization"
    assert body["recommended_preset"] == "missFocused"
    assert body["recommended_intensity"] == "supportive"
    assert body["confidence"] > 0.4
    assert body["confidence"] <= 0.95


# ---------------------------------------------------------------------------
# 5. Coach plan calibration logic: high delta yields speed focus
# ---------------------------------------------------------------------------
def test_coach_plan_high_delta_yields_speed_focus(tmp_path: Path):
    main = load_main_module(tmp_path)
    client = TestClient(main.app)

    response = client.post(
        "/v1/coach/plan",
        json={
            "user_id": "test-user",
            "recent_sessions": [
                {
                    "id": "s1",
                    "timestamp": "2026-03-10T00:00:00Z",
                    "scoring_preset_raw_value": "balanced",
                    "baseline_score": 60.0,
                    "adaptive_score": 75.0,
                    "baseline_accuracy": 0.7,
                    "adaptive_accuracy": 0.92,
                    "miss_delta": -3,
                    "time_delta": -2.0,
                },
            ],
        },
    )
    assert response.status_code == 200
    body = response.json()
    assert body["focus_area"] == "Adaptive speed confidence"
    assert body["recommended_preset"] == "speedFocused"
    assert body["recommended_intensity"] == "advanced"


# ---------------------------------------------------------------------------
# 6. Benchmark percentile reflects user delta vs global average
# ---------------------------------------------------------------------------
def test_benchmark_percentile_reflects_delta(tmp_path: Path):
    main = load_main_module(tmp_path)
    client = TestClient(main.app)

    # Upload some sessions to create a global average
    for i in range(3):
        payload = dict(SAMPLE_SESSION_PAYLOAD)
        payload["id"] = f"bench-sess-{i}"
        payload["user_id"] = "global-user"
        payload["baseline_score"] = 70
        payload["adaptive_score"] = 76
        client.post("/v1/sessions", json=payload)

    # Request benchmark for a user with higher delta
    response = client.post(
        "/v1/benchmarks",
        json={
            "user_id": "test-user",
            "recent_sessions": [
                {
                    "id": "b1",
                    "timestamp": "2026-03-10T00:00:00Z",
                    "scoring_preset_raw_value": "balanced",
                    "baseline_score": 60.0,
                    "adaptive_score": 80.0,
                    "baseline_accuracy": 0.75,
                    "adaptive_accuracy": 0.9,
                    "miss_delta": -2,
                    "time_delta": -1.0,
                },
            ],
        },
    )
    assert response.status_code == 200
    body = response.json()
    assert body["percentile"] >= 20
    assert body["percentile"] <= 99
    assert body["cohort_label"] == "Motor accessibility learners"
    assert body["average_score_delta"] >= 0


# ---------------------------------------------------------------------------
# 7. Coaching recommendations: moderate delta yields balanced plan
# ---------------------------------------------------------------------------
def test_coach_plan_moderate_delta_yields_balanced(tmp_path: Path):
    main = load_main_module(tmp_path)
    client = TestClient(main.app)

    response = client.post(
        "/v1/coach/plan",
        json={
            "user_id": "test-user",
            "recent_sessions": [
                {
                    "id": "m1",
                    "timestamp": "2026-03-10T00:00:00Z",
                    "scoring_preset_raw_value": "balanced",
                    "baseline_score": 70.0,
                    "adaptive_score": 77.0,
                    "baseline_accuracy": 0.8,
                    "adaptive_accuracy": 0.88,
                    "miss_delta": -1,
                    "time_delta": -1.0,
                },
            ],
        },
    )
    assert response.status_code == 200
    body = response.json()
    assert body["focus_area"] == "Balanced consistency"
    assert body["recommended_preset"] == "balanced"
    assert body["recommended_intensity"] == "standard"
    assert len(body["action_items"]) >= 3


# ---------------------------------------------------------------------------
# 8. Sync queue behavior: session upload, lookup, and deduplication
# ---------------------------------------------------------------------------
def test_sync_queue_upload_lookup_and_dedup(tmp_path: Path):
    main = load_main_module(tmp_path)
    client = TestClient(main.app)

    # Upload first session
    payload = dict(SAMPLE_SESSION_PAYLOAD)
    resp = client.post("/v1/sessions", json=payload)
    assert resp.status_code == 200
    assert resp.json()["accepted"] is True

    # Lookup sessions for user
    lookup = client.get("/v1/sessions/kim?limit=10")
    assert lookup.status_code == 200
    assert lookup.json()["count"] == 1
    assert lookup.json()["user_id"] == "kim"
    assert len(lookup.json()["items"]) == 1

    # Upload duplicate (INSERT OR REPLACE) -- same id, should not increase count
    resp2 = client.post("/v1/sessions", json=payload)
    assert resp2.status_code == 200
    lookup2 = client.get("/v1/sessions/kim?limit=10")
    assert lookup2.json()["count"] == 1

    # Upload second session with different id
    payload2 = dict(payload)
    payload2["id"] = "sess-002"
    payload2["adaptive_score"] = 85
    client.post("/v1/sessions", json=payload2)
    lookup3 = client.get("/v1/sessions/kim?limit=10")
    assert lookup3.json()["count"] == 2


# ---------------------------------------------------------------------------
# 9. Input validation rejects invalid payloads
# ---------------------------------------------------------------------------
def test_input_validation_rejects_invalid_payloads(tmp_path: Path):
    main = load_main_module(tmp_path)
    client = TestClient(main.app)

    # Empty user_id in coach plan
    resp = client.post(
        "/v1/coach/plan",
        json={"user_id": "", "recent_sessions": []},
    )
    assert resp.status_code == 422

    # Missing required fields in session upload
    resp2 = client.post(
        "/v1/sessions",
        json={"id": "x"},
    )
    assert resp2.status_code == 422

    # Out-of-range stability_index
    bad_payload = dict(SAMPLE_SESSION_PAYLOAD)
    bad_payload["stability_index"] = 5.0
    resp3 = client.post("/v1/sessions", json=bad_payload)
    assert resp3.status_code == 422

    # Out-of-range confidence_score
    bad_payload2 = dict(SAMPLE_SESSION_PAYLOAD)
    bad_payload2["confidence_score"] = -1.0
    resp4 = client.post("/v1/sessions", json=bad_payload2)
    assert resp4.status_code == 422


# ---------------------------------------------------------------------------
# 10. Structured error response format
# ---------------------------------------------------------------------------
def test_structured_error_response_format(tmp_path: Path):
    main = load_main_module(tmp_path, api_key="secret-key")
    client = TestClient(main.app)

    resp = client.post(
        "/v1/sessions",
        json=SAMPLE_SESSION_PAYLOAD,
    )
    assert resp.status_code == 401
    body = resp.json()
    assert "error" in body
    assert body["error"]["code"] == 401
    assert "message" in body["error"]
