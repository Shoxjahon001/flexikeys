"""
Parent service unit tests — no database required.

Tests exercise: ExportDataOut field constraints, streak computation logic.
"""
from __future__ import annotations

import types
from datetime import date

from flexikeys.modules.parent.schemas import ExportDataOut
from flexikeys.modules.parent.service import _compute_streak

# ── Schema field constraints ──────────────────────────────────────────────────


def test_export_data_excludes_email_field() -> None:
    """ExportDataOut must not expose parent email or parent_id."""
    fields = ExportDataOut.model_fields
    assert "email" not in fields
    assert "parent_id" not in fields


def test_export_data_excludes_birth_year_field() -> None:
    fields = ExportDataOut.model_fields
    assert "birth_year" not in fields


def test_export_data_has_required_safe_fields() -> None:
    """ExportDataOut must have child_id, display_name, learning_language."""
    fields = ExportDataOut.model_fields
    assert "child_id" in fields
    assert "display_name" in fields
    assert "learning_language" in fields


# ── Streak computation ────────────────────────────────────────────────────────


def _make_record(day: date, seconds_active: int = 300) -> object:
    """Create a minimal duck-typed record for streak computation."""
    return types.SimpleNamespace(date=day, seconds_active=seconds_active)


def test_streak_is_zero_when_no_activity() -> None:
    assert _compute_streak([]) == 0


def test_streak_is_zero_when_all_inactive() -> None:
    records = [
        _make_record(date(2024, 1, 1), seconds_active=0),
        _make_record(date(2024, 1, 2), seconds_active=0),
    ]
    assert _compute_streak(records) == 0


def test_streak_counts_consecutive_days() -> None:
    """5 consecutive active days → streak = 5."""
    records = [_make_record(date(2024, 1, 1 + i)) for i in range(5)]
    assert _compute_streak(records) == 5


def test_streak_breaks_on_gap() -> None:
    """Activity on days 1, 2, then skip day 3, then days 4, 5 → streak from the end = 2."""
    records = [
        _make_record(date(2024, 1, 1)),
        _make_record(date(2024, 1, 2)),
        # day 3 missing
        _make_record(date(2024, 1, 4)),
        _make_record(date(2024, 1, 5)),
    ]
    # Streak is counted from the most recent date backward
    assert _compute_streak(records) == 2


def test_streak_single_day() -> None:
    records = [_make_record(date(2024, 6, 15))]
    assert _compute_streak(records) == 1


def test_streak_ignores_inactive_days() -> None:
    """Inactive days (seconds_active=0) do not count in the streak."""
    records = [
        _make_record(date(2024, 1, 1), seconds_active=300),
        _make_record(date(2024, 1, 2), seconds_active=0),   # inactive — breaks streak
        _make_record(date(2024, 1, 3), seconds_active=400),
        _make_record(date(2024, 1, 4), seconds_active=200),
    ]
    # Most recent run: days 3 and 4 are active and consecutive → streak = 2
    assert _compute_streak(records) == 2


def test_streak_unsorted_input() -> None:
    """Streak computation must handle unsorted input correctly."""
    records = [
        _make_record(date(2024, 3, 5)),
        _make_record(date(2024, 3, 3)),
        _make_record(date(2024, 3, 4)),
    ]
    assert _compute_streak(records) == 3
