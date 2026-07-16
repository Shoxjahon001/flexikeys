"""Notification service unit tests — no database required."""
from __future__ import annotations

import asyncio
import uuid
from unittest.mock import AsyncMock, MagicMock

import pytest

from flexikeys.modules.notifications.service import (
    _TEMPLATES,
    NotificationService,
    _render,
)

# ── Helpers ───────────────────────────────────────────────────────────────────


def _svc(repo: MagicMock | None = None) -> NotificationService:
    svc: NotificationService = object.__new__(NotificationService)
    svc._repo = repo or MagicMock()
    return svc


def _mock_repo(*, push=True, email=True, in_app=True, has_prefs=True) -> MagicMock:
    repo = MagicMock()
    prefs = MagicMock() if has_prefs else None
    if prefs:
        prefs.push_enabled = push
        prefs.email_enabled = email
        prefs.in_app_enabled = in_app
    repo.get_preferences = AsyncMock(return_value=prefs)
    repo.create = AsyncMock(return_value=MagicMock())
    return repo


# ── No-child targeting ────────────────────────────────────────────────────────


def test_no_child_targeting_raises_value_error() -> None:
    """Passing is_child=True must raise ValueError — never target child experience."""
    svc = _svc()
    with pytest.raises(ValueError, match="never target"):
        asyncio.get_event_loop().run_until_complete(
            svc.send(
                user_id=uuid.uuid4(),
                kind="weekly_report_ready",
                payload={"vars": {"child_name": "Alex"}},
                is_child=True,
            )
        )


def test_no_child_targeting_not_raised_for_parent() -> None:
    """Normal parent send must not raise."""
    repo = _mock_repo()
    svc = _svc(repo)
    # Should not raise
    asyncio.get_event_loop().run_until_complete(
        svc.send(
            user_id=uuid.uuid4(),
            kind="weekly_report_ready",
            payload={"vars": {"child_name": "Alex"}},
            is_child=False,
        )
    )


# ── Opt-out preferences ───────────────────────────────────────────────────────


def test_email_opt_out_respected() -> None:
    """If email_enabled=False, email notification must not be dispatched (in_app still fires)."""
    repo = _mock_repo(push=True, email=False, in_app=True)
    svc = _svc(repo)

    asyncio.get_event_loop().run_until_complete(
        svc.send(
            user_id=uuid.uuid4(),
            kind="streak_encouragement",
            payload={"vars": {"child_name": "Alex", "streak_days": "5"}},
            is_child=False,
        )
    )
    # in_app was True → create() called once
    repo.create.assert_awaited_once()


def test_push_opt_out_respected() -> None:
    """push_enabled=False must not crash and must still write in_app record."""
    repo = _mock_repo(push=False, email=True, in_app=True)
    svc = _svc(repo)

    asyncio.get_event_loop().run_until_complete(
        svc.send(
            user_id=uuid.uuid4(),
            kind="weekly_report_ready",
            payload={"vars": {"child_name": "Sam"}},
            is_child=False,
        )
    )
    repo.create.assert_awaited_once()


def test_in_app_opt_out_skips_db_write() -> None:
    """If in_app=False, no Notification record is created."""
    repo = _mock_repo(push=True, email=True, in_app=False)
    svc = _svc(repo)

    asyncio.get_event_loop().run_until_complete(
        svc.send(
            user_id=uuid.uuid4(),
            kind="streak_encouragement",
            payload={"vars": {"child_name": "Lee", "streak_days": "3"}},
            is_child=False,
        )
    )
    repo.create.assert_not_awaited()


def test_all_channels_opt_out_skips_all() -> None:
    repo = _mock_repo(push=False, email=False, in_app=False)
    svc = _svc(repo)

    asyncio.get_event_loop().run_until_complete(
        svc.send(
            user_id=uuid.uuid4(),
            kind="consent_request",
            payload={"vars": {"teacher_name": "Ms. Kim", "class_name": "Room 1"}},
            is_child=False,
        )
    )
    repo.create.assert_not_awaited()


def test_no_prefs_row_sends_all_channels() -> None:
    """Absence of preference row = all channels enabled by default."""
    repo = _mock_repo(has_prefs=False)
    svc = _svc(repo)

    asyncio.get_event_loop().run_until_complete(
        svc.send(
            user_id=uuid.uuid4(),
            kind="weekly_report_ready",
            payload={"vars": {"child_name": "Alex"}},
            is_child=False,
        )
    )
    # in_app is on by default → create called
    repo.create.assert_awaited_once()


# ── Template rendering ────────────────────────────────────────────────────────


def test_weekly_report_template_en() -> None:
    rendered = _render("weekly_report_ready", "en", {"child_name": "Alex"})
    assert "Alex" in rendered["body"]
    assert "weekly" in rendered["body"].lower() or "report" in rendered["title"].lower()


def test_weekly_report_template_uz() -> None:
    rendered = _render("weekly_report_ready", "uz", {"child_name": "Amir"})
    assert "Amir" in rendered["body"]
    assert "hisobot" in rendered["body"].lower() or "Haftalik" in rendered["title"]


def test_weekly_report_template_ru() -> None:
    rendered = _render("weekly_report_ready", "ru", {"child_name": "Саша"})
    assert "Саша" in rendered["body"]
    # Cyrillic chars in Russian template
    assert any("А" <= c <= "я" for c in rendered["title"])  # noqa: RUF001


def test_streak_template_interpolates_days() -> None:
    rendered = _render(
        "streak_encouragement", "en", {"child_name": "Jo", "streak_days": "7"}
    )
    assert "7" in rendered["body"]
    assert "Jo" in rendered["body"]


def test_consent_request_template_interpolates_teacher_and_class() -> None:
    rendered = _render(
        "consent_request", "en", {"teacher_name": "Ms. Rivera", "class_name": "Bluebirds"}
    )
    assert "Ms. Rivera" in rendered["body"]
    assert "Bluebirds" in rendered["body"]


def test_assignment_template_en() -> None:
    rendered = _render("assignment_created", "en", {"child_name": "Lily"})
    assert "Lily" in rendered["body"]
    assert "assignment" in rendered["title"].lower() or "assignment" in rendered["body"].lower()


def test_unknown_language_falls_back_to_en() -> None:
    rendered = _render("weekly_report_ready", "xx", {"child_name": "Kim"})
    # Falls back to "en"
    assert "Kim" in rendered["body"]
    assert rendered["title"] == _TEMPLATES["weekly_report_ready"]["en"]["title"]


# ── High-level helper methods ─────────────────────────────────────────────────


def test_send_weekly_report_ready_calls_send() -> None:
    repo = _mock_repo()
    svc = _svc(repo)
    parent_id = uuid.uuid4()
    report_id = uuid.uuid4()

    asyncio.get_event_loop().run_until_complete(
        svc.send_weekly_report_ready(parent_id, "Alex", report_id, "en")
    )
    repo.create.assert_awaited_once()


def test_send_streak_encouragement_calls_send() -> None:
    repo = _mock_repo()
    svc = _svc(repo)

    asyncio.get_event_loop().run_until_complete(
        svc.send_streak_encouragement(uuid.uuid4(), "Alex", 5, "en")
    )
    repo.create.assert_awaited_once()


def test_send_consent_request_calls_send() -> None:
    repo = _mock_repo()
    svc = _svc(repo)

    asyncio.get_event_loop().run_until_complete(
        svc.send_consent_request(uuid.uuid4(), "Ms. Kim", "Bluebirds", "en")
    )
    repo.create.assert_awaited_once()
