from __future__ import annotations

import uuid
from datetime import UTC, date, datetime, timedelta

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from flexikeys.core.enums import EventType
from flexikeys.modules.progress.models import DailyActivity
from flexikeys.modules.sessions.models import InteractionEvent, LearningSession


async def run_daily_rollup(
    session: AsyncSession, rollup_date: date
) -> list[uuid.UUID]:
    """
    Aggregate interaction_events for rollup_date into daily_activity rows.
    Returns list of child_ids that had activity.
    Pure computation — caller must commit.
    """
    start_dt = datetime(
        rollup_date.year, rollup_date.month, rollup_date.day, 0, 0, 0, tzinfo=UTC
    )
    end_dt = start_dt + timedelta(days=1)

    # Fetch all events for the rollup date joined with session to get child_id
    stmt = (
        select(
            LearningSession.child_id,
            InteractionEvent.event_type,
            InteractionEvent.payload,
            InteractionEvent.occurred_at,
        )
        .join(LearningSession, InteractionEvent.session_id == LearningSession.id)
        .where(
            InteractionEvent.occurred_at >= start_dt,
            InteractionEvent.occurred_at < end_dt,
        )
    )
    result = await session.execute(stmt)
    rows = result.fetchall()

    # Group events by child_id
    from collections import defaultdict

    child_events: dict[uuid.UUID, list[dict]] = defaultdict(list)
    for child_id, event_type, payload, occurred_at in rows:
        child_events[child_id].append(
            {
                "event_type": event_type.value
                if hasattr(event_type, "value")
                else str(event_type),
                "payload": payload or {},
                "occurred_at": occurred_at,
            }
        )

    child_ids: list[uuid.UUID] = []

    for child_id, events in child_events.items():
        metrics = compute_daily_metrics(events)

        # Upsert daily_activity
        existing_result = await session.execute(
            select(DailyActivity).where(
                DailyActivity.child_id == child_id,
                DailyActivity.date == rollup_date,
            )
        )
        existing = existing_result.scalar_one_or_none()

        if existing is None:
            row = DailyActivity(
                id=uuid.uuid4(),
                child_id=child_id,
                date=rollup_date,
                seconds_active=metrics["seconds_active"],
                items_completed=metrics["items_completed"],
                avg_accuracy=metrics["avg_accuracy"],
            )
            session.add(row)
        else:
            existing.seconds_active = metrics["seconds_active"]
            existing.items_completed = metrics["items_completed"]
            existing.avg_accuracy = metrics["avg_accuracy"]

        child_ids.append(child_id)

    if child_ids:
        await session.flush()

    return child_ids


def compute_daily_metrics(events: list[dict]) -> dict:
    """
    Pure function: compute seconds_active, items_completed, avg_accuracy from events.

    Each event is a dict with at minimum:
      - "event_type": str (e.g. "item_completed", "keystroke")
      - "payload": dict (optional, may contain "correct": bool, "latency_ms": int)
      - "occurred_at": datetime (optional, used for time computation)
    """
    items_completed = 0
    correct_keystrokes = 0
    total_keystrokes = 0

    occurred_times: list[datetime] = []

    for event in events:
        event_type = event.get("event_type", "")
        payload = event.get("payload") or {}
        occurred_at = event.get("occurred_at")

        if occurred_at is not None:
            occurred_times.append(occurred_at)

        if event_type == EventType.item_completed.value:
            items_completed += 1
        elif event_type == EventType.keystroke.value:
            total_keystrokes += 1
            if payload.get("correct") is True:
                correct_keystrokes += 1

    # seconds_active: span from first to last event, min 0
    if len(occurred_times) >= 2:
        sorted_times = sorted(occurred_times)
        delta = sorted_times[-1] - sorted_times[0]
        seconds_active = max(0, int(delta.total_seconds()))
    elif items_completed > 0 or total_keystrokes > 0:
        # Heuristic: estimate 5s per interaction
        seconds_active = (items_completed + total_keystrokes) * 5
    else:
        seconds_active = 0

    avg_accuracy: float | None = None
    if total_keystrokes > 0:
        avg_accuracy = correct_keystrokes / total_keystrokes

    return {
        "items_completed": items_completed,
        "seconds_active": seconds_active,
        "avg_accuracy": avg_accuracy,
    }
