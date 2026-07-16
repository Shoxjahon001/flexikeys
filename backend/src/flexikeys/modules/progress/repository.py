from __future__ import annotations

import uuid
from datetime import date, datetime

from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession

from flexikeys.modules.adaptive.models import AdaptationChange, SkillMastery
from flexikeys.modules.progress.models import ChildGameProgress, DailyActivity


class ProgressRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._s = session

    async def get_skill_mastery(
        self, child_id: uuid.UUID, language: str
    ) -> list[SkillMastery]:
        result = await self._s.execute(
            select(SkillMastery).where(
                and_(
                    SkillMastery.child_id == child_id,
                    SkillMastery.language == language,
                )
            )
        )
        return list(result.scalars().all())

    async def get_daily_activity(
        self, child_id: uuid.UUID, from_date: date, to_date: date
    ) -> list[DailyActivity]:
        result = await self._s.execute(
            select(DailyActivity)
            .where(
                and_(
                    DailyActivity.child_id == child_id,
                    DailyActivity.date >= from_date,
                    DailyActivity.date <= to_date,
                )
            )
            .order_by(DailyActivity.date)
        )
        return list(result.scalars().all())

    async def get_adaptation_changes(
        self, child_id: uuid.UUID, limit: int = 20, offset: int = 0
    ) -> list[AdaptationChange]:
        result = await self._s.execute(
            select(AdaptationChange)
            .where(AdaptationChange.child_id == child_id)
            .order_by(AdaptationChange.changed_at.desc())
            .limit(limit)
            .offset(offset)
        )
        return list(result.scalars().all())

    async def list_game_progress(self, child_id: uuid.UUID) -> list[ChildGameProgress]:
        result = await self._s.execute(
            select(ChildGameProgress).where(ChildGameProgress.child_id == child_id)
        )
        return list(result.scalars().all())

    async def get_game_progress_row(
        self, child_id: uuid.UUID, level_slug: str
    ) -> ChildGameProgress | None:
        result = await self._s.execute(
            select(ChildGameProgress).where(
                and_(
                    ChildGameProgress.child_id == child_id,
                    ChildGameProgress.level_slug == level_slug,
                )
            )
        )
        return result.scalar_one_or_none()

    async def upsert_game_progress(
        self,
        row: ChildGameProgress | None,
        *,
        child_id: uuid.UUID,
        level_slug: str,
        completed: bool,
        stars: int,
        completed_activities: list[str],
        updated_at: datetime,
    ) -> ChildGameProgress:
        if row is None:
            row = ChildGameProgress(child_id=child_id, level_slug=level_slug)
            self._s.add(row)
        row.completed = completed
        row.stars = stars
        row.completed_activities = completed_activities
        row.updated_at = updated_at
        await self._s.flush()
        return row
