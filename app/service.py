from __future__ import annotations

from datetime import datetime, timezone

from .db import UserAggregate


def clamp(value: float, min_value: float, max_value: float) -> float:
    return max(min_value, min(max_value, value))


def build_coach_plan(
    user_id: str,
    recent_sessions: list[dict],
    aggregate: UserAggregate,
) -> dict:
    del user_id

    if recent_sessions:
        avg_delta_recent = sum(s["adaptive_score"] - s["baseline_score"] for s in recent_sessions) / len(recent_sessions)
    else:
        avg_delta_recent = aggregate.avg_delta

    if avg_delta_recent < 4.5:
        focus_area = "Precision stabilization"
        recommended_preset = "missFocused"
        recommended_intensity = "supportive"
        rationale = "Recent gains are modest; prioritize fewer misses and accidental interactions."
        action_items = [
            "Use Mistake-first preset for the next 3 sessions.",
            "Set intensity to Supportive for stronger touch filtering.",
            "Keep accidental touches under 2 per run.",
            "Recalibrate if confidence remains low.",
        ]
    elif avg_delta_recent < 9.0:
        focus_area = "Balanced consistency"
        recommended_preset = "balanced"
        recommended_intensity = "standard"
        rationale = "You are improving steadily. Keep balanced pacing while preserving precision."
        action_items = [
            "Use Balanced preset for at least 4 sessions this week.",
            "Run sessions in Standard intensity.",
            "Target +1.5 score delta over your recent average.",
            "Review hold duration if misses rise.",
        ]
    else:
        focus_area = "Adaptive speed confidence"
        recommended_preset = "speedFocused"
        recommended_intensity = "advanced"
        rationale = "Improvement trend is strong. Increase speed while maintaining low mistake rates."
        action_items = [
            "Use Speed-first preset for one challenge per day.",
            "Run sessions in Advanced intensity to maintain challenge.",
            "Keep miss delta positive while reducing completion time.",
            "Run a recalibration every 5 sessions.",
        ]

    confidence = clamp(0.58 + (min(aggregate.count, 20) / 100) + (abs(avg_delta_recent) / 40), 0.45, 0.95)

    return {
        "generated_at": datetime.now(tz=timezone.utc),
        "focus_area": focus_area,
        "rationale": rationale,
        "recommended_preset": recommended_preset,
        "recommended_intensity": recommended_intensity,
        "target_score_delta": round(max(6.0, avg_delta_recent + 2.0), 2),
        "target_sessions_per_week": 4 if aggregate.count >= 3 else 5,
        "confidence": round(confidence, 3),
        "action_items": action_items,
    }


def build_benchmark(
    user_id: str,
    recent_sessions: list[dict],
    aggregate: UserAggregate,
    global_average_delta: float,
) -> dict:
    del user_id

    if recent_sessions:
        avg_delta_recent = sum(s["adaptive_score"] - s["baseline_score"] for s in recent_sessions) / len(recent_sessions)
    else:
        avg_delta_recent = aggregate.avg_delta

    baseline = 55 + ((avg_delta_recent - global_average_delta) * 4.2)
    percentile = int(clamp(round(baseline), 20, 99))

    return {
        "generated_at": datetime.now(tz=timezone.utc),
        "cohort_label": "Motor accessibility learners",
        "percentile": percentile,
        "average_score_delta": round(global_average_delta or 6.0, 2),
    }
