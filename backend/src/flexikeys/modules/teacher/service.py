from __future__ import annotations

import random
import string
import uuid

from fastapi import HTTPException

from flexikeys.modules.teacher.repository import TeacherRepository
from flexikeys.modules.teacher.schemas import (
    AssignmentOut,
    ClassAnalyticsOut,
    ClassEnrollmentOut,
    ClassOut,
    CreateAssignmentIn,
    StudentSummaryOut,
)

_JOIN_CODE_CHARS = string.ascii_uppercase + string.digits
_JOIN_CODE_LENGTH = 6


def _generate_join_code() -> str:
    return "".join(random.choices(_JOIN_CODE_CHARS, k=_JOIN_CODE_LENGTH))


class TeacherService:
    def __init__(self, repo: TeacherRepository) -> None:
        self._repo = repo

    async def create_class(self, teacher_id: uuid.UUID, name: str) -> ClassOut:
        join_code = _generate_join_code()
        cls = await self._repo.create_class(teacher_id, name, join_code)
        count = await self._repo.count_students(cls.id)
        return ClassOut(
            id=cls.id,
            name=cls.name,
            join_code=cls.join_code,
            student_count=count,
            created_at=cls.created_at,
        )

    async def list_classes(self, teacher_id: uuid.UUID) -> list[ClassOut]:
        classes = await self._repo.get_classes_by_teacher(teacher_id)
        result = []
        for cls in classes:
            count = await self._repo.count_students(cls.id)
            result.append(
                ClassOut(
                    id=cls.id,
                    name=cls.name,
                    join_code=cls.join_code,
                    student_count=count,
                    created_at=cls.created_at,
                )
            )
        return result

    async def join_class(
        self, join_code: str, child_id: uuid.UUID
    ) -> ClassEnrollmentOut:
        cls = await self._repo.get_class_by_join_code(join_code.upper())
        if cls is None:
            raise HTTPException(status_code=404, detail="Class not found")
        already = await self._repo.is_enrolled(cls.id, child_id)
        if already:
            raise HTTPException(status_code=409, detail="Already enrolled")
        enrollment = await self._repo.enroll_child(cls.id, child_id)
        return ClassEnrollmentOut(
            class_id=cls.id,
            class_name=cls.name,
            enrolled_at=enrollment.enrolled_at,
        )

    async def create_assignment(
        self,
        class_id: uuid.UUID,
        teacher_id: uuid.UUID,
        data: CreateAssignmentIn,
    ) -> AssignmentOut:
        cls = await self._repo.get_class_by_id(class_id)
        if cls is None or cls.teacher_id != teacher_id:
            raise HTTPException(status_code=403, detail="Not authorized")
        assignment = await self._repo.create_assignment(
            class_id,
            data.level_id,
            data.lesson_id,
            data.due_at,
            data.instructions,
        )
        return AssignmentOut.model_validate(assignment)

    async def list_assignments(
        self, class_id: uuid.UUID, teacher_id: uuid.UUID
    ) -> list[AssignmentOut]:
        cls = await self._repo.get_class_by_id(class_id)
        if cls is None or cls.teacher_id != teacher_id:
            raise HTTPException(status_code=403, detail="Not authorized")
        assignments = await self._repo.get_assignments_by_class(class_id)
        return [AssignmentOut.model_validate(a) for a in assignments]

    async def get_class_analytics(
        self,
        class_id: uuid.UUID,
        teacher_id: uuid.UUID,
        student_summaries: list[StudentSummaryOut],
    ) -> ClassAnalyticsOut:
        cls = await self._repo.get_class_by_id(class_id)
        if cls is None or cls.teacher_id != teacher_id:
            raise HTTPException(status_code=403, detail="Not authorized")
        avg = (
            sum(s.mastery_score for s in student_summaries) / len(student_summaries)
            if student_summaries
            else 0.0
        )
        needs_count = sum(1 for s in student_summaries if s.needs_attention)
        return ClassAnalyticsOut(
            class_id=class_id,
            class_name=cls.name,
            student_count=len(student_summaries),
            avg_mastery=avg,
            needs_attention_count=needs_count,
            student_summaries=student_summaries,
        )

    async def assert_teacher_owns_class(
        self, class_id: uuid.UUID, teacher_id: uuid.UUID
    ) -> None:
        """Raise 403 if teacher does not own the class."""
        cls = await self._repo.get_class_by_id(class_id)
        if cls is None or cls.teacher_id != teacher_id:
            raise HTTPException(status_code=403, detail="Not authorized")

    async def assert_child_enrolled(
        self, class_id: uuid.UUID, child_id: uuid.UUID
    ) -> None:
        """Raise 403 if child is not enrolled in this class."""
        enrolled = await self._repo.is_enrolled(class_id, child_id)
        if not enrolled:
            raise HTTPException(
                status_code=403, detail="Child is not enrolled in this class"
            )
