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
from flexikeys.core.enums import AssetKind, ItemType, LessonType


class Asset(Base):
    __tablename__ = "assets"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    kind: Mapped[AssetKind] = mapped_column(
        Enum(AssetKind, name="asset_kind", create_type=False), nullable=False
    )
    storage_key: Mapped[str] = mapped_column(String(512), nullable=False, unique=True)
    mime: Mapped[str] = mapped_column(String(128), nullable=False)
    bytes: Mapped[int] = mapped_column(Integer(), nullable=False)
    checksum: Mapped[str] = mapped_column(String(64), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )


class CurriculumVersion(Base):
    __tablename__ = "curriculum_versions"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    version: Mapped[str] = mapped_column(String(32), nullable=False, unique=True)
    published_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    checksum: Mapped[str] = mapped_column(String(64), nullable=False)


class Level(Base):
    __tablename__ = "levels"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    version_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("curriculum_versions.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    ordinal: Mapped[int] = mapped_column(Integer(), nullable=False)
    slug: Mapped[str] = mapped_column(String(64), nullable=False)
    unlock_mastery_threshold: Mapped[Decimal] = mapped_column(
        Numeric(5, 4), nullable=False, server_default="0.8000"
    )


class Lesson(Base):
    __tablename__ = "lessons"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    level_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("levels.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    ordinal: Mapped[int] = mapped_column(Integer(), nullable=False)
    slug: Mapped[str] = mapped_column(String(64), nullable=False)
    lesson_type: Mapped[LessonType] = mapped_column(
        Enum(LessonType, name="lesson_type", create_type=False), nullable=False
    )


class Item(Base):
    __tablename__ = "items"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    lesson_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("lessons.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    ordinal: Mapped[int] = mapped_column(Integer(), nullable=False)
    item_type: Mapped[ItemType] = mapped_column(
        Enum(ItemType, name="item_type", create_type=False), nullable=False
    )
    skill_key: Mapped[str] = mapped_column(String(200), nullable=False, index=True)
    payload: Mapped[dict[str, Any] | None] = mapped_column(JSONB, nullable=True)


class ItemLocalization(Base):
    __tablename__ = "item_localizations"
    __table_args__ = (UniqueConstraint("item_id", "language"),)

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    item_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("items.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    language: Mapped[str] = mapped_column(String(10), nullable=False)
    text: Mapped[str | None] = mapped_column(Text(), nullable=True)
    audio_asset_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("assets.id"), nullable=True, index=True
    )
    image_asset_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("assets.id"), nullable=True, index=True
    )
    extra_audio_asset_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("assets.id"), nullable=True, index=True
    )
