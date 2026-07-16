"""SM-2 spaced repetition unit tests."""
from __future__ import annotations

from datetime import UTC, datetime, timedelta

import pytest

from flexikeys.modules.adaptive.repetition import (
    EASE_INIT,
    EASE_MIN,
    FIRST_INTERVAL_DAYS,
    LAPSE_INTERVAL_DAYS,
    SECOND_INTERVAL_DAYS,
    next_due_at,
    select_due_items,
    sm2_update,
)


class TestSm2Update:
    def test_step1_correct(self) -> None:
        interval, ease, lapses = sm2_update(
            FIRST_INTERVAL_DAYS, EASE_INIT, 0, correct=True
        )
        assert interval == SECOND_INTERVAL_DAYS
        assert abs(ease - 2.60) < 0.001
        assert lapses == 0

    def test_step2_correct(self) -> None:
        interval, ease, lapses = sm2_update(SECOND_INTERVAL_DAYS, 2.60, 0, correct=True)
        # round(6 * 2.60) = 16
        assert interval == 16
        assert abs(ease - 2.70) < 0.001
        assert lapses == 0

    def test_step3_incorrect(self) -> None:
        interval, ease, lapses = sm2_update(16, 2.70, 0, correct=False)
        assert interval == LAPSE_INTERVAL_DAYS
        assert abs(ease - 2.50) < 0.001
        assert lapses == 1

    def test_ease_floor(self) -> None:
        _, ease, _ = sm2_update(10, EASE_MIN + 0.05, 3, correct=False)
        assert ease >= EASE_MIN

    def test_first_correct_returns_second_interval(self) -> None:
        interval, _, _ = sm2_update(FIRST_INTERVAL_DAYS, EASE_INIT, 0, correct=True)
        assert interval == SECOND_INTERVAL_DAYS

    def test_lapse_resets_interval(self) -> None:
        interval, _, lapses = sm2_update(30, 2.5, 0, correct=False)
        assert interval == LAPSE_INTERVAL_DAYS
        assert lapses == 1

    def test_multiple_lapses_accumulate(self) -> None:
        _, _, lapses = sm2_update(1, 1.35, 2, correct=False)
        assert lapses == 3


class TestNextDueAt:
    def test_1_day_from_now(self) -> None:
        now = datetime.now(UTC)
        due = next_due_at(1, from_dt=now)
        delta = due - now
        assert 86300 < delta.total_seconds() < 86500  # ≈ 1 day

    def test_7_days(self) -> None:
        now = datetime.now(UTC)
        due = next_due_at(7, from_dt=now)
        delta = due - now
        assert abs(delta.days - 7) <= 1


class TestSelectDueItems:
    def _queue(self, items: list[tuple[str, datetime]]) -> list[dict]:
        return [{"skill_key": k, "due_at": d} for k, d in items]

    def test_returns_overdue(self) -> None:
        now = datetime.now(UTC)
        past = now - timedelta(days=1)
        future = now + timedelta(days=1)
        queue = self._queue([("a", past), ("b", future)])
        result = select_due_items(queue, now=now)
        assert result == ["a"]

    def test_respects_max_due(self) -> None:
        now = datetime.now(UTC)
        past = now - timedelta(hours=1)
        queue = self._queue([(str(i), past) for i in range(20)])
        result = select_due_items(queue, now=now, max_due=5)
        assert len(result) == 5

    def test_empty_queue(self) -> None:
        assert select_due_items([], now=datetime.now(UTC)) == []

    def test_no_due_items(self) -> None:
        now = datetime.now(UTC)
        future = now + timedelta(days=5)
        queue = self._queue([("a", future)])
        assert select_due_items(queue, now=now) == []
