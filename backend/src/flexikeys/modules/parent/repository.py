from __future__ import annotations

import uuid
from datetime import UTC, datetime

from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession

from flexikeys.modules.adaptive.models import AdaptationChange, SkillMastery
from flexikeys.modules.children.models import Child
from flexikeys.modules.parent.models import Report
from flexikeys.modules.progress.models import DailyActivity


class ParentRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._s = session

    async def get_children(self, parent_id: uuid.UUID) -> list[Child]:
        result = await self._s.execute(
            select(Child).where(
                and_(Child.parent_id == parent_id, Child.deleted_at.is_(None))
            )
        )
        return list(result.scalars().all())

    async def get_child(
        self, child_id: uuid.UUID, parent_id: uuid.UUID
    ) -> Child | None:
        result = await self._s.execute(
            select(Child).where(
                and_(
                    Child.id == child_id,
                    Child.parent_id == parent_id,
                    Child.deleted_at.is_(None),
                )
            )
        )
        return result.scalar_one_or_none()

    async def get_today_activity(self, child_id: uuid.UUID) -> DailyActivity | None:
        today = datetime.now(UTC).date()
        result = await self._s.execute(
            select(DailyActivity).where(
                and_(
                    DailyActivity.child_id == child_id,
                    DailyActivity.date == today,
                )
            )
        )
        return result.scalar_one_or_none()

    async def get_streak(self, child_id: uuid.UUID) -> int:
        """Return the current consecutive-day streak for the child."""
        from datetime import timedelta

        result = await self._s.execute(
            select(DailyActivity)
            .where(
                and_(
                    DailyActivity.child_id == child_id,
                    DailyActivity.seconds_active > 0,
                )
            )
            .order_by(DailyActivity.date.desc())
            .limit(365)
        )
        rows = list(result.scalars().all())
        if not rows:
            return 0

        active_dates = sorted({r.date for r in rows}, reverse=True)
        streak = 1
        for i in range(1, len(active_dates)):
            if active_dates[i] == active_dates[i - 1] - timedelta(days=1):
                streak += 1
            else:
                break
        return streak

    async def get_reports(
        self, child_id: uuid.UUID, scope: str | None
    ) -> list[Report]:
        stmt = select(Report).where(Report.subject_id == child_id)
        if scope is not None:
            stmt = stmt.where(Report.scope == scope)
        result = await self._s.execute(stmt.order_by(Report.created_at.desc()))
        return list(result.scalars().all())

    async def get_all_activity(self, child_id: uuid.UUID) -> list[DailyActivity]:
        result = await self._s.execute(
            select(DailyActivity)
            .where(DailyActivity.child_id == child_id)
            .order_by(DailyActivity.date)
        )
        return list(result.scalars().all())

    async def get_all_skill_mastery(self, child_id: uuid.UUID) -> list[SkillMastery]:
        result = await self._s.execute(
            select(SkillMastery).where(SkillMastery.child_id == child_id)
        )
        return list(result.scalars().all())

    async def get_all_adaptation_changes(
        self, child_id: uuid.UUID
    ) -> list[AdaptationChange]:
        result = await self._s.execute(
            select(AdaptationChange)
            .where(AdaptationChange.child_id == child_id)
            .order_by(AdaptationChange.changed_at.desc())
        )
        return list(result.scalars().all())

    async def delete_child(self, child_id: uuid.UUID) -> None:
        result = await self._s.execute(
            select(Child).where(Child.id == child_id)
        )
        child = result.scalar_one_or_none()
        if child is not None:
            child.deleted_at = datetime.now(UTC)
            await self._s.flush()
