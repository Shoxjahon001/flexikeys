from __future__ import annotations

import uuid
from datetime import datetime
from decimal import Decimal
from typing import Any

from sqlalchemy import (
    DateTime,
    Enum,
    ForeignKey,
    Integer,
    Numeric,
    String,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column

from flexikeys.core.db import Base
from flexikeys.core.enums import AdaptationReasonCode


class SkillMastery(Base):
    __tablename__ = "skill_mastery"
    __table_args__ = (UniqueConstraint("child_id", "language", "skill_key"),)

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    child_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("children.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    language: Mapped[str] = mapped_column(String(10), nullable=False)
    skill_key: Mapped[str] = mapped_column(String(200), nullable=False)
    p_known: Mapped[Decimal] = mapped_column(Numeric(5, 4), nullable=False, server_default="0.1000")
    attempts: Mapped[int] = mapped_column(Integer(), nullable=False, server_default="0")
    correct: Mapped[int] = mapped_column(Integer(), nullable=False, server_default="0")
    ewma_accuracy: Mapped[Decimal | None] = mapped_column(Numeric(5, 4), nullable=True)
    ewma_latency_ms: Mapped[Decimal | None] = mapped_column(Numeric(8, 2), nullable=True)
    last_seen_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class AdaptationProfile(Base):
    __tablename__ = "adaptation_profiles"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    child_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("children.id", ondelete="CASCADE"),
        nullable=False,
        unique=True,
        index=True,
    )
    params: Mapped[dict[str, Any]] = mapped_column(JSONB, nullable=False, server_default="{}")
    version: Mapped[int] = mapped_column(Integer(), nullable=False, server_default="1")
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )


class AdaptationChange(Base):
    __tablename__ = "adaptation_changes"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    child_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("children.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    changed_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    param: Mapped[str] = mapped_column(String(64), nullable=False)
    old_value: Mapped[str | None] = mapped_column(Text(), nullable=True)
    new_value: Mapped[str | None] = mapped_column(Text(), nullable=True)
    reason_code: Mapped[AdaptationReasonCode] = mapped_column(
        Enum(AdaptationReasonCode, name="adaptation_reason_code", create_type=False),
        nullable=False,
    )
    explanation_key: Mapped[str | None] = mapped_column(String(128), nullable=True)


class RepetitionQueue(Base):
    __tablename__ = "repetition_queue"
    __table_args__ = (UniqueConstraint("child_id", "language", "skill_key"),)

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    child_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("children.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    language: Mapped[str] = mapped_column(String(10), nullable=False)
    skill_key: Mapped[str] = mapped_column(String(200), nullable=False)
    due_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, index=True)
    interval_days: Mapped[int] = mapped_column(Integer(), nullable=False, server_default="1")
    ease: Mapped[Decimal] = mapped_column(Numeric(4, 2), nullable=False, server_default="2.50")
    lapses: Mapped[int] = mapped_column(Integer(), nullable=False, server_default="0")
