from __future__ import annotations

import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import (
    BigInteger,
    DateTime,
    Enum,
    ForeignKey,
    Index,
    PrimaryKeyConstraint,
    String,
    func,
)
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column

from flexikeys.core.db import Base
from flexikeys.core.enums import EventType


class LearningSession(Base):
    __tablename__ = "learning_sessions"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    child_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("children.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )
    language: Mapped[str] = mapped_column(String(10), nullable=False)
    started_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    ended_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    device_info: Mapped[dict[str, Any] | None] = mapped_column(JSONB, nullable=True)
    client_version: Mapped[str | None] = mapped_column(String(32), nullable=True)


class InteractionEvent(Base):
    """Monthly-partitioned telemetry table. PK is composite (id, occurred_at)."""

    __tablename__ = "interaction_events"
    __table_args__ = (
        PrimaryKeyConstraint("id", "occurred_at"),
        Index("ix_interaction_events_session_id", "session_id"),
        Index("ix_interaction_events_skill_key_occurred_at", "skill_key", "occurred_at"),
    )

    id: Mapped[int] = mapped_column(BigInteger, autoincrement=True, nullable=False)
    session_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("learning_sessions.id", ondelete="RESTRICT"),
        nullable=False,
    )
    occurred_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    event_type: Mapped[EventType] = mapped_column(
        Enum(EventType, name="event_type", create_type=False), nullable=False
    )
    item_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("items.id"), nullable=True
    )
    skill_key: Mapped[str | None] = mapped_column(String(200), nullable=True)
    payload: Mapped[dict[str, Any] | None] = mapped_column(JSONB, nullable=True)
    ingest_batch_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), nullable=True)
