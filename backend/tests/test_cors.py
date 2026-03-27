from __future__ import annotations

import importlib
import sys
from pathlib import Path

from fastapi.testclient import TestClient

BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))


def load_main_module(tmp_path: Path):
    import os

    os.environ["STEADYTAP_DB_PATH"] = str(tmp_path / "steadytap.sqlite")
    os.environ["STEADYTAP_RUNTIME_STORE_PATH"] = str(tmp_path / "runtime-events.jsonl")
    os.environ.pop("STEADYTAP_API_KEY", None)
    sys.modules.pop("app.main", None)
    sys.modules.pop("app.runtime_store", None)
    module = importlib.import_module("app.main")
    return importlib.reload(module)


def test_backend_cors_allows_known_frontend_origin(tmp_path):
    main = load_main_module(tmp_path)
    client = TestClient(main.app)

    response = client.options(
        "/v1/health",
        headers={
            "Origin": "https://steadytap.pages.dev",
            "Access-Control-Request-Method": "GET",
        },
    )

    assert response.status_code == 200
    assert response.headers["access-control-allow-origin"] == "https://steadytap.pages.dev"


def test_backend_cors_omits_unknown_origin(tmp_path):
    main = load_main_module(tmp_path)
    client = TestClient(main.app)

    response = client.options(
        "/v1/health",
        headers={
            "Origin": "https://unexpected.example",
            "Access-Control-Request-Method": "GET",
        },
    )

    assert response.status_code == 400
    assert "access-control-allow-origin" not in response.headers
