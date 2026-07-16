from __future__ import annotations

import uuid
from datetime import UTC, datetime
from typing import Any, Sequence

from sqlalchemy import and_, select, text
from sqlalchemy.ext.asyncio import AsyncSession

from flexikeys.modules.sessions.models import InteractionEvent, LearningSession


class SessionRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._s = session

    async def create_session(
        self,
        child_id: uuid.UUID,
        language: str,
        device_info: dict[str, Any] | None = None,
        client_version: str | None = None,
    ) -> LearningSession:
        obj = LearningSession(
            id=uuid.uuid4(),
            child_id=child_id,
            language=language,
            device_info=device_info,
            client_version=client_version,
        )
        self._s.add(obj)
        await self._s.flush()
        return obj

    async def get_session(self, session_id: uuid.UUID) -> LearningSession | None:
        result = await self._s.execute(
            select(LearningSession).where(LearningSession.id == session_id)
        )
        return result.scalar_one_or_none()

    async def end_session(
        self, session_id: uuid.UUID, ended_at: datetime | None = None
    ) -> LearningSession | None:
        obj = await self.get_session(session_id)
        if obj is None:
            return None
        obj.ended_at = ended_at or datetime.now(UTC)
        await self._s.flush()
        return obj

    async def insert_event_batch(
        self,
        session_id: uuid.UUID,
        batch_id: uuid.UUID,
        events: list[dict[str, Any]],
    ) -> int:
        """
        Bulk-insert up to 500 events using executemany.
        Returns number of rows inserted.
        """
        if not events:
            return 0
        rows = [
            {
                "session_id": str(session_id),
                "occurred_at": e["occurred_at"],
                "event_type": e["event_type"],
                "item_id": str(e["item_id"]) if e.get("item_id") else None,
                "skill_key": e.get("skill_key"),
                "payload": e.get("payload"),
                "ingest_batch_id": str(batch_id),
            }
            for e in events
        ]
        await self._s.execute(
            text(
                """
                INSERT INTO interaction_events
                    (session_id, occurred_at, event_type, item_id, skill_key, payload, ingest_batch_id)
                VALUES
                    (:session_id, :occurred_at, CAST(:event_type AS event_type), :item_id::uuid,
                     :skill_key, CAST(:payload AS jsonb), :ingest_batch_id::uuid)
                """
            ),
            rows,
        )
        return len(rows)

    async def get_session_by_id_str(self, session_id: str) -> LearningSession | None:
        return await self.get_session(uuid.UUID(session_id))

    async def get_session_events(
        self, session_id: uuid.UUID
    ) -> Sequence[InteractionEvent]:
        result = await self._s.execute(
            select(InteractionEvent).where(
                InteractionEvent.session_id == session_id
            )
        )
        return result.scalars().all()
