from __future__ import annotations

import uuid
from typing import Annotated

from fastapi import APIRouter, BackgroundTasks, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from flexikeys.core.db import get_db
from flexikeys.core.deps import get_child_claims
from flexikeys.core.redis import get_redis
from flexikeys.modules.sessions.schemas import (
    EventBatchIn,
    EventBatchOut,
    SessionCreate,
    SessionEnd,
    SessionOut,
)
from flexikeys.modules.sessions.service import SessionService

router = APIRouter(prefix="/sessions", tags=["sessions"])


def _svc(db: AsyncSession, redis: object) -> SessionService:
    return SessionService(db, redis)  # type: ignore[arg-type]


@router.post("", response_model=SessionOut, status_code=201)
async def start_session(
    body: SessionCreate,
    claims: Annotated[dict, Depends(get_child_claims)],
    db: Annotated[AsyncSession, Depends(get_db)],
    redis: Annotated[object, Depends(get_redis)],
) -> SessionOut:
    child_id = uuid.UUID(claims["sub"])
    body = SessionCreate(
        child_id=child_id,
        language=body.language,
        device_info=body.device_info,
        client_version=body.client_version,
    )
    svc = _svc(db, redis)
    session = await svc.start_session(body)
    await db.commit()
    return SessionOut.model_validate(session)


@router.patch("/{session_id}", response_model=SessionOut)
async def end_session(
    session_id: uuid.UUID,
    body: SessionEnd,
    _claims: Annotated[dict, Depends(get_child_claims)],
    db: Annotated[AsyncSession, Depends(get_db)],
    redis: Annotated[object, Depends(get_redis)],
) -> SessionOut:
    svc = _svc(db, redis)
    session = await svc.end_session(session_id, body)
    await db.commit()
    return SessionOut.model_validate(session)


@router.post("/{session_id}/events", response_model=EventBatchOut)
async def ingest_events(
    session_id: uuid.UUID,
    batch: EventBatchIn,
    background_tasks: BackgroundTasks,
    _claims: Annotated[dict, Depends(get_child_claims)],
    db: Annotated[AsyncSession, Depends(get_db)],
    redis: Annotated[object, Depends(get_redis)],
) -> EventBatchOut:
    svc = _svc(db, redis)
    accepted, deduplicated = await svc.ingest_events(session_id, batch)
    if not deduplicated:
        await db.commit()
        background_tasks.add_task(
            _run_metric_pipeline_bg,
            str(session_id),
            svc.normalise_events_for_pipeline(batch),
        )
    return EventBatchOut(accepted=accepted, deduplicated=deduplicated)


async def _run_metric_pipeline_bg(session_id: str, events: list) -> None:  # type: ignore[type-arg]
    # STUB #2 — replace with ARQ worker enqueue (see issue #adaptive-worker-arq)
    from flexikeys.modules.adaptive.worker import process_events_background

    await process_events_background(session_id, events)
