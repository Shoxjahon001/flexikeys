"""Add aac_events — synced "My Voice" AAC card-tap log

Revision ID: f6a7b8c9d0e1
Revises: e5f6a7b8c9d0
Create Date: 2026-07-24
"""
from __future__ import annotations

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "f6a7b8c9d0e1"
down_revision = "e5f6a7b8c9d0"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "aac_events",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "child_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("children.id", ondelete="RESTRICT"),
            nullable=False,
        ),
        sa.Column("card_id", sa.String(64), nullable=False),
        sa.Column("category", sa.String(32), nullable=False),
        sa.Column("sentence_spoken", sa.String(500), nullable=False),
        sa.Column("language", sa.String(10), nullable=False),
        sa.Column("tapped_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("ingest_batch_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("NOW()"),
            nullable=False,
        ),
    )
    op.create_index("ix_aac_events_child_id", "aac_events", ["child_id"])
    op.create_index("ix_aac_events_ingest_batch_id", "aac_events", ["ingest_batch_id"])
    op.create_index(
        "ix_aac_events_child_id_tapped_at", "aac_events", ["child_id", "tapped_at"]
    )


def downgrade() -> None:
    op.drop_index("ix_aac_events_child_id_tapped_at", table_name="aac_events")
    op.drop_index("ix_aac_events_ingest_batch_id", table_name="aac_events")
    op.drop_index("ix_aac_events_child_id", table_name="aac_events")
    op.drop_table("aac_events")
