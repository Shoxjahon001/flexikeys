"""Benchmark: insert 500 interaction_events in < 1s."""
from __future__ import annotations

import time
import uuid
from datetime import UTC, datetime

import pytest
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession


@pytest.mark.asyncio
async def test_interaction_events_bulk_insert_benchmark(db_session: AsyncSession) -> None:
    # Set up prerequisites
    parent_id = uuid.uuid4()
    child_id = uuid.uuid4()
    session_id = uuid.uuid4()

    await db_session.execute(text("""
        INSERT INTO users (id, role) VALUES (:id, 'parent')
    """), {"id": str(parent_id)})

    await db_session.execute(text("""
        INSERT INTO children (id, parent_id, display_name, learning_language)
        VALUES (:id, :parent_id, 'BenchChild', 'en')
    """), {"id": str(child_id), "parent_id": str(parent_id)})

    await db_session.execute(text("""
        INSERT INTO learning_sessions (id, child_id, language)
        VALUES (:id, :child_id, 'en')
    """), {"id": str(session_id), "child_id": str(child_id)})

    await db_session.flush()

    # Build 500 event rows — all in July 2026 so they hit the same partition
    batch_id = uuid.uuid4()
    rows = [
        {
            "session_id": str(session_id),
            "occurred_at": datetime(2026, 7, 10, 12, 0, i % 60, tzinfo=UTC).isoformat(),
            "event_type": "keystroke",
            "skill_key": f"en:letter:{chr(ord('a') + i % 26)}",
            "ingest_batch_id": str(batch_id),
            "payload": f'{{"latency_ms": {100 + i}}}',
        }
        for i in range(500)
    ]

    start = time.perf_counter()

    # Use executemany for bulk insert
    await db_session.execute(
        text("""
            INSERT INTO interaction_events
                (session_id, occurred_at, event_type, skill_key, ingest_batch_id, payload)
            VALUES
                (:session_id, :occurred_at::timestamptz, :event_type,
                 :skill_key, :ingest_batch_id::uuid, :payload::jsonb)
        """),
        rows,
    )
    await db_session.flush()

    elapsed = time.perf_counter() - start

    assert elapsed < 1.0, f"Bulk insert of 500 events took {elapsed:.3f}s — expected < 1s"
    print(f"\n  interaction_events bulk insert (500 rows): {elapsed*1000:.1f}ms")
