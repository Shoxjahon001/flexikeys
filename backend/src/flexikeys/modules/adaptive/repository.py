from __future__ import annotations

import uuid
from datetime import UTC, datetime
from decimal import Decimal
from typing import Any, Sequence

from sqlalchemy import and_, select, update
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.ext.asyncio import AsyncSession

from flexikeys.modules.adaptive.models import (
    AdaptationChange,
    AdaptationProfile,
    RepetitionQueue,
    SkillMastery,
)
from flexikeys.modules.adaptive.policy import PolicyChange


class AdaptiveRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._s = session

    # ── SkillMastery ──────────────────────────────────────────────────────────

    async def get_skill_mastery(
        self, child_id: uuid.UUID, language: str, skill_key: str
    ) -> SkillMastery | None:
        result = await self._s.execute(
            select(SkillMastery).where(
                and_(
                    SkillMastery.child_id == child_id,
                    SkillMastery.language == language,
                    SkillMastery.skill_key == skill_key,
                )
            )
        )
        return result.scalar_one_or_none()

    async def list_skill_mastery(
        self, child_id: uuid.UUID, language: str
    ) -> Sequence[SkillMastery]:
        result = await self._s.execute(
            select(SkillMastery).where(
                and_(
                    SkillMastery.child_id == child_id,
                    SkillMastery.language == language,
                )
            )
        )
        return result.scalars().all()

    async def upsert_skill_mastery(
        self,
        child_id: uuid.UUID,
        language: str,
        skill_key: str,
        p_known: float,
        attempts_delta: int = 0,
        correct_delta: int = 0,
        ewma_accuracy: float | None = None,
        ewma_latency_ms: float | None = None,
    ) -> SkillMastery:
        existing = await self.get_skill_mastery(child_id, language, skill_key)
        now = datetime.now(UTC)
        if existing is None:
            obj = SkillMastery(
                id=uuid.uuid4(),
                child_id=child_id,
                language=language,
                skill_key=skill_key,
                p_known=Decimal(str(round(p_known, 4))),
                attempts=attempts_delta,
                correct=correct_delta,
                ewma_accuracy=Decimal(str(round(ewma_accuracy, 4))) if ewma_accuracy is not None else None,
                ewma_latency_ms=Decimal(str(round(ewma_latency_ms, 2))) if ewma_latency_ms is not None else None,
                last_seen_at=now,
            )
            self._s.add(obj)
            await self._s.flush()
            return obj
        else:
            existing.p_known = Decimal(str(round(p_known, 4)))
            existing.attempts += attempts_delta
            existing.correct += correct_delta
            if ewma_accuracy is not None:
                existing.ewma_accuracy = Decimal(str(round(ewma_accuracy, 4)))
            if ewma_latency_ms is not None:
                existing.ewma_latency_ms = Decimal(str(round(ewma_latency_ms, 2)))
            existing.last_seen_at = now
            await self._s.flush()
            return existing

    # ── AdaptationProfile ─────────────────────────────────────────────────────

    async def get_profile(self, child_id: uuid.UUID) -> AdaptationProfile | None:
        result = await self._s.execute(
            select(AdaptationProfile).where(AdaptationProfile.child_id == child_id)
        )
        return result.scalar_one_or_none()

    async def upsert_profile(
        self, child_id: uuid.UUID, params: dict[str, Any], version: int
    ) -> AdaptationProfile:
        existing = await self.get_profile(child_id)
        now = datetime.now(UTC)
        if existing is None:
            obj = AdaptationProfile(
                id=uuid.uuid4(),
                child_id=child_id,
                params=params,
                version=version,
                updated_at=now,
            )
            self._s.add(obj)
            await self._s.flush()
            return obj
        else:
            existing.params = params
            existing.version = version
            existing.updated_at = now
            await self._s.flush()
            return existing

    # ── AdaptationChange audit log ────────────────────────────────────────────

    async def record_changes(
        self,
        child_id: uuid.UUID,
        changes: list[PolicyChange],
    ) -> list[AdaptationChange]:
        now = datetime.now(UTC)
        rows: list[AdaptationChange] = []
        for c in changes:
            obj = AdaptationChange(
                id=uuid.uuid4(),
                child_id=child_id,
                changed_at=now,
                param=c.param,
                old_value=str(c.old_value) if c.old_value is not None else None,
                new_value=str(c.new_value) if c.new_value is not None else None,
                reason_code=c.reason_code,  # type: ignore[arg-type]
                explanation_key=c.explanation_key,
            )
            self._s.add(obj)
            rows.append(obj)
        if rows:
            await self._s.flush()
        return rows

    # ── RepetitionQueue ───────────────────────────────────────────────────────

    async def list_due_queue(
        self, child_id: uuid.UUID, language: str
    ) -> Sequence[RepetitionQueue]:
        result = await self._s.execute(
            select(RepetitionQueue).where(
                and_(
                    RepetitionQueue.child_id == child_id,
                    RepetitionQueue.language == language,
                )
            )
        )
        return result.scalars().all()

    async def upsert_queue_entry(
        self,
        child_id: uuid.UUID,
        language: str,
        skill_key: str,
        due_at: datetime,
        interval_days: int,
        ease: float,
        lapses: int,
    ) -> RepetitionQueue:
        result = await self._s.execute(
            select(RepetitionQueue).where(
                and_(
                    RepetitionQueue.child_id == child_id,
                    RepetitionQueue.language == language,
                    RepetitionQueue.skill_key == skill_key,
                )
            )
        )
        existing = result.scalar_one_or_none()
        if existing is None:
            obj = RepetitionQueue(
                id=uuid.uuid4(),
                child_id=child_id,
                language=language,
                skill_key=skill_key,
                due_at=due_at,
                interval_days=interval_days,
                ease=Decimal(str(round(ease, 2))),
                lapses=lapses,
            )
            self._s.add(obj)
            await self._s.flush()
            return obj
        else:
            existing.due_at = due_at
            existing.interval_days = interval_days
            existing.ease = Decimal(str(round(ease, 2)))
            existing.lapses = lapses
            await self._s.flush()
            return existing
