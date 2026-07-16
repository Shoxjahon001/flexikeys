from __future__ import annotations

import uuid
from datetime import date, timedelta

from sqlalchemy.ext.asyncio import AsyncSession

from flexikeys.modules.adaptive.models import AdaptationChange, SkillMastery
from flexikeys.modules.progress.models import DailyActivity

# Skills with p_known below this threshold are considered areas needing practice.
_PRACTICE_THRESHOLD = 0.7
# Skills with p_known at or above this threshold are considered mastered.
_MASTERY_THRESHOLD = 0.8


async def run_weekly_report(
    session: AsyncSession, child_id: uuid.UUID, week_start: date
) -> dict:
    """
    Build parent_weekly report payload for the 7 days from week_start.
    Returns the JSONB payload dict (not the Report ORM object).
    Pure computation — caller must commit if they save the Report row.
    """
    from sqlalchemy import and_, select

    week_end = week_start + timedelta(days=6)

    # Fetch daily activity for the week
    activity_result = await session.execute(
        select(DailyActivity)
        .where(
            and_(
                DailyActivity.child_id == child_id,
                DailyActivity.date >= week_start,
                DailyActivity.date <= week_end,
            )
        )
        .order_by(DailyActivity.date)
    )
    daily_rows_orm = list(activity_result.scalars().all())
    daily_rows = [
        {
            "date": r.date,
            "seconds_active": r.seconds_active,
            "items_completed": r.items_completed,
            "avg_accuracy": float(r.avg_accuracy) if r.avg_accuracy is not None else None,
        }
        for r in daily_rows_orm
    ]

    # Fetch skill mastery
    skill_result = await session.execute(
        select(SkillMastery).where(SkillMastery.child_id == child_id)
    )
    skill_rows = [
        {
            "skill_key": s.skill_key,
            "p_known": float(s.p_known),
            "attempts": s.attempts,
            "correct": s.correct,
        }
        for s in skill_result.scalars().all()
    ]

    # Fetch adaptation changes during the week
    from datetime import UTC, datetime

    week_start_dt = datetime(
        week_start.year, week_start.month, week_start.day, tzinfo=UTC
    )
    week_end_dt = datetime(
        week_end.year, week_end.month, week_end.day, 23, 59, 59, tzinfo=UTC
    )
    adaptation_result = await session.execute(
        select(AdaptationChange)
        .where(
            and_(
                AdaptationChange.child_id == child_id,
                AdaptationChange.changed_at >= week_start_dt,
                AdaptationChange.changed_at <= week_end_dt,
            )
        )
        .order_by(AdaptationChange.changed_at)
    )
    adaptation_rows = [
        {
            "changed_at": c.changed_at.isoformat(),
            "param": c.param,
            "reason_code": c.reason_code.value
            if hasattr(c.reason_code, "value")
            else str(c.reason_code),
        }
        for c in adaptation_result.scalars().all()
    ]

    return compute_weekly_payload(daily_rows, skill_rows, adaptation_rows)


def compute_weekly_payload(
    daily_rows: list[dict],
    skill_rows: list[dict],
    adaptation_rows: list[dict],
) -> dict:
    """
    Pure function for testability.

    daily_rows: [{date, seconds_active, items_completed, avg_accuracy}, ...]
    skill_rows: [{skill_key, p_known, ...}, ...]
    adaptation_rows: [{changed_at, param, reason_code}, ...]

    Returns:
      {time_spent_min, items_completed, streak_days, accuracy_trend,
       areas_needing_practice, top_mastered_skills, adaptation_summaries}
    """
    # Total time in minutes
    total_seconds = sum(r.get("seconds_active", 0) or 0 for r in daily_rows)
    time_spent_min = round(total_seconds / 60.0, 2)

    # Total items completed
    items_completed = sum(r.get("items_completed", 0) or 0 for r in daily_rows)

    # Streak: consecutive active days from the last day backward
    active_dates = sorted(
        {r["date"] for r in daily_rows if (r.get("seconds_active") or 0) > 0},
        reverse=True,
    )
    if not active_dates:
        streak_days = 0
    else:
        streak_days = 1
        for i in range(1, len(active_dates)):
            if active_dates[i] == active_dates[i - 1] - timedelta(days=1):
                streak_days += 1
            else:
                break

    # Accuracy trend: average of non-None daily accuracies
    accuracies = [
        r["avg_accuracy"]
        for r in daily_rows
        if r.get("avg_accuracy") is not None
    ]
    accuracy_trend: float | None = (
        round(sum(accuracies) / len(accuracies), 4) if accuracies else None
    )

    # Areas needing practice: skills with p_known < threshold
    areas_needing_practice = [
        {"skill_key": s["skill_key"], "p_known": s["p_known"]}
        for s in skill_rows
        if s.get("p_known", 1.0) < _PRACTICE_THRESHOLD
    ]
    areas_needing_practice.sort(key=lambda x: x["p_known"])

    # Top mastered skills: skills with p_known >= threshold, top 5
    top_mastered_skills = sorted(
        [
            {"skill_key": s["skill_key"], "p_known": s["p_known"]}
            for s in skill_rows
            if s.get("p_known", 0.0) >= _MASTERY_THRESHOLD
        ],
        key=lambda x: x["p_known"],
        reverse=True,
    )[:5]

    # Adaptation summaries
    adaptation_summaries = [
        {
            "changed_at": r.get("changed_at"),
            "param": r.get("param"),
            "reason_code": r.get("reason_code"),
        }
        for r in adaptation_rows
    ]

    return {
        "time_spent_min": time_spent_min,
        "items_completed": items_completed,
        "streak_days": streak_days,
        "accuracy_trend": accuracy_trend,
        "areas_needing_practice": areas_needing_practice,
        "top_mastered_skills": top_mastered_skills,
        "adaptation_summaries": adaptation_summaries,
    }
