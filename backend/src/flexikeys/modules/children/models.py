from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import DateTime, Enum, ForeignKey, Integer, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from flexikeys.core.db import Base
from flexikeys.core.enums import LearningLanguage


class Child(Base):
    __tablename__ = "children"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    parent_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )
    display_name: Mapped[str] = mapped_column(String(64), nullable=False)
    avatar_id: Mapped[str | None] = mapped_column(String(64), nullable=True)
    birth_year: Mapped[int | None] = mapped_column(Integer(), nullable=True)
    learning_language: Mapped[LearningLanguage] = mapped_column(
        Enum(LearningLanguage, name="learning_language", create_type=False),
        nullable=False,
        server_default="en",
    )
    ui_language: Mapped[str] = mapped_column(String(10), nullable=False, server_default="en")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)