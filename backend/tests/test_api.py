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
    schema = client.get("/v1/schema/coach-report")

    assert health.status_code == 200
    assert health.json()["session_count"] == 0
    assert health.json()["readiness_contract"] == "steadytap-service-brief-v1"
    assert health.json()["report_contract"]["schema"] == "steadytap-coach-report-v1"
    assert health.json()["links"]["runtime_brief"] == "/v1/runtime-brief"

    assert meta.status_code == 200
    body = meta.json()
    assert body["service"] == "steadytap-backend"
    assert body["auth"]["api_key_required"] is False
    assert body["storage"]["db_path"].endswith("steadytap.sqlite")
    assert "/v1/meta" in body["routes"]
    assert "/v1/runtime-brief" in body["routes"]
    assert body["readiness_contract"] == "steadytap-service-brief-v1"
    assert body["report_contract"]["schema"] == "steadytap-coach-report-v1"

    assert brief.status_code == 200
    brief_body = brief.json()
    assert brief_body["readiness_contract"] == "steadytap-service-brief-v1"
    assert brief_body["report_contract"]["schema"] == "steadytap-coach-report-v1"
    assert brief_body["evidence_counts"]["service_routes"] >= 8

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
