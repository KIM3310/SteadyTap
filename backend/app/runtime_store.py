from __future__ import annotations

import json
import os
from collections import Counter, deque
from datetime import datetime, timezone
from pathlib import Path
from threading import Lock
from typing import Any

STORE_PATH = Path(os.getenv("STEADYTAP_RUNTIME_STORE_PATH", "./data/runtime-events.jsonl"))
_LOCK = Lock()
_EVENT_COUNTS: Counter[str] = Counter()
_ROUTE_COUNTS: Counter[str] = Counter()
_RECENT_EVENTS: deque[dict[str, Any]] = deque(maxlen=20)
_LOADED = False


def _ensure_parent() -> None:
    STORE_PATH.parent.mkdir(parents=True, exist_ok=True)


def _load_if_needed() -> None:
    global _LOADED
    if _LOADED:
        return
    with _LOCK:
        if _LOADED:
            return
        if STORE_PATH.exists():
            for line in STORE_PATH.read_text(encoding="utf-8").splitlines():
                if not line.strip():
                    continue
                try:
                    event = json.loads(line)
                except json.JSONDecodeError:
                    continue
                _EVENT_COUNTS[str(event.get("event_type") or "unknown")] += 1
                _ROUTE_COUNTS[str(event.get("route") or "unknown")] += 1
                _RECENT_EVENTS.append(event)
        _LOADED = True


def record_runtime_event(
    *,
    event_type: str,
    route: str,
    outcome: str = "ok",
    user_id: str | None = None,
    details: dict[str, Any] | None = None,
) -> None:
    _load_if_needed()
    event = {
        "ts": datetime.now(tz=timezone.utc).isoformat(),
        "event_type": event_type,
        "route": route,
        "outcome": outcome,
        "user_id": user_id,
        "details": details or {},
    }
    payload = json.dumps(event, ensure_ascii=True)

    with _LOCK:
        _ensure_parent()
        with STORE_PATH.open("a", encoding="utf-8") as handle:
            handle.write(f"{payload}\n")
        _EVENT_COUNTS[event_type] += 1
        _ROUTE_COUNTS[route] += 1
        _RECENT_EVENTS.append(event)


def build_runtime_summary() -> dict[str, Any]:
    _load_if_needed()
    with _LOCK:
        top_routes = [
            {"route": route, "count": count}
            for route, count in _ROUTE_COUNTS.most_common(5)
        ]
        event_counts = dict(_EVENT_COUNTS)
        recent_events = list(_RECENT_EVENTS)[-5:]
    return {
        "store_path": str(STORE_PATH),
        "event_count": int(sum(event_counts.values())),
        "event_type_counts": event_counts,
        "top_routes": top_routes,
        "recent_events": recent_events,
    }
