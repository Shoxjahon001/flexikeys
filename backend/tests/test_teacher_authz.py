"""Teacher authorization unit tests — no database required."""
from __future__ import annotations

import asyncio
import uuid
from datetime import UTC, datetime
from unittest.mock import AsyncMock, MagicMock

import pytest
from fastapi import HTTPException

from flexikeys.modules.teacher.schemas import StudentSummaryOut
from flexikeys.modules.teacher.service import TeacherService


def _svc(repo: MagicMock | None = None) -> TeacherService:
    svc: TeacherService = object.__new__(TeacherService)
    svc._repo = repo or MagicMock()
    return svc


def _mock_class(teacher_id: uuid.UUID, class_id: uuid.UUID | None = None) -> MagicMock:
    cls = MagicMock()
    cls.id = class_id or uuid.uuid4()
    cls.teacher_id = teacher_id
    cls.name = "Test Class"
    cls.join_code = "XYZ123"
    cls.created_at = datetime.now(UTC)
    return cls


# ── Teacher cannot access unenrolled child ────────────────────────────────────


def test_teacher_cannot_access_unenrolled_child() -> None:
    """assert_child_enrolled must raise 403 for a non-enrolled child."""
    class_id = uuid.uuid4()
    child_id = uuid.uuid4()
    repo = MagicMock()
    repo.is_enrolled = AsyncMock(return_value=False)

    svc = _svc(repo)
    with pytest.raises(HTTPException) as exc_info:
        asyncio.get_event_loop().run_until_complete(
            svc.assert_child_enrolled(class_id, child_id)
        )
    assert exc_info.value.status_code == 403
    repo.is_enrolled.assert_awaited_once_with(class_id, child_id)


def test_enrolled_child_passes_check() -> None:
    class_id = uuid.uuid4()
    child_id = uuid.uuid4()
    repo = MagicMock()
    repo.is_enrolled = AsyncMock(return_value=True)

    svc = _svc(repo)
    # Should not raise
    asyncio.get_event_loop().run_until_complete(
        svc.assert_child_enrolled(class_id, child_id)
    )


def test_wrong_teacher_cannot_access_class() -> None:
    """Teacher B cannot access Teacher A's class."""
    teacher_a = uuid.uuid4()
    teacher_b = uuid.uuid4()
    class_id = uuid.uuid4()
    cls = _mock_class(teacher_id=teacher_a, class_id=class_id)
    repo = MagicMock()
    repo.get_class_by_id = AsyncMock(return_value=cls)

    svc = _svc(repo)
    with pytest.raises(HTTPException) as exc_info:
        asyncio.get_event_loop().run_until_complete(
            svc.assert_teacher_owns_class(class_id, teacher_b)
        )
    assert exc_info.value.status_code == 403


def test_correct_teacher_passes_ownership_check() -> None:
    teacher_id = uuid.uuid4()
    class_id = uuid.uuid4()
    cls = _mock_class(teacher_id=teacher_id, class_id=class_id)
    repo = MagicMock()
    repo.get_class_by_id = AsyncMock(return_value=cls)

    svc = _svc(repo)
    # Should not raise
    asyncio.get_event_loop().run_until_complete(
        svc.assert_teacher_owns_class(class_id, teacher_id)
    )


def test_teacher_cannot_access_nonexistent_class() -> None:
    repo = MagicMock()
    repo.get_class_by_id = AsyncMock(return_value=None)

    svc = _svc(repo)
    with pytest.raises(HTTPException) as exc_info:
        asyncio.get_event_loop().run_until_complete(
            svc.assert_teacher_owns_class(uuid.uuid4(), uuid.uuid4())
        )
    assert exc_info.value.status_code == 403


# ── StudentSummaryOut must not expose parent contact data ─────────────────────


def test_student_summary_has_no_email_field() -> None:
    """StudentSummaryOut schema must not have email or phone fields."""
    fields = set(StudentSummaryOut.model_fields.keys())
    assert "email" not in fields
    assert "phone" not in fields
    assert "parent_email" not in fields
    assert "contact" not in fields


def test_student_summary_has_no_parent_id_field() -> None:
    fields = set(StudentSummaryOut.model_fields.keys())
    assert "parent_id" not in fields


def test_student_summary_contains_only_safe_fields() -> None:
    """Only educational progress fields should be in the summary."""
    allowed = {
        "child_id", "display_name", "mastery_score",
        "last_active", "needs_attention", "skills_needing_practice",
    }
    fields = set(StudentSummaryOut.model_fields.keys())
    assert fields == allowed


# ── Needs attention framing ───────────────────────────────────────────────────


def test_needs_attention_framing_uses_correct_copy() -> None:
    """The 'needs_attention' flag must never be presented as stigmatizing."""
    from flexikeys.modules.teacher.schemas import NeedsAttentionOut

    # NeedsAttentionOut must have skills_needing_practice, not labels like "struggling"
    fields = set(NeedsAttentionOut.model_fields.keys())
    assert "skills_needing_practice" in fields
    # Model must not have a field named after negative framing
    for bad_name in ("failing", "struggling", "behind", "weak"):
        assert bad_name not in fields


def test_analytics_needs_attention_count_not_ranking() -> None:
    """ClassAnalyticsOut provides a count, not a ranked leaderboard."""
    from flexikeys.modules.teacher.schemas import ClassAnalyticsOut

    fields = set(ClassAnalyticsOut.model_fields.keys())
    assert "needs_attention_count" in fields
    # There must be no rank, position, or percentile field
    for bad_name in ("rank", "ranking", "percentile", "position", "bottom"):
        assert bad_name not in fields
