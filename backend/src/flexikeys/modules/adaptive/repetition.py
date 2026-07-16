"""
SM-2-derived spaced repetition scheduler.

We use a simplified binary quality model:
    correct  → quality 5 equivalent
    incorrect → lapse (quality < 3)

Rules
-----
Correct:
    - interval == 0  → new_interval = FIRST_INTERVAL_DAYS  (1)
    - interval == 1  → new_interval = SECOND_INTERVAL_DAYS (6)
    - otherwise      → new_interval = round(interval * ease)
    - ease           = min(5.0, ease + EASE_CORRECT_BONUS)

Incorrect (lapse):
    - new_interval   = LAPSE_INTERVAL_DAYS (1)
    - ease           = max(EASE_MIN, ease - EASE_LAPSE_PENALTY)
    - lapses        += 1

Hand-computed test fixture
--------------------------
Start: interval=1, ease=2.50, lapses=0

Step 1 — correct:
    new_interval = 6  (second-correct rule)
    new_ease = 2.60

Step 2 — correct:
    new_interval = round(6 * 2.60) = 16
    new_ease = 2.70

Step 3 — incorrect:
    new_interval = 1
    new_ease = max(1.30, 2.70 - 0.20) = 2.50
    lapses = 1
"""
from __future__ import annotations

from datetime import UTC, datetime, timedelta

EASE_INIT: float = 2.50
EASE_MIN: float = 1.30
EASE_CORRECT_BONUS: float = 0.10
EASE_LAPSE_PENALTY: float = 0.20
LAPSE_INTERVAL_DAYS: int = 1
FIRST_INTERVAL_DAYS: int = 1
SECOND_INTERVAL_DAYS: int = 6


def sm2_update(
    interval_days: int,
    ease: float,
    lapses: int,
    correct: bool,
) -> tuple[int, float, int]:
    """
    One SM-2 update step.

    Returns
    -------
    (new_interval_days, new_ease, new_lapses)
    """
    if correct:
        if interval_days == 0:
            new_interval = FIRST_INTERVAL_DAYS
        elif interval_days <= 1:
            new_interval = SECOND_INTERVAL_DAYS
        else:
            new_interval = round(interval_days * ease)
        new_ease = min(5.0, ease + EASE_CORRECT_BONUS)
        return new_interval, new_ease, lapses
    else:
        new_ease = max(EASE_MIN, ease - EASE_LAPSE_PENALTY)
        return LAPSE_INTERVAL_DAYS, new_ease, lapses + 1


def next_due_at(interval_days: int, from_dt: datetime | None = None) -> datetime:
    """Compute absolute due datetime from now (or from_dt) + interval."""
    base = from_dt or datetime.now(UTC)
    return base + timedelta(days=interval_days)


def select_due_items(
    queue: list[dict],
    now: datetime | None = None,
    max_due: int = 10,
) -> list[str]:
    """
    Return skill_keys due for review (due_at <= now), sorted oldest-first.
    Each dict in queue must have {skill_key: str, due_at: datetime}.
    """
    now = now or datetime.now(UTC)
    due = [item for item in queue if item["due_at"] <= now]
    due.sort(key=lambda x: x["due_at"])
    return [item["skill_key"] for item in due[:max_due]]
