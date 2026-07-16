"""Initial schema — all tables

Revision ID: a1b2c3d4e5f6
Revises:
Create Date: 2026-07-10
"""
from __future__ import annotations

from typing import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "a1b2c3d4e5f6"
down_revision: str | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

# Convenience alias
PUUID = postgresql.UUID(as_uuid=True)
PJSONB = postgresql.JSONB()

_TABLES_WITH_UPDATED_AT = [
    "users", "children", "adaptation_profiles", "wallets",
    "level_progress", "classes", "assignments",
    "ai_conversations", "notifications",
]


def upgrade() -> None:
    # ── Extensions ────────────────────────────────────────────────────────────
    op.execute("CREATE EXTENSION IF NOT EXISTS citext")

    # ── Enum types ────────────────────────────────────────────────────────────
    op.execute("CREATE TYPE user_role AS ENUM ('parent', 'teacher', 'admin')")
    op.execute("CREATE TYPE oauth_provider AS ENUM ('google', 'apple')")
    op.execute("CREATE TYPE learning_language AS ENUM ('en', 'uz', 'ru')")
    op.execute("CREATE TYPE lesson_type AS ENUM ('typing', 'drawing', 'listening', 'story')")
    op.execute(
        "CREATE TYPE item_type AS ENUM "
        "('letter', 'number', 'word', 'sentence', 'shape', 'color', 'trace_path', 'story_page')"
    )
    op.execute(
        "CREATE TYPE event_type AS ENUM "
        "('keystroke', 'trace_point', 'item_shown', 'item_completed', 'hint_shown', 'break_taken')"
    )
    op.execute(
        "CREATE TYPE adaptation_reason_code AS ENUM "
        "('accuracy_drop', 'latency_rise', 'fatigue', 'mastery_gain', 'accidental_taps')"
    )
    op.execute("CREATE TYPE level_status AS ENUM ('locked', 'active', 'mastered')")
    op.execute(
        "CREATE TYPE reward_kind AS ENUM "
        "('badge', 'world', 'mascot_emotion', 'background', 'accessory')"
    )
    op.execute("CREATE TYPE reward_source AS ENUM ('earned', 'purchased_with_coins')")
    op.execute(
        "CREATE TYPE submission_status AS ENUM ('pending', 'in_progress', 'completed')"
    )
    op.execute(
        "CREATE TYPE report_scope AS ENUM "
        "('parent_daily', 'parent_weekly', 'teacher_class')"
    )
    op.execute("CREATE TYPE asset_kind AS ENUM ('audio', 'image', 'rive', 'font')")
    op.execute(
        "CREATE TYPE consent_type AS ENUM ('data_processing', 'coppa_parent_consent')"
    )

    # ── Trigger function ──────────────────────────────────────────────────────
    op.execute("""
        CREATE OR REPLACE FUNCTION set_updated_at()
        RETURNS TRIGGER LANGUAGE plpgsql AS $$
        BEGIN
            NEW.updated_at = NOW();
            RETURN NEW;
        END;
        $$
    """)

    # ── assets ────────────────────────────────────────────────────────────────
    op.create_table(
        "assets",
        sa.Column("id", PUUID, primary_key=True),
        sa.Column("kind", postgresql.ENUM(name="asset_kind", create_type=False), nullable=False),
        sa.Column("storage_key", sa.String(512), nullable=False, unique=True),
        sa.Column("mime", sa.String(128), nullable=False),
        sa.Column("bytes", sa.BigInteger(), nullable=False),
        sa.Column("checksum", sa.String(64), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("NOW()"), nullable=False),
    )

    # ── users ─────────────────────────────────────────────────────────────────
    op.create_table(
        "users",
        sa.Column("id", PUUID, primary_key=True),
        sa.Column("email", sa.Text(), nullable=True, unique=True),
        sa.Column("password_hash", sa.String(256), nullable=True),
        sa.Column("role", postgresql.ENUM(name="user_role", create_type=False), nullable=False),
        sa.Column("locale", sa.String(10), nullable=False, server_default="en"),
        sa.Column("timezone", sa.String(64), nullable=False, server_default="UTC"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("NOW()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("NOW()"), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.execute("ALTER TABLE users ALTER COLUMN email TYPE CITEXT USING email::CITEXT")

    # ── oauth_identities ──────────────────────────────────────────────────────
    op.create_table(
        "oauth_identities",
        sa.Column("id", PUUID, primary_key=True),
        sa.Column("user_id", PUUID, sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("provider", postgresql.ENUM(name="oauth_provider", create_type=False), nullable=False),
        sa.Column("provider_subject", sa.String(256), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("NOW()"), nullable=False),
        sa.UniqueConstraint("provider", "provider_subject"),
    )
    op.create_index("ix_oauth_identities_user_id", "oauth_identities", ["user_id"])

    # ── children ──────────────────────────────────────────────────────────────
    op.create_table(
        "children",
        sa.Column("id", PUUID, primary_key=True),
        sa.Column("parent_id", PUUID, sa.ForeignKey("users.id", ondelete="RESTRICT"), nullable=False),
        sa.Column("display_name", sa.String(64), nullable=False),
        sa.Column("avatar_id", sa.String(64), nullable=True),
        sa.Column("birth_year", sa.Integer(), nullable=True),
        sa.Column("learning_language", postgresql.ENUM(name="learning_language", create_type=False), nullable=False, server_default="en"),
        sa.Column("ui_language", sa.String(10), nullable=False, server_default="en"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("NOW()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("NOW()"), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index("ix_children_parent_id", "children", ["parent_id"])

    # ── parental_consents ─────────────────────────────────────────────────────
    op.create_table(
        "parental_consents",
        sa.Column("id", PUUID, primary_key=True),
        sa.Column("child_id", PUUID, sa.ForeignKey("children.id", ondelete="CASCADE"), nullable=False),
        sa.Column("consent_type", postgresql.ENUM(name="consent_type", create_type=False), nullable=False),
        sa.Column("granted_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("revoked_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index("ix_parental_consents_child_id", "parental_consents", ["child_id"])

    # ── refresh_tokens ────────────────────────────────────────────────────────
    op.create_table(
        "refresh_tokens",
        sa.Column("id", PUUID, primary_key=True),
        sa.Column("user_id", PUUID, sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("token_hash", sa.String(256), nullable=False, unique=True),
        sa.Column("device_info", sa.String(512), nullable=True),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("revoked_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("NOW()"), nullable=False),
    )
    op.create_index("ix_refresh_tokens_user_id", "refresh_tokens", ["user_id"])

    # ── curriculum_versions ───────────────────────────────────────────────────
    op.create_table(
        "curriculum_versions",
        sa.Column("id", PUUID, primary_key=True),
        sa.Column("version", sa.String(32), nullable=False, unique=True),
        sa.Column("published_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("checksum", sa.String(64), nullable=False),
    )

    # ── levels ────────────────────────────────────────────────────────────────
    op.create_table(
        "levels",
        sa.Column("id", PUUID, primary_key=True),
        sa.Column("version_id", PUUID, sa.ForeignKey("curriculum_versions.id", ondelete="CASCADE"), nullable=False),
        sa.Column("ordinal", sa.Integer(), nullable=False),
        sa.Column("slug", sa.String(64), nullable=False),
        sa.Column("unlock_mastery_threshold", sa.Numeric(5, 4), nullable=False, server_default="0.8000"),
    )
    op.create_index("ix_levels_version_id", "levels", ["version_id"])

    # ── lessons ───────────────────────────────────────────────────────────────
    op.create_table(
        "lessons",
        sa.Column("id", PUUID, primary_key=True),
        sa.Column("level_id", PUUID, sa.ForeignKey("levels.id", ondelete="CASCADE"), nullable=False),
        sa.Column("ordinal", sa.Integer(), nullable=False),
        sa.Column("slug", sa.String(64), nullable=False),
        sa.Column("lesson_type", postgresql.ENUM(name="lesson_type", create_type=False), nullable=False),
    )
    op.create_index("ix_lessons_level_id", "lessons", ["level_id"])

    # ── items ─────────────────────────────────────────────────────────────────
    op.create_table(
        "items",
        sa.Column("id", PUUID, primary_key=True),
        sa.Column("lesson_id", PUUID, sa.ForeignKey("lessons.id", ondelete="CASCADE"), nullable=False),
        sa.Column("ordinal", sa.Integer(), nullable=False),
        sa.Column("item_type", postgresql.ENUM(name="item_type", create_type=False), nullable=False),
        sa.Column("skill_key", sa.String(200), nullable=False),
        sa.Column("payload", PJSONB, nullable=True),
    )
    op.create_index("ix_items_lesson_id", "items", ["lesson_id"])
    op.create_index("ix_items_skill_key", "items", ["skill_key"])

    # ── item_localizations ────────────────────────────────────────────────────
    op.create_table(
        "item_localizations",
        sa.Column("id", PUUID, primary_key=True),
        sa.Column("item_id", PUUID, sa.ForeignKey("items.id", ondelete="CASCADE"), nullable=False),
        sa.Column("language", sa.String(10), nullable=False),
        sa.Column("text", sa.Text(), nullable=True),
        sa.Column("audio_asset_id", PUUID, sa.ForeignKey("assets.id"), nullable=True),
        sa.Column("image_asset_id", PUUID, sa.ForeignKey("assets.id"), nullable=True),
        sa.Column("extra_audio_asset_id", PUUID, sa.ForeignKey("assets.id"), nullable=True),
        sa.UniqueConstraint("item_id", "language"),
    )
    op.create_index("ix_item_localizations_item_id", "item_localizations", ["item_id"])

    # ── learning_sessions ─────────────────────────────────────────────────────
    op.create_table(
        "learning_sessions",
        sa.Column("id", PUUID, primary_key=True),
        sa.Column("child_id", PUUID, sa.ForeignKey("children.id", ondelete="RESTRICT"), nullable=False),
        sa.Column("language", sa.String(10), nullable=False),
        sa.Column("started_at", sa.DateTime(timezone=True), server_default=sa.text("NOW()"), nullable=False),
        sa.Column("ended_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("device_info", PJSONB, nullable=True),
        sa.Column("client_version", sa.String(32), nullable=True),
    )
    op.create_index("ix_learning_sessions_child_id", "learning_sessions", ["child_id"])

    # ── interaction_events (partitioned by month) ─────────────────────────────
    op.execute("CREATE SEQUENCE interaction_events_id_seq AS BIGINT")
    op.execute("""
        CREATE TABLE interaction_events (
            id          BIGINT      NOT NULL DEFAULT nextval('interaction_events_id_seq'),
            session_id  UUID        NOT NULL REFERENCES learning_sessions(id),
            occurred_at TIMESTAMPTZ NOT NULL,
            event_type  event_type  NOT NULL,
            item_id     UUID        REFERENCES items(id),
            skill_key   VARCHAR(200),
            payload     JSONB,
            ingest_batch_id UUID,
            CONSTRAINT interaction_events_pkey PRIMARY KEY (id, occurred_at)
        ) PARTITION BY RANGE (occurred_at)
    """)
    op.execute(
        "CREATE INDEX ix_interaction_events_session_id "
        "ON interaction_events (session_id)"
    )
    op.execute(
        "CREATE INDEX ix_interaction_events_skill_key_occurred_at "
        "ON interaction_events (skill_key, occurred_at)"
    )
    # Monthly partitions for 2026 and 2027
    for year in (2026, 2027):
        for month in range(1, 13):
            from_date = f"{year}-{month:02d}-01"
            to_year, to_month = (year + 1, 1) if month == 12 else (year, month + 1)
            to_date = f"{to_year}-{to_month:02d}-01"
            pname = f"interaction_events_{year}_{month:02d}"
            op.execute(
                f"CREATE TABLE {pname} PARTITION OF interaction_events "
                f"FOR VALUES FROM ('{from_date}') TO ('{to_date}')"
            )

    # ── skill_mastery ─────────────────────────────────────────────────────────
    op.create_table(
        "skill_mastery",
        sa.Column("id", PUUID, primary_key=True),
        sa.Column("child_id", PUUID, sa.ForeignKey("children.id", ondelete="CASCADE"), nullable=False),
        sa.Column("language", sa.String(10), nullable=False),
        sa.Column("skill_key", sa.String(200), nullable=False),
        sa.Column("p_known", sa.Numeric(5, 4), nullable=False, server_default="0.1000"),
        sa.Column("attempts", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("correct", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("ewma_accuracy", sa.Numeric(5, 4), nullable=True),
        sa.Column("ewma_latency_ms", sa.Numeric(8, 2), nullable=True),
        sa.Column("last_seen_at", sa.DateTime(timezone=True), nullable=True),
        sa.UniqueConstraint("child_id", "language", "skill_key"),
    )
    op.create_index("ix_skill_mastery_child_id", "skill_mastery", ["child_id"])

    # ── adaptation_profiles ───────────────────────────────────────────────────
    op.create_table(
        "adaptation_profiles",
        sa.Column("id", PUUID, primary_key=True),
        sa.Column("child_id", PUUID, sa.ForeignKey("children.id", ondelete="CASCADE"), nullable=False, unique=True),
        sa.Column("params", PJSONB, nullable=False, server_default="{}"),
        sa.Column("version", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("NOW()"), nullable=False),
    )
    op.create_index("ix_adaptation_profiles_child_id", "adaptation_profiles", ["child_id"])

    # ── adaptation_changes ────────────────────────────────────────────────────
    op.create_table(
        "adaptation_changes",
        sa.Column("id", PUUID, primary_key=True),
        sa.Column("child_id", PUUID, sa.ForeignKey("children.id", ondelete="CASCADE"), nullable=False),
        sa.Column("changed_at", sa.DateTime(timezone=True), server_default=sa.text("NOW()"), nullable=False),
        sa.Column("param", sa.String(64), nullable=False),
        sa.Column("old_value", sa.Text(), nullable=True),
        sa.Column("new_value", sa.Text(), nullable=True),
        sa.Column("reason_code", postgresql.ENUM(name="adaptation_reason_code", create_type=False), nullable=False),
        sa.Column("explanation_key", sa.String(128), nullable=True),
    )
    op.create_index("ix_adaptation_changes_child_id", "adaptation_changes", ["child_id"])

    # ── repetition_queue ──────────────────────────────────────────────────────
    op.create_table(
        "repetition_queue",
        sa.Column("id", PUUID, primary_key=True),
        sa.Column("child_id", PUUID, sa.ForeignKey("children.id", ondelete="CASCADE"), nullable=False),
        sa.Column("language", sa.String(10), nullable=False),
        sa.Column("skill_key", sa.String(200), nullable=False),
        sa.Column("due_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("interval_days", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("ease", sa.Numeric(4, 2), nullable=False, server_default="2.50"),
        sa.Column("lapses", sa.Integer(), nullable=False, server_default="0"),
        sa.UniqueConstraint("child_id", "language", "skill_key"),
    )
    op.create_index("ix_repetition_queue_child_id", "repetition_queue", ["child_id"])
    op.create_index("ix_repetition_queue_due_at", "repetition_queue", ["due_at"])

    # ── level_progress ────────────────────────────────────────────────────────
    op.create_table(
        "level_progress",
        sa.Column("id", PUUID, primary_key=True),
        sa.Column("child_id", PUUID, sa.ForeignKey("children.id", ondelete="CASCADE"), nullable=False),
        sa.Column("language", sa.String(10), nullable=False),
        sa.Column("level_id", PUUID, sa.ForeignKey("levels.id"), nullable=False),
        sa.Column("status", postgresql.ENUM(name="level_status", create_type=False), nullable=False, server_default="locked"),
        sa.Column("mastered_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("NOW()"), nullable=False),
        sa.UniqueConstraint("child_id", "language", "level_id"),
    )
    op.create_index("ix_level_progress_child_id", "level_progress", ["child_id"])
    op.create_index("ix_level_progress_level_id", "level_progress", ["level_id"])

    # ── wallets ───────────────────────────────────────────────────────────────
    op.create_table(
        "wallets",
        sa.Column("child_id", PUUID, sa.ForeignKey("children.id", ondelete="CASCADE"), primary_key=True),
        sa.Column("coins", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("stars", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("NOW()"), nullable=False),
    )

    # ── reward_definitions ────────────────────────────────────────────────────
    op.create_table(
        "reward_definitions",
        sa.Column("id", PUUID, primary_key=True),
        sa.Column("kind", postgresql.ENUM(name="reward_kind", create_type=False), nullable=False),
        sa.Column("slug", sa.String(128), nullable=False, unique=True),
        sa.Column("cost_coins", sa.Integer(), nullable=True),
        sa.Column("unlock_rule", PJSONB, nullable=True),
    )

    # ── reward_grants ─────────────────────────────────────────────────────────
    op.create_table(
        "reward_grants",
        sa.Column("id", PUUID, primary_key=True),
        sa.Column("child_id", PUUID, sa.ForeignKey("children.id", ondelete="CASCADE"), nullable=False),
        sa.Column("reward_definition_id", PUUID, sa.ForeignKey("reward_definitions.id"), nullable=False),
        sa.Column("granted_at", sa.DateTime(timezone=True), server_default=sa.text("NOW()"), nullable=False),
        sa.Column("source", postgresql.ENUM(name="reward_source", create_type=False), nullable=False),
        sa.UniqueConstraint("child_id", "reward_definition_id"),
    )
    op.create_index("ix_reward_grants_child_id", "reward_grants", ["child_id"])
    op.create_index("ix_reward_grants_reward_definition_id", "reward_grants", ["reward_definition_id"])

    # ── daily_activity ────────────────────────────────────────────────────────
    op.create_table(
        "daily_activity",
        sa.Column("id", PUUID, primary_key=True),
        sa.Column("child_id", PUUID, sa.ForeignKey("children.id", ondelete="CASCADE"), nullable=False),
        sa.Column("date", sa.Date(), nullable=False),
        sa.Column("seconds_active", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("items_completed", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("avg_accuracy", sa.Numeric(5, 4), nullable=True),
        sa.UniqueConstraint("child_id", "date"),
    )
    op.create_index("ix_daily_activity_child_id", "daily_activity", ["child_id"])

    # ── classes ───────────────────────────────────────────────────────────────
    op.create_table(
        "classes",
        sa.Column("id", PUUID, primary_key=True),
        sa.Column("teacher_id", PUUID, sa.ForeignKey("users.id", ondelete="RESTRICT"), nullable=False),
        sa.Column("name", sa.String(128), nullable=False),
        sa.Column("join_code", sa.String(16), nullable=False, unique=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("NOW()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("NOW()"), nullable=False),
    )
    op.create_index("ix_classes_teacher_id", "classes", ["teacher_id"])

    # ── class_enrollments ─────────────────────────────────────────────────────
    op.create_table(
        "class_enrollments",
        sa.Column("id", PUUID, primary_key=True),
        sa.Column("class_id", PUUID, sa.ForeignKey("classes.id", ondelete="CASCADE"), nullable=False),
        sa.Column("child_id", PUUID, sa.ForeignKey("children.id", ondelete="CASCADE"), nullable=False),
        sa.Column("enrolled_at", sa.DateTime(timezone=True), server_default=sa.text("NOW()"), nullable=False),
        sa.UniqueConstraint("class_id", "child_id"),
    )
    op.create_index("ix_class_enrollments_class_id", "class_enrollments", ["class_id"])
    op.create_index("ix_class_enrollments_child_id", "class_enrollments", ["child_id"])

    # ── assignments ───────────────────────────────────────────────────────────
    op.create_table(
        "assignments",
        sa.Column("id", PUUID, primary_key=True),
        sa.Column("class_id", PUUID, sa.ForeignKey("classes.id", ondelete="CASCADE"), nullable=False),
        sa.Column("level_id", PUUID, sa.ForeignKey("levels.id"), nullable=True),
        sa.Column("lesson_id", PUUID, sa.ForeignKey("lessons.id"), nullable=True),
        sa.Column("due_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("instructions", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("NOW()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("NOW()"), nullable=False),
    )
    op.create_index("ix_assignments_class_id", "assignments", ["class_id"])

    # ── assignment_status ─────────────────────────────────────────────────────
    op.create_table(
        "assignment_status",
        sa.Column("id", PUUID, primary_key=True),
        sa.Column("assignment_id", PUUID, sa.ForeignKey("assignments.id", ondelete="CASCADE"), nullable=False),
        sa.Column("child_id", PUUID, sa.ForeignKey("children.id", ondelete="CASCADE"), nullable=False),
        sa.Column("status", postgresql.ENUM(name="submission_status", create_type=False), nullable=False, server_default="pending"),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.UniqueConstraint("assignment_id", "child_id"),
    )
    op.create_index("ix_assignment_status_assignment_id", "assignment_status", ["assignment_id"])
    op.create_index("ix_assignment_status_child_id", "assignment_status", ["child_id"])

    # ── ai_conversations ──────────────────────────────────────────────────────
    op.create_table(
        "ai_conversations",
        sa.Column("id", PUUID, primary_key=True),
        sa.Column("parent_user_id", PUUID, sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("title", sa.String(256), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("NOW()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("NOW()"), nullable=False),
    )
    op.create_index("ix_ai_conversations_parent_user_id", "ai_conversations", ["parent_user_id"])

    # ── ai_messages ───────────────────────────────────────────────────────────
    op.create_table(
        "ai_messages",
        sa.Column("id", PUUID, primary_key=True),
        sa.Column("conversation_id", PUUID, sa.ForeignKey("ai_conversations.id", ondelete="CASCADE"), nullable=False),
        sa.Column("role", sa.String(16), nullable=False),
        sa.Column("content", sa.Text(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("NOW()"), nullable=False),
    )
    op.create_index("ix_ai_messages_conversation_id", "ai_messages", ["conversation_id"])

    # ── notifications ─────────────────────────────────────────────────────────
    op.create_table(
        "notifications",
        sa.Column("id", PUUID, primary_key=True),
        sa.Column("user_id", PUUID, sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("kind", sa.String(64), nullable=False),
        sa.Column("payload", PJSONB, nullable=True),
        sa.Column("sent_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("read_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("NOW()"), nullable=False),
    )
    op.create_index("ix_notifications_user_id", "notifications", ["user_id"])

    # ── reports ───────────────────────────────────────────────────────────────
    op.create_table(
        "reports",
        sa.Column("id", PUUID, primary_key=True),
        sa.Column("scope", postgresql.ENUM(name="report_scope", create_type=False), nullable=False),
        sa.Column("subject_id", PUUID, nullable=False),
        sa.Column("period", sa.String(32), nullable=False),
        sa.Column("payload", PJSONB, nullable=False, server_default="{}"),
        sa.Column("pdf_asset_id", PUUID, sa.ForeignKey("assets.id"), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("NOW()"), nullable=False),
    )
    op.create_index("ix_reports_subject_id", "reports", ["subject_id"])

    # ── updated_at triggers ───────────────────────────────────────────────────
    for table in _TABLES_WITH_UPDATED_AT:
        op.execute(
            f"CREATE TRIGGER trg_{table}_updated_at "
            f"BEFORE UPDATE ON {table} "
            f"FOR EACH ROW EXECUTE FUNCTION set_updated_at()"
        )


def downgrade() -> None:
    # Drop triggers first
    for table in reversed(_TABLES_WITH_UPDATED_AT):
        op.execute(f"DROP TRIGGER IF EXISTS trg_{table}_updated_at ON {table}")

    # Drop tables in reverse FK dependency order
    op.drop_table("reports")
    op.drop_table("notifications")
    op.drop_table("ai_messages")
    op.drop_table("ai_conversations")
    op.drop_table("assignment_status")
    op.drop_table("assignments")
    op.drop_table("class_enrollments")
    op.drop_table("classes")
    op.drop_table("daily_activity")
    op.drop_table("reward_grants")
    op.drop_table("reward_definitions")
    op.drop_table("wallets")
    op.drop_table("level_progress")
    op.drop_table("repetition_queue")
    op.drop_table("adaptation_changes")
    op.drop_table("adaptation_profiles")
    op.drop_table("skill_mastery")

    # Drop interaction_events partitions then parent
    for year in (2026, 2027):
        for month in range(1, 13):
            op.execute(f"DROP TABLE IF EXISTS interaction_events_{year}_{month:02d}")
    op.execute("DROP TABLE IF EXISTS interaction_events")
    op.execute("DROP SEQUENCE IF EXISTS interaction_events_id_seq")

    op.drop_table("learning_sessions")
    op.drop_table("item_localizations")
    op.drop_table("items")
    op.drop_table("lessons")
    op.drop_table("levels")
    op.drop_table("curriculum_versions")
    op.drop_table("refresh_tokens")
    op.drop_table("parental_consents")
    op.drop_table("children")
    op.drop_table("oauth_identities")
    op.drop_table("users")
    op.drop_table("assets")

    op.execute("DROP FUNCTION IF EXISTS set_updated_at()")

    for enum_name in (
        "consent_type", "asset_kind", "report_scope", "submission_status",
        "reward_source", "reward_kind", "level_status", "adaptation_reason_code",
        "event_type", "item_type", "lesson_type", "learning_language",
        "oauth_provider", "user_role",
    ):
        op.execute(f"DROP TYPE IF EXISTS {enum_name}")

    op.execute("DROP EXTENSION IF EXISTS citext")
