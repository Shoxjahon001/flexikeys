"""Add child_game_progress — client-reported offline progress backup/sync

Revision ID: e5f6a7b8c9d0
Revises: d4e5f6a7b8c9
Create Date: 2026-07-14
"""
from __future__ import annotations

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "e5f6a7b8c9d0"
down_revision = "d4e5f6a7b8c9"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Deliberately NOT the mastery-gated `level_progress` table (locked/
    # active/mastered is server-computed by the adaptive engine). This is a
    # client-reported backup/restore of the offline game's local progress —
    # keyed by free-text level_slug so it works before curriculum content for
    # all 16 levels is seeded, with no FK to `levels`.
    op.create_table(
        "child_game_progress",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "child_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("children.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("level_slug", sa.String(64), nullable=False),
        sa.Column("completed", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column("stars", sa.Integer(), nullable=False, server_default="0"),
        sa.Column(
            "completed_activities",
            postgresql.JSONB,
            nullable=False,
            server_default="[]",
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("NOW()"),
            nullable=False,
        ),
        sa.UniqueConstraint("child_id", "level_slug", name="uq_child_game_progress_child_level"),
    )
    op.create_index("ix_child_game_progress_child_id", "child_game_progress", ["child_id"])


def downgrade() -> None:
    op.drop_index("ix_child_game_progress_child_id", table_name="child_game_progress")
    op.drop_table("child_game_progress")
