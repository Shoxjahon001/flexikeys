from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Index, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from flexikeys.core.db import Base


class AacEvent(Base):
    """
    One "My Voice" AAC card tap, synced from the client's offline-first
    drift log (see app/lib/features/aac/data/aac_event_repository.dart).

    Minimal-PII by design: card_id/category/sentence_spoken/language are
    vocabulary content, not identity — no child name, photo, or free-text
    beyond the pre-authored (or parent-typed custom-card) sentence itself.
    """

    __tablename__ = "aac_events"
    __table_args__ = (
        Index("ix_aac_events_child_id_tapped_at", "child_id", "tapped_at"),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    child_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("children.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )
    card_id: Mapped[str] = mapped_column(String(64), nullable=False)
    category: Mapped[str] = mapped_column(String(32), nullable=False)
    sentence_spoken: Mapped[str] = mapped_column(String(500), nullable=False)
    language: Mapped[str] = mapped_column(String(10), nullable=False)
    tapped_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    ingest_batch_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), nullable=False, index=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
