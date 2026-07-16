"""
Worker pure-function unit tests — no database required.

Tests exercise compute_daily_metrics and compute_weekly_payload directly.
"""
from __future__ import annotations

from datetime import date

import pytest

from flexikeys.workers.daily_rollup import compute_daily_metrics
from flexikeys.workers.weekly_report import compute_weekly_payload

# ── compute_daily_metrics ─────────────────────────────────────────────────────


def test_daily_rollup_counts_items() -> None:
    events = [
        {"event_type": "item_completed", "payload": {}},
        {"event_type": "keystroke", "payload": {"correct": True}},
        {"event_type": "item_completed", "payload": {}},
    ]
    result = compute_daily_metrics(events)
    assert result["items_completed"] == 2


def test_daily_rollup_computes_avg_accuracy() -> None:
    events = [
        {"event_type": "keystroke", "payload": {"correct": True}},
        {"event_type": "keystroke", "payload": {"correct": True}},
        {"event_type": "keystroke", "payload": {"correct": False}},
        {"event_type": "keystroke", "payload": {"correct": True}},
    ]
    result = compute_daily_metrics(events)
    assert result["avg_accuracy"] is not None
    assert abs(result["avg_accuracy"] - 0.75) < 0.001


def test_daily_rollup_no_keystrokes_accuracy_is_none() -> None:
    events = [
        {"event_type": "item_completed", "payload": {}},
    ]
    result = compute_daily_metrics(events)
    assert result["avg_accuracy"] is None


def test_daily_rollup_empty_events() -> None:
    result = compute_daily_metrics([])
    assert result["items_completed"] == 0
    assert result["seconds_active"] == 0
    assert result["avg_accuracy"] is None


def test_daily_rollup_only_incorrect_keystrokes() -> None:
    events = [
        {"event_type": "keystroke", "payload": {"correct": False}},
        {"event_type": "keystroke", "payload": {"correct": False}},
    ]
    result = compute_daily_metrics(events)
    assert result["avg_accuracy"] == 0.0


# ── compute_weekly_payload ─────────────────────────────────────────────────────


def _week_rows() -> list[dict]:
    """7-day window where days 3-7 are active (5 consecutive at the end)."""
    return [
        {
            "date": date(2024, 1, 1),
            "seconds_active": 0,
            "items_completed": 0,
            "avg_accuracy": None,
        },
        {
            "date": date(2024, 1, 2),
            "seconds_active": 0,
            "items_completed": 0,
            "avg_accuracy": None,
        },
        {
            "date": date(2024, 1, 3),
            "seconds_active": 300,
            "items_completed": 5,
            "avg_accuracy": 0.8,
        },
        {
            "date": date(2024, 1, 4),
            "seconds_active": 400,
            "items_completed": 6,
            "avg_accuracy": 0.9,
        },
        {
            "date": date(2024, 1, 5),
            "seconds_active": 350,
            "items_completed": 4,
            "avg_accuracy": 0.85,
        },
        {
            "date": date(2024, 1, 6),
            "seconds_active": 600,
            "items_completed": 8,
            "avg_accuracy": 0.9,
        },
        {
            "date": date(2024, 1, 7),
            "seconds_active": 200,
            "items_completed": 3,
            "avg_accuracy": 0.7,
        },
    ]


def test_weekly_payload_streak_computation() -> None:
    """5 consecutive active days at the end of a 7-day window → streak = 5."""
    payload = compute_weekly_payload(_week_rows(), [], [])
    assert payload["streak_days"] == 5


def test_weekly_payload_areas_needing_practice() -> None:
    """Skills with p_known < threshold appear in areas_needing_practice."""
    skill_rows = [
        {"skill_key": "en:letter:b", "p_known": 0.2},
        {"skill_key": "en:letter:a", "p_known": 0.95},
    ]
    payload = compute_weekly_payload([], skill_rows, [])
    assert any("b" in s["skill_key"] for s in payload["areas_needing_practice"])
    # High p_known skill should NOT be in areas_needing_practice
    assert not any("a" in s["skill_key"] for s in payload["areas_needing_practice"])


def test_weekly_payload_top_mastered_skills() -> None:
    """Skills with high p_known appear in top_mastered_skills."""
    skill_rows = [
        {"skill_key": "en:letter:a", "p_known": 0.95},
        {"skill_key": "en:letter:b", "p_known": 0.2},
        {"skill_key": "en:letter:c", "p_known": 0.88},
    ]
    payload = compute_weekly_payload([], skill_rows, [])
    top_keys = [s["skill_key"] for s in payload["top_mastered_skills"]]
    assert "en:letter:a" in top_keys
    assert "en:letter:c" in top_keys
    assert "en:letter:b" not in top_keys


def test_weekly_payload_zero_streak_when_no_activity() -> None:
    daily_rows = [
        {"date": date(2024, 1, 1), "seconds_active": 0, "items_completed": 0, "avg_accuracy": None},
        {"date": date(2024, 1, 2), "seconds_active": 0, "items_completed": 0, "avg_accuracy": None},
    ]
    payload = compute_weekly_payload(daily_rows, [], [])
    assert payload["streak_days"] == 0


def test_weekly_payload_time_spent_aggregation() -> None:
    daily_rows = [
        {"date": date(2024, 1, 1), "seconds_active": 600, "items_completed": 5,
         "avg_accuracy": 0.9},
        {"date": date(2024, 1, 2), "seconds_active": 300, "items_completed": 3,
         "avg_accuracy": 0.8},
    ]
    payload = compute_weekly_payload(daily_rows, [], [])
    assert payload["time_spent_min"] == pytest.approx(15.0, abs=0.1)
    assert payload["items_completed"] == 8


def test_weekly_payload_accuracy_trend_none_when_no_data() -> None:
    payload = compute_weekly_payload([], [], [])
    assert payload["accuracy_trend"] is None


def test_weekly_payload_adaptation_summaries_passed_through() -> None:
    adaptation_rows = [
        {
            "changed_at": "2024-01-01T10:00:00+00:00",
            "param": "key_scale",
            "reason_code": "accuracy_drop",
        },
    ]
    payload = compute_weekly_payload([], [], adaptation_rows)
    assert len(payload["adaptation_summaries"]) == 1
    assert payload["adaptation_summaries"][0]["param"] == "key_scale"
