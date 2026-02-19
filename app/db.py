from __future__ import annotations

import sqlite3
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from threading import Lock


@dataclass
class UserAggregate:
    count: int
    avg_delta: float
    avg_miss_delta: float


class Database:
    def __init__(self, db_path: str) -> None:
        self._path = Path(db_path)
        self._path.parent.mkdir(parents=True, exist_ok=True)
        self._lock = Lock()
        self._initialize()

    def _connect(self) -> sqlite3.Connection:
        conn = sqlite3.connect(self._path)
        conn.row_factory = sqlite3.Row
        return conn

    def _initialize(self) -> None:
        with self._connect() as conn:
            conn.execute(
                """
                CREATE TABLE IF NOT EXISTS sessions (
                    id TEXT PRIMARY KEY,
                    user_id TEXT NOT NULL,
                    ts TEXT NOT NULL,
                    scoring_preset TEXT NOT NULL,
                    challenge_intensity TEXT NOT NULL DEFAULT 'standard',
                    weekly_goal_target INTEGER NOT NULL DEFAULT 4,
                    baseline_score REAL NOT NULL,
                    adaptive_score REAL NOT NULL,
                    miss_delta INTEGER NOT NULL,
                    time_delta REAL NOT NULL,
                    stability_index REAL NOT NULL,
                    confidence_score REAL NOT NULL,
                    button_scale REAL NOT NULL,
                    hold_duration REAL NOT NULL,
                    swipe_threshold REAL NOT NULL,
                    created_at TEXT NOT NULL
                )
                """
            )
            conn.execute(
                "CREATE INDEX IF NOT EXISTS idx_sessions_user_ts ON sessions(user_id, ts DESC)"
            )
            self._ensure_column(
                conn,
                table="sessions",
                column="challenge_intensity",
                definition="TEXT NOT NULL DEFAULT 'standard'",
            )
            self._ensure_column(
                conn,
                table="sessions",
                column="weekly_goal_target",
                definition="INTEGER NOT NULL DEFAULT 4",
            )
            conn.commit()

    def _ensure_column(
        self,
        conn: sqlite3.Connection,
        table: str,
        column: str,
        definition: str,
    ) -> None:
        columns = conn.execute(f"PRAGMA table_info({table})").fetchall()
        if any(row["name"] == column for row in columns):
            return
        conn.execute(f"ALTER TABLE {table} ADD COLUMN {column} {definition}")

    def insert_session(self, payload: dict) -> None:
        now = datetime.now(tz=timezone.utc).isoformat()
        intensity = payload.get("challenge_intensity_raw_value") or "standard"
        weekly_goal_raw = payload.get("weekly_goal_target")
        weekly_goal = int(weekly_goal_raw) if weekly_goal_raw is not None else 4

        with self._lock:
            with self._connect() as conn:
                conn.execute(
                    """
                    INSERT OR REPLACE INTO sessions (
                        id, user_id, ts, scoring_preset, challenge_intensity, weekly_goal_target, baseline_score, adaptive_score,
                        miss_delta, time_delta, stability_index, confidence_score,
                        button_scale, hold_duration, swipe_threshold, created_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    (
                        payload["id"],
                        payload["user_id"],
                        payload["timestamp"],
                        payload["scoring_preset_raw_value"],
                        intensity,
                        weekly_goal,
                        payload["baseline_score"],
                        payload["adaptive_score"],
                        payload["miss_delta"],
                        payload["time_delta"],
                        payload["stability_index"],
                        payload["confidence_score"],
                        payload["button_scale"],
                        payload["hold_duration"],
                        payload["swipe_threshold"],
                        now,
                    ),
                )
                conn.commit()

    def count_sessions(self) -> int:
        with self._connect() as conn:
            row = conn.execute("SELECT COUNT(*) AS c FROM sessions").fetchone()
            return int(row["c"]) if row else 0

    def list_sessions(self, user_id: str, limit: int = 20) -> list[dict]:
        with self._connect() as conn:
            rows = conn.execute(
                """
                SELECT id, user_id, ts, scoring_preset, challenge_intensity, weekly_goal_target, baseline_score, adaptive_score,
                       miss_delta, time_delta, stability_index, confidence_score,
                       button_scale, hold_duration, swipe_threshold
                FROM sessions
                WHERE user_id = ?
                ORDER BY ts DESC
                LIMIT ?
                """,
                (user_id, limit),
            ).fetchall()

        return [dict(row) for row in rows]

    def user_aggregate(self, user_id: str) -> UserAggregate:
        with self._connect() as conn:
            row = conn.execute(
                """
                SELECT
                    COUNT(*) AS c,
                    AVG(adaptive_score - baseline_score) AS avg_delta,
                    AVG(miss_delta) AS avg_miss_delta
                FROM sessions
                WHERE user_id = ?
                """,
                (user_id,),
            ).fetchone()

        if not row:
            return UserAggregate(count=0, avg_delta=0.0, avg_miss_delta=0.0)

        return UserAggregate(
            count=int(row["c"] or 0),
            avg_delta=float(row["avg_delta"] or 0.0),
            avg_miss_delta=float(row["avg_miss_delta"] or 0.0),
        )

    def global_average_delta(self) -> float:
        with self._connect() as conn:
            row = conn.execute(
                "SELECT AVG(adaptive_score - baseline_score) AS avg_delta FROM sessions"
            ).fetchone()
        return float(row["avg_delta"] or 0.0) if row else 0.0
