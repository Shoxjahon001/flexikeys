from __future__ import annotations

import uuid
from datetime import UTC, datetime
from typing import Any, Sequence

from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession

from flexikeys.modules.children.models import Child


class ChildRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._s = session

    async def get_by_id(self, child_id: uuid.UUID) -> Child | None:
        result = await self._s.execute(
            select(Child).where(and_(Child.id == child_id, Child.deleted_at.is_(None)))
        )
        return result.scalar_one_or_none()

    async def list_by_parent(self, parent_id: uuid.UUID) -> Sequence[Child]:
        result = await self._s.execute(
            select(Child).where(
                and_(Child.parent_id == parent_id, Child.deleted_at.is_(None))
            )
        )
        return result.scalars().all()

    async def create(
        self,
        parent_id: uuid.UUID,
        display_name: str,
        learning_language: Any,
        ui_language: str = "en",
        birth_year: int | None = None,
        avatar_id: str | None = None,
    ) -> Child:
        child = Child(
            id=uuid.uuid4(),
            parent_id=parent_id,
            display_name=display_name,
            learning_language=learning_language,
            ui_language=ui_language,
            birth_year=birth_year,
            avatar_id=avatar_id,
        )
        self._s.add(child)
        await self._s.flush()
        return child

    async def update(self, child: Child, **kwargs: Any) -> Child:
        for k, v in kwargs.items():
            setattr(child, k, v)
        child.updated_at = datetime.now(UTC)
        await self._s.flush()
        return child

    async def is_enrolled_in_teacher_class(
        self, child_id: uuid.UUID, teacher_id: uuid.UUID
    ) -> bool:
        """Check whether a child is in any class taught by the given teacher."""
        from flexikeys.modules.teacher.models import Class, ClassEnrollment

        result = await self._s.execute(
            select(ClassEnrollment)
            .join(Class, Class.id == ClassEnrollment.class_id)
            .where(
                and_(
                    ClassEnrollment.child_id == child_id,
                    Class.teacher_id == teacher_id,
                )
            )
        )
        return result.scalar_one_or_none() is not None