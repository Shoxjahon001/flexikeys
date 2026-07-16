from __future__ import annotations

import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import DateTime, Enum, ForeignKey, Integer, String, UniqueConstraint, func
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column

from flexikeys.core.db import Base
from flexikeys.core.enums import RewardKind, RewardSource


class Wallet(Base):
    __tablename__ = "wallets"

    child_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("children.id", ondelete="CASCADE"),
        primary_key=True,
    )
    coins: Mapped[int] = mapped_column(Integer(), nullable=False, server_default="0")
    stars: Mapped[int] = mapped_column(Integer(), nullable=False, server_default="0")
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )


class RewardDefinition(Base):
    __tablename__ = "reward_definitions"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    kind: Mapped[RewardKind] = mapped_column(
        Enum(RewardKind, name="reward_kind", create_type=False), nullable=False
    )
    slug: Mapped[str] = mapped_column(String(128), nullable=False, unique=True)
    cost_coins: Mapped[int | None] = mapped_column(Integer(), nullable=True)
    unlock_rule: Mapped[dict[str, Any] | None] = mapped_column(JSONB, nullable=True)


class RewardGrant(Base):
    __tablename__ = "reward_grants"
    __table_args__ = (UniqueConstraint("child_id", "reward_definition_id"),)

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    child_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("children.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    reward_definition_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("reward_definitions.id"),
        nullable=False,
        index=True,
    )
    granted_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    source: Mapped[RewardSource] = mapped_column(
        Enum(RewardSource, name="reward_source", create_type=False), nullable=False
    )
