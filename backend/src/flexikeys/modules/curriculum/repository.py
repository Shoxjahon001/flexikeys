from __future__ import annotations

import uuid
from typing import Any, Sequence

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from flexikeys.modules.curriculum.models import (
    CurriculumVersion,
    Item,
    ItemLocalization,
    Lesson,
    Level,
)


class CurriculumRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._s = session

    # ── Version ───────────────────────────────────────────────────────────────

    async def get_latest_version(self) -> CurriculumVersion | None:
        result = await self._s.execute(
            select(CurriculumVersion)
            .order_by(CurriculumVersion.published_at.desc())
            .limit(1)
        )
        return result.scalar_one_or_none()

    # ── Levels ────────────────────────────────────────────────────────────────

    async def list_levels(self, version_id: uuid.UUID) -> Sequence[Level]:
        result = await self._s.execute(
            select(Level)
            .where(Level.version_id == version_id)
            .order_by(Level.ordinal)
        )
        return result.scalars().all()

    async def get_level_by_slug(self, version_id: uuid.UUID, slug: str) -> Level | None:
        result = await self._s.execute(
            select(Level).where(Level.version_id == version_id, Level.slug == slug)
        )
        return result.scalar_one_or_none()

    # ── Lessons ───────────────────────────────────────────────────────────────

    async def list_lessons(self, level_id: uuid.UUID) -> Sequence[Lesson]:
        result = await self._s.execute(
            select(Lesson).where(Lesson.level_id == level_id).order_by(Lesson.ordinal)
        )
        return result.scalars().all()

    async def get_lesson_by_id(self, lesson_id: uuid.UUID) -> Lesson | None:
        result = await self._s.execute(
            select(Lesson).where(Lesson.id == lesson_id)
        )
        return result.scalar_one_or_none()

    # ── Items ─────────────────────────────────────────────────────────────────

    async def list_items(self, lesson_id: uuid.UUID) -> Sequence[Item]:
        result = await self._s.execute(
            select(Item).where(Item.lesson_id == lesson_id).order_by(Item.ordinal)
        )
        return result.scalars().all()

    async def get_item_l10n(self, item_id: uuid.UUID, language: str) -> ItemLocalization | None:
        result = await self._s.execute(
            select(ItemLocalization).where(
                ItemLocalization.item_id == item_id,
                ItemLocalization.language == language,
            )
        )
        return result.scalar_one_or_none()

    async def list_items_with_l10n(
        self, lesson_id: uuid.UUID, language: str
    ) -> list[tuple[Item, ItemLocalization | None]]:
        items = await self.list_items(lesson_id)
        result = []
        for item in items:
            l10n = await self.get_item_l10n(item.id, language)
            result.append((item, l10n))
        return result
