"""Teacher module unit tests — pure, no database required."""
from __future__ import annotations

import asyncio
import uuid
from datetime import UTC, datetime
from unittest.mock import AsyncMock, MagicMock

import pytest
from fastapi import HTTPException

from flexikeys.modules.teacher.schemas import (
    CreateAssignmentIn,
    StudentSummaryOut,
)
from flexikeys.modules.teacher.service import TeacherService, _generate_join_code

# ── Helpers ───────────────────────────────────────────────────────────────────

def _svc(repo: MagicMock | None = None) -> TeacherService:
    svc: TeacherService = object.__new__(TeacherService)
    svc._repo = repo or MagicMock()
    return svc


def _mock_class(
    *,
    id: uuid.UUID | None = None,
    teacher_id: uuid.UUID | None = None,
    name: str = "Test Class",
    join_code: str = "ABC123",
) -> MagicMock:
    cls = MagicMock()
    cls.id = id or uuid.uuid4()
    cls.teacher_id = teacher_id or uuid.uuid4()
    cls.name = name
    cls.join_code = join_code
    cls.created_at = datetime.now(UTC)
    return cls


def _mock_assignment(class_id: uuid.UUID) -> MagicMock:
    a = MagicMock()
    a.id = uuid.uuid4()
    a.class_id = class_id
    a.level_id = None
    a.lesson_id = None
    a.due_at = None
    a.instructions = "Practice letters A–E"  # noqa: RUF001
    a.created_at = datetime.now(UTC)
    return a


def _mock_enrollment() -> MagicMock:
    e = MagicMock()
    e.enrolled_at = datetime.now(UTC)
    return e


# ── Join code format ──────────────────────────────────────────────────────────


def test_join_code_is_uppercase_alphanumeric() -> None:
    for _ in range(50):
        code = _generate_join_code()
        assert len(code) == 6
        assert code.upper() == code
        assert code.isalnum()


# ── create_class ──────────────────────────────────────────────────────────────


def test_create_class_generates_join_code() -> None:
    teacher_id = uuid.uuid4()
    repo = MagicMock()
    cls = _mock_class(teacher_id=teacher_id)
    repo.create_class = AsyncMock(return_value=cls)
    repo.count_students = AsyncMock(return_value=0)

    svc = _svc(repo)
    result = asyncio.get_event_loop().run_until_complete(
        svc.create_class(teacher_id, "Room 3A")
    )

    repo.create_class.assert_awaited_once()
    called_args = repo.create_class.call_args
    assert called_args[0][0] == teacher_id
    assert called_args[0][1] == "Room 3A"
    join_code = called_args[0][2]
    assert len(join_code) == 6 and join_code.isalnum()
    assert result.name == cls.name
    assert result.student_count == 0


def test_create_class_stores_teacher_id() -> None:
    teacher_id = uuid.uuid4()
    repo = MagicMock()
    cls = _mock_class(teacher_id=teacher_id)
    repo.create_class = AsyncMock(return_value=cls)
    repo.count_students = AsyncMock(return_value=0)

    svc = _svc(repo)
    asyncio.get_event_loop().run_until_complete(svc.create_class(teacher_id, "Class B"))
    assert repo.create_class.call_args[0][0] == teacher_id


# ── list_classes ──────────────────────────────────────────────────────────────


def test_list_classes_filters_by_teacher() -> None:
    teacher_id = uuid.uuid4()
    repo = MagicMock()
    repo.get_classes_by_teacher = AsyncMock(
        return_value=[_mock_class(teacher_id=teacher_id)]
    )
    repo.count_students = AsyncMock(return_value=2)

    svc = _svc(repo)
    classes = asyncio.get_event_loop().run_until_complete(svc.list_classes(teacher_id))

    repo.get_classes_by_teacher.assert_awaited_once_with(teacher_id)
    assert len(classes) == 1
    assert classes[0].student_count == 2


# ── join_class ────────────────────────────────────────────────────────────────


def test_join_class_creates_enrollment() -> None:
    child_id = uuid.uuid4()
    cls = _mock_class(join_code="XYZ999")
    repo = MagicMock()
    repo.get_class_by_join_code = AsyncMock(return_value=cls)
    repo.is_enrolled = AsyncMock(return_value=False)
    repo.enroll_child = AsyncMock(return_value=_mock_enrollment())

    svc = _svc(repo)
    result = asyncio.get_event_loop().run_until_complete(
        svc.join_class("XYZ999", child_id)
    )

    repo.enroll_child.assert_awaited_once_with(cls.id, child_id)
    assert result.class_id == cls.id
    assert result.class_name == cls.name


def test_join_class_rejects_invalid_code() -> None:
    repo = MagicMock()
    repo.get_class_by_join_code = AsyncMock(return_value=None)

    svc = _svc(repo)
    with pytest.raises(HTTPException) as exc_info:
        asyncio.get_event_loop().run_until_complete(
            svc.join_class("BADCODE", uuid.uuid4())
        )
    assert exc_info.value.status_code == 404


def test_join_class_rejects_duplicate_enrollment() -> None:
    cls = _mock_class(join_code="DUP000")
    repo = MagicMock()
    repo.get_class_by_join_code = AsyncMock(return_value=cls)
    repo.is_enrolled = AsyncMock(return_value=True)

    svc = _svc(repo)
    with pytest.raises(HTTPException) as exc_info:
        asyncio.get_event_loop().run_until_complete(
            svc.join_class("DUP000", uuid.uuid4())
        )
    assert exc_info.value.status_code == 409


# ── create_assignment ─────────────────────────────────────────────────────────


def test_create_assignment_rejects_wrong_teacher() -> None:
    teacher_id = uuid.uuid4()
    other_teacher = uuid.uuid4()
    class_id = uuid.uuid4()
    cls = _mock_class(id=class_id, teacher_id=other_teacher)
    repo = MagicMock()
    repo.get_class_by_id = AsyncMock(return_value=cls)

    svc = _svc(repo)
    with pytest.raises(HTTPException) as exc_info:
        asyncio.get_event_loop().run_until_complete(
            svc.create_assignment(class_id, teacher_id, CreateAssignmentIn())
        )
    assert exc_info.value.status_code == 403


def test_create_assignment_succeeds() -> None:
    teacher_id = uuid.uuid4()
    class_id = uuid.uuid4()
    cls = _mock_class(id=class_id, teacher_id=teacher_id)
    assignment = _mock_assignment(class_id)

    repo = MagicMock()
    repo.get_class_by_id = AsyncMock(return_value=cls)
    repo.create_assignment = AsyncMock(return_value=assignment)

    svc = _svc(repo)
    data = CreateAssignmentIn(instructions="Do letters A–C")  # noqa: RUF001
    result = asyncio.get_event_loop().run_until_complete(
        svc.create_assignment(class_id, teacher_id, data)
    )

    repo.create_assignment.assert_awaited_once()
    assert result.class_id == class_id


# ── get_class_analytics ───────────────────────────────────────────────────────


def test_get_class_analytics_sums_students() -> None:
    teacher_id = uuid.uuid4()
    class_id = uuid.uuid4()
    cls = _mock_class(id=class_id, teacher_id=teacher_id)

    repo = MagicMock()
    repo.get_class_by_id = AsyncMock(return_value=cls)

    summaries = [
        StudentSummaryOut(
            child_id=uuid.uuid4(),
            display_name="Alex",
            mastery_score=0.8,
            last_active=None,
            needs_attention=False,
        ),
        StudentSummaryOut(
            child_id=uuid.uuid4(),
            display_name="Sam",
            mastery_score=0.4,
            last_active=None,
            needs_attention=True,
        ),
    ]

    svc = _svc(repo)
    result = asyncio.get_event_loop().run_until_complete(
        svc.get_class_analytics(class_id, teacher_id, summaries)
    )

    assert result.student_count == 2
    assert abs(result.avg_mastery - 0.6) < 0.001
    assert result.needs_attention_count == 1


def test_get_class_analytics_counts_needs_attention() -> None:
    teacher_id = uuid.uuid4()
    class_id = uuid.uuid4()
    cls = _mock_class(id=class_id, teacher_id=teacher_id)
    repo = MagicMock()
    repo.get_class_by_id = AsyncMock(return_value=cls)

    summaries = [
        StudentSummaryOut(
            child_id=uuid.uuid4(),
            display_name=f"Child {i}",
            mastery_score=0.3,
            last_active=None,
            needs_attention=True,
        )
        for i in range(3)
    ]

    svc = _svc(repo)
    result = asyncio.get_event_loop().run_until_complete(
        svc.get_class_analytics(class_id, teacher_id, summaries)
    )

    assert result.needs_attention_count == 3


def test_get_class_analytics_empty_class() -> None:
    teacher_id = uuid.uuid4()
    class_id = uuid.uuid4()
    cls = _mock_class(id=class_id, teacher_id=teacher_id)
    repo = MagicMock()
    repo.get_class_by_id = AsyncMock(return_value=cls)

    svc = _svc(repo)
    result = asyncio.get_event_loop().run_until_complete(
        svc.get_class_analytics(class_id, teacher_id, [])
    )

    assert result.student_count == 0
    assert result.avg_mastery == 0.0
    assert result.needs_attention_count == 0
