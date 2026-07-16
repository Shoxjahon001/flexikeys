from __future__ import annotations

import uuid
from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import (
    Boolean,
    Date,
    DateTime,
    Enum,
    ForeignKey,
    Integer,
    Numeric,
    String,
    UniqueConstraint,
    func,
)
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column

from flexikeys.core.db import Base
from flexikeys.core.enums import LevelStatus


class LevelProgress(Base):
    __tablename__ = "level_progress"
    __table_args__ = (UniqueConstraint("child_id", "language", "level_id"),)

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    child_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("children.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    language: Mapped[str] = mapped_column(String(10), nullable=False)
    level_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("levels.id"), nullable=False, index=True
    )
    status: Mapped[LevelStatus] = mapped_column(
        Enum(LevelStatus, name="level_status", create_type=False),
        nullable=False,
        server_default="locked",
    )
    mastered_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )


class ChildGameProgress(Base):
    """Client-reported backup/restore of the offline game's local per-level
    progress. Deliberately separate from `LevelProgress` — that table's
    locked/active/mastered status is server-computed by the adaptive engine
    (mastery-gated progression is a non-negotiable product rule); this table
    is just "what does the child's device say," keyed by free-text
    level_slug so it works independent of curriculum seeding state.
    """

    __tablename__ = "child_game_progress"
    __table_args__ = (UniqueConstraint("child_id", "level_slug"),)

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    child_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("children.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    level_slug: Mapped[str] = mapped_column(String(64), nullable=False)
    completed: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default="false")
    stars: Mapped[int] = mapped_column(Integer(), nullable=False, server_default="0")
    completed_activities: Mapped[list[str]] = mapped_column(
        JSONB, nullable=False, server_default="[]"
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )


class DailyActivity(Base):
    __tablename__ = "daily_activity"
    __table_args__ = (UniqueConstraint("child_id", "date"),)

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    child_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("children.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    date: Mapped[date] = mapped_column(Date(), nullable=False)
    seconds_active: Mapped[int] = mapped_column(Integer(), nullable=False, server_default="0")
    items_completed: Mapped[int] = mapped_column(Integer(), nullable=False, server_default="0")
    avg_accuracy: Mapped[Decimal | None] = mapped_column(Numeric(5, 4), nullable=True)
