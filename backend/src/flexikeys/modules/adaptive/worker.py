"""
Adaptive metric processing worker.

This module is invoked as a FastAPI BackgroundTask today.
STUB #2: Replace with ARQ (async Redis Queue) worker when volume warrants it.
See issue #adaptive-worker-arq.

The function is async so it can be awaited directly or enqueued via ARQ with
zero refactoring — ARQ calls `await func(ctx, *args)`.
"""
from __future__ import annotations

import logging
from typing import Any

logger = logging.getLogger(__name__)


async def process_events_background(
    session_id: str,
    events: list[dict[str, Any]],
) -> None:
    """
    Process a batch of interaction events and update the adaptive profile.

    Runs after a successful event ingest — either in-process via FastAPI
    BackgroundTasks or as an ARQ job.
    """
    from flexikeys.core.db import AsyncSessionFactory
    from flexikeys.modules.adaptive.service import AdaptiveService
    from flexikeys.modules.sessions.repository import SessionRepository

    if not events:
        return

    async with AsyncSessionFactory() as db:
        repo = SessionRepository(db)
        session = await repo.get_session_by_id_str(session_id)
        if session is None:
            logger.warning("metric job: session %s not found", session_id)
            return

        child_id = session.child_id
        language = session.language.value if hasattr(session.language, "value") else str(session.language)

        svc = AdaptiveService(db)
        await svc.process_session_events(
            child_id=child_id,
            language=language,
            session_id=session_id,
            events=events,
        )
        await db.commit()
