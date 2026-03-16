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
    evidence_basis = [
        f"Recent sessions considered: {len(recent_sessions)}",
        f"Recent score delta baseline: {avg_delta_recent:.2f}",
        f"Lifetime average delta: {aggregate.avg_delta:.2f}",
        f"Completed session count: {aggregate.count}",
    ]
    alignment_with_local = (
        "Remote recommendation aligns with your recent local trend and keeps the suggested preset within your observed confidence band."
        if recent_sessions
        else "Remote recommendation is using aggregate-only history because there are not enough recent local sessions yet."
    )

    return {
        "generated_at": datetime.now(tz=timezone.utc),
        "focus_area": focus_area,
        "rationale": rationale,
        "recommended_preset": recommended_preset,
        "recommended_intensity": recommended_intensity,
        "target_score_delta": round(max(6.0, avg_delta_recent + 2.0), 2),
        "target_sessions_per_week": 4 if aggregate.count >= 3 else 5,
        "confidence": round(confidence, 3),
        "evidence_basis": evidence_basis,
        "alignment_with_local": alignment_with_local,
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


def build_progress_report(
    user_id: str,
    recent_sessions: list[dict],
    coach_plan: dict,
    benchmark: dict,
) -> dict:
    recent_delta = (
        sum(s["adaptive_score"] - s["baseline_score"] for s in recent_sessions) / len(recent_sessions)
        if recent_sessions
        else 0.0
    )
    weekly_target = (
        int(recent_sessions[0].get("weekly_goal_target", 4))
        if recent_sessions
        else int(coach_plan.get("target_sessions_per_week", 4) or 4)
    )
    sessions_completed = len(recent_sessions)
    adherence_pct = round((sessions_completed / max(weekly_target, 1)) * 100, 1)
    streak_days = sessions_completed
    target_delta = float(coach_plan.get("target_score_delta", 0.0) or 0.0)
    delta_gap = round(recent_delta - target_delta, 2)

    review_notes = [
        "Weekly cadence should be interpreted alongside local session freshness.",
        "Coach delta compares current average improvement against the active remote target.",
        "Use this report as a reviewer/clinician handoff snapshot, not a replacement for raw session playback.",
    ]

    copy_text = "\n".join(
        [
            "SteadyTap progress report",
            f"User: {user_id}",
            f"Weekly cadence: {sessions_completed}/{weekly_target} sessions ({adherence_pct}%)",
            f"Streak: {streak_days} day(s)",
            f"Current average delta: {recent_delta:.2f}",
            f"Coach target delta: {target_delta:.2f}",
            f"Delta gap: {delta_gap:+.2f}",
            f"Benchmark percentile: {benchmark.get('percentile', 0)}",
            f"Coach focus: {coach_plan.get('focus_area', '-')}",
        ]
    )

    return {
        "generated_at": datetime.now(tz=timezone.utc),
        "user_id": user_id,
        "weekly_cadence": {
            "sessions_completed": sessions_completed,
            "target_sessions": weekly_target,
            "adherence_pct": adherence_pct,
            "streak_days": streak_days,
        },
        "benchmark": {
            "percentile": int(benchmark.get("percentile", 0) or 0),
            "cohort_label": benchmark.get("cohort_label", "Motor accessibility learners"),
            "average_score_delta": float(benchmark.get("average_score_delta", 0.0) or 0.0),
        },
        "coach_delta": {
            "current_average_delta": round(recent_delta, 2),
            "target_score_delta": round(target_delta, 2),
            "delta_gap": delta_gap,
            "recommended_intensity": coach_plan.get("recommended_intensity", "standard"),
            "focus_area": coach_plan.get("focus_area", ""),
        },
        "review_notes": review_notes,
        "copy_text": copy_text,
    }
