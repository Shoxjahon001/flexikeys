from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from flexikeys.modules.teacher.models import (
    Assignment,
    AssignmentSubmission,
    Class,
    ClassEnrollment,
)


class TeacherRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._s = session

    async def create_class(
        self, teacher_id: uuid.UUID, name: str, join_code: str
    ) -> Class:
        cls = Class(teacher_id=teacher_id, name=name, join_code=join_code)
        self._s.add(cls)
        await self._s.flush()
        return cls

    async def get_classes_by_teacher(self, teacher_id: uuid.UUID) -> list[Class]:
        result = await self._s.execute(
            select(Class)
            .where(Class.teacher_id == teacher_id)
            .order_by(Class.created_at.desc())
        )
        return list(result.scalars().all())

    async def get_class_by_id(self, class_id: uuid.UUID) -> Class | None:
        result = await self._s.execute(select(Class).where(Class.id == class_id))
        return result.scalar_one_or_none()

    async def get_class_by_join_code(self, join_code: str) -> Class | None:
        result = await self._s.execute(
            select(Class).where(Class.join_code == join_code)
        )
        return result.scalar_one_or_none()

    async def is_enrolled(self, class_id: uuid.UUID, child_id: uuid.UUID) -> bool:
        result = await self._s.execute(
            select(ClassEnrollment).where(
                ClassEnrollment.class_id == class_id,
                ClassEnrollment.child_id == child_id,
            )
        )
        return result.scalar_one_or_none() is not None

    async def enroll_child(
        self, class_id: uuid.UUID, child_id: uuid.UUID
    ) -> ClassEnrollment:
        enrollment = ClassEnrollment(class_id=class_id, child_id=child_id)
        self._s.add(enrollment)
        await self._s.flush()
        return enrollment

    async def get_enrolled_child_ids(self, class_id: uuid.UUID) -> list[uuid.UUID]:
        result = await self._s.execute(
            select(ClassEnrollment.child_id).where(
                ClassEnrollment.class_id == class_id
            )
        )
        return list(result.scalars().all())

    async def create_assignment(
        self,
        class_id: uuid.UUID,
        level_id: uuid.UUID | None,
        lesson_id: uuid.UUID | None,
        due_at: datetime | None,
        instructions: str | None,
    ) -> Assignment:
        assignment = Assignment(
            class_id=class_id,
            level_id=level_id,
            lesson_id=lesson_id,
            due_at=due_at,
            instructions=instructions,
        )
        self._s.add(assignment)
        await self._s.flush()
        return assignment

    async def get_assignments_by_class(self, class_id: uuid.UUID) -> list[Assignment]:
        result = await self._s.execute(
            select(Assignment)
            .where(Assignment.class_id == class_id)
            .order_by(Assignment.created_at.desc())
        )
        return list(result.scalars().all())

    async def upsert_submission(
        self,
        assignment_id: uuid.UUID,
        child_id: uuid.UUID,
        status: str,
    ) -> AssignmentSubmission:
        from flexikeys.core.enums import SubmissionStatus

        result = await self._s.execute(
            select(AssignmentSubmission).where(
                AssignmentSubmission.assignment_id == assignment_id,
                AssignmentSubmission.child_id == child_id,
            )
        )
        submission = result.scalar_one_or_none()
        if submission is None:
            submission = AssignmentSubmission(
                assignment_id=assignment_id,
                child_id=child_id,
                status=SubmissionStatus(status),
            )
            self._s.add(submission)
        else:
            submission.status = SubmissionStatus(status)
        await self._s.flush()
        return submission

    async def count_students(self, class_id: uuid.UUID) -> int:
        result = await self._s.execute(
            select(func.count()).select_from(ClassEnrollment).where(
                ClassEnrollment.class_id == class_id
            )
        )
        return result.scalar_one()
