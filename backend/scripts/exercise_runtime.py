from __future__ import annotations

import json
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

os.environ.setdefault("STEADYTAP_DB_PATH", str(ROOT / "data" / "exercise.sqlite"))
os.environ.setdefault(
    "STEADYTAP_RUNTIME_STORE_PATH",
    str(ROOT / "data" / "runtime-events.exercise.jsonl"),
)

from fastapi.testclient import TestClient  # noqa: E402

from app.main import app  # noqa: E402


def _headers() -> dict[str, str]:
    token = str(os.getenv("STEADYTAP_API_KEY", "")).strip()
    if not token:
        return {}
    return {"Authorization": f"Bearer {token}"}


def main() -> None:
    headers = _headers()
    payload = {
        "id": "exercise-session-1",
        "user_id": "demo-user",
        "timestamp": "2026-03-09T00:00:00Z",
        "scoring_preset_raw_value": "standard",
        "challenge_intensity_raw_value": "standard",
        "weekly_goal_target": 4,
        "baseline_score": 0.62,
        "adaptive_score": 0.75,
        "miss_delta": -2,
        "time_delta": -0.12,
        "stability_index": 0.84,
        "confidence_score": 0.87,
        "button_scale": 1.05,
        "hold_duration": 0.32,
        "swipe_threshold": 0.44,
    }
    with TestClient(app) as client:
        client.get("/v1/health").raise_for_status()
        client.post("/v1/sessions", json=payload, headers=headers).raise_for_status()
        client.post(
            "/v1/coach/plan",
            json={"user_id": "demo-user", "recent_sessions": []},
            headers=headers,
        ).raise_for_status()
        client.post(
            "/v1/benchmarks",
            json={"user_id": "demo-user", "recent_sessions": []},
            headers=headers,
        ).raise_for_status()
        scorecard = client.get("/v1/runtime-scorecard")
        scorecard.raise_for_status()
        body = scorecard.json()

    print(
        json.dumps(
            {
                "contract": body["readiness_contract"],
                "summary": body["summary"],
                "persistence": body["runtime"]["persistence"],
            },
            indent=2,
        )
    )


if __name__ == "__main__":
    main()
