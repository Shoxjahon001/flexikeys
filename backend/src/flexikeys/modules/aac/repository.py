from __future__ import annotations

import uuid
from datetime import date, datetime
from typing import Any

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from flexikeys.modules.aac.models import AacEvent


class AacRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._s = session

    async def insert_event_batch(
        self,
        child_id: uuid.UUID,
        batch_id: uuid.UUID,
        events: list[dict[str, Any]],
    ) -> int:
        if not events:
            return 0
        rows = [
            AacEvent(
                id=uuid.uuid4(),
                child_id=child_id,
                card_id=e["card_id"],
                category=e["category"],
                sentence_spoken=e["sentence_spoken"],
                language=e["language"],
                tapped_at=e["tapped_at"],
                ingest_batch_id=batch_id,
            )
            for e in events
        ]
        self._s.add_all(rows)
        await self._s.flush()
        return len(rows)

    async def get_events_since(
        self, child_id: uuid.UUID, since: datetime
    ) -> list[AacEvent]:
        result = await self._s.execute(
            select(AacEvent)
            .where(AacEvent.child_id == child_id, AacEvent.tapped_at >= since)
            .order_by(AacEvent.tapped_at)
        )
        return list(result.scalars().all())

    async def get_card_counts_between(
        self, child_id: uuid.UUID, start: datetime, end: datetime
    ) -> list[tuple[str, str, int]]:
        """(card_id, category, count), highest count first — for the parent
        dashboard's "Today" stat cards."""
        result = await self._s.execute(
            select(AacEvent.card_id, AacEvent.category, func.count().label("n"))
            .where(
                AacEvent.child_id == child_id,
                AacEvent.tapped_at >= start,
                AacEvent.tapped_at < end,
            )
            .group_by(AacEvent.card_id, AacEvent.category)
            .order_by(func.count().desc())
        )
        return [(row.card_id, row.category, row.n) for row in result.all()]

    async def get_daily_category_counts(
        self, child_id: uuid.UUID, since: datetime
    ) -> list[tuple[date, str, int]]:
        """(day, category, count) grouped by UTC calendar day — for the
        parent dashboard's 7-day trend chart."""
        day_expr = func.date(AacEvent.tapped_at)
        result = await self._s.execute(
            select(day_expr.label("day"), AacEvent.category, func.count().label("n"))
            .where(AacEvent.child_id == child_id, AacEvent.tapped_at >= since)
            .group_by(day_expr, AacEvent.category)
            .order_by(day_expr)
        )
        return [(row.day, row.category, row.n) for row in result.all()]
