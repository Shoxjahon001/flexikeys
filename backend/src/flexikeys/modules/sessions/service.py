from __future__ import annotations

import json
import uuid
from datetime import UTC, datetime
from typing import Any

from fastapi import HTTPException
from redis.asyncio import Redis
from sqlalchemy.ext.asyncio import AsyncSession

from flexikeys.modules.sessions.repository import SessionRepository
from flexikeys.modules.sessions.schemas import EventBatchIn, SessionCreate, SessionEnd

_BATCH_DEDUP_TTL = 86_400  # 24 h


class SessionService:
    def __init__(self, session: AsyncSession, redis: Redis) -> None:  # type: ignore[type-arg]
        self._repo = SessionRepository(session)
        self._redis = redis

    async def start_session(self, body: SessionCreate) -> Any:
        return await self._repo.create_session(
            child_id=body.child_id,
            language=body.language,
            device_info=body.device_info,
            client_version=body.client_version,
        )

    async def end_session(self, session_id: uuid.UUID, body: SessionEnd) -> Any:
        obj = await self._repo.end_session(session_id, body.ended_at)
        if obj is None:
            raise HTTPException(status_code=404, detail="Session not found")
        return obj

    async def ingest_events(
        self, session_id: uuid.UUID, batch: EventBatchIn
    ) -> tuple[int, bool]:
        """
        Idempotent batch ingest.

        Returns (accepted_count, deduplicated).
        deduplicated=True means this batch_id was already processed.
        """
        dedup_key = f"ingest:batch:{batch.batch_id}"
        # Redis SET NX — returns True only on first call
        is_new = await self._redis.set(dedup_key, "1", ex=_BATCH_DEDUP_TTL, nx=True)
        if not is_new:
            return 0, True  # already processed

        # Validate session exists
        ls = await self._repo.get_session(session_id)
        if ls is None:
            raise HTTPException(status_code=404, detail="Session not found")

        # Normalise events for batch insert
        rows: list[dict[str, Any]] = []
        for ev in batch.events:
            payload_dict = ev.payload.model_dump(exclude={"event_type"})
            rows.append(
                {
                    "occurred_at": ev.occurred_at,
                    "event_type": ev.payload.event_type,
                    "item_id": ev.item_id
                    or getattr(ev.payload, "item_id", None),
                    "skill_key": ev.skill_key
                    or getattr(ev.payload, "skill_key", None),
                    "payload": json.dumps(payload_dict),
                }
            )

        count = await self._repo.insert_event_batch(session_id, batch.batch_id, rows)
        return count, False

    def normalise_events_for_pipeline(self, batch: EventBatchIn) -> list[dict[str, Any]]:
        """Convert ingest batch to the flat dicts expected by metrics pipeline."""
        result: list[dict[str, Any]] = []
        for ev in batch.events:
            payload_dict = ev.payload.model_dump()
            result.append(
                {
                    "event_type": ev.payload.event_type,
                    "occurred_at": ev.occurred_at,
                    "skill_key": ev.skill_key or payload_dict.get("skill_key"),
                    "item_id": ev.item_id,
                    "payload": payload_dict,
                }
            )
        return result
