from __future__ import annotations

import importlib
import os
import sys
from pathlib import Path

from fastapi.testclient import TestClient


def load_main_module(tmp_path: Path, api_key: str = ""):
    os.environ["STEADYTAP_DB_PATH"] = str(tmp_path / "steadytap.sqlite")
    if api_key:
        os.environ["STEADYTAP_API_KEY"] = api_key
    else:
        os.environ.pop("STEADYTAP_API_KEY", None)

    sys.modules.pop("app.main", None)
    module = importlib.import_module("app.main")
    return importlib.reload(module)


def test_health_and_meta_report_runtime_state(tmp_path: Path):
    main = load_main_module(tmp_path)
    client = TestClient(main.app)

    health = client.get("/v1/health")
    meta = client.get("/v1/meta")
    brief = client.get("/v1/runtime-brief")
    review_pack = client.get("/v1/review-pack")
    schema = client.get("/v1/schema/coach-report")

    assert health.status_code == 200
    assert health.json()["session_count"] == 0
    assert health.json()["readiness_contract"] == "steadytap-service-brief-v1"
    assert health.json()["report_contract"]["schema"] == "steadytap-coach-report-v1"
    assert health.json()["links"]["runtime_brief"] == "/v1/runtime-brief"
    assert health.json()["links"]["review_pack"] == "/v1/review-pack"

    assert meta.status_code == 200
    body = meta.json()
    assert body["service"] == "steadytap-backend"
    assert body["auth"]["api_key_required"] is False
    assert body["storage"]["db_path"].endswith("steadytap.sqlite")
    assert "/v1/meta" in body["routes"]
    assert "/v1/runtime-brief" in body["routes"]
    assert "/v1/review-pack" in body["routes"]
    assert body["readiness_contract"] == "steadytap-service-brief-v1"
    assert body["report_contract"]["schema"] == "steadytap-coach-report-v1"
    assert "review-pack-surface" in body["capabilities"]

    assert brief.status_code == 200
    brief_body = brief.json()
    assert brief_body["readiness_contract"] == "steadytap-service-brief-v1"
    assert brief_body["report_contract"]["schema"] == "steadytap-coach-report-v1"
    assert brief_body["evidence_counts"]["service_routes"] >= 8

    assert review_pack.status_code == 200
    review_pack_body = review_pack.json()
    assert review_pack_body["readiness_contract"] == "steadytap-review-pack-v1"
    assert review_pack_body["proof_bundle"]["auth_mode"] in {"open-review", "bearer-required"}
    assert "/v1/review-pack" in review_pack_body["proof_bundle"]["review_routes"]
    assert isinstance(review_pack_body["review_sequence"], list)

    assert schema.status_code == 200
    schema_body = schema.json()
    assert schema_body["schema"] == "steadytap-coach-report-v1"
    assert "action_items" in schema_body["required_sections"]


def test_protected_routes_require_bearer_token_when_api_key_is_configured(tmp_path: Path):
    main = load_main_module(tmp_path, api_key="top-secret")
    client = TestClient(main.app)

    unauthorized = client.post("/v1/benchmarks", json={"user_id": "kim", "recent_sessions": []})
    authorized = client.get("/v1/meta")

    assert unauthorized.status_code == 401
    assert authorized.status_code == 200
    assert authorized.json()["auth"]["api_key_required"] is True
