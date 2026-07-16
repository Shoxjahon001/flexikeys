"""Seed initial reward definitions for Cloud Shop

Revision ID: d4e5f6a7b8c9
Revises: c3d4e5f6a7b8
Create Date: 2026-07-13
"""
from __future__ import annotations

import json
import uuid

import sqlalchemy as sa
from alembic import op

revision = "d4e5f6a7b8c9"
down_revision = "b2c3d4e5f6a7"
branch_labels = None
depends_on = None

# Stable UUIDs so this migration is idempotent on re-run in dev
_DEFINITIONS = [
    # Badges (earned, no cost)
    {
        "id": "11000000-0000-0000-0000-000000000001",
        "kind": "badge",
        "slug": "practiced_3_days",
        "cost_coins": None,
        "unlock_rule": {"streak_days": 3},
    },
    {
        "id": "11000000-0000-0000-0000-000000000002",
        "kind": "badge",
        "slug": "mastered_5_letters",
        "cost_coins": None,
        "unlock_rule": {"mastered_letters": 5},
    },
    {
        "id": "11000000-0000-0000-0000-000000000003",
        "kind": "badge",
        "slug": "effort_milestone",
        "cost_coins": None,
        "unlock_rule": {"total_items_completed": 50},
    },
    # Mascot accessories (purchasable with coins)
    {
        "id": "22000000-0000-0000-0000-000000000001",
        "kind": "accessory",
        "slug": "cloud_hat",
        "cost_coins": 50,
        "unlock_rule": None,
    },
    {
        "id": "22000000-0000-0000-0000-000000000002",
        "kind": "accessory",
        "slug": "cloud_scarf",
        "cost_coins": 50,
        "unlock_rule": None,
    },
    # World themes
    {
        "id": "33000000-0000-0000-0000-000000000001",
        "kind": "world",
        "slug": "world_ocean",
        "cost_coins": 100,
        "unlock_rule": None,
    },
    {
        "id": "33000000-0000-0000-0000-000000000002",
        "kind": "world",
        "slug": "world_forest",
        "cost_coins": 100,
        "unlock_rule": None,
    },
    # Backgrounds
    {
        "id": "44000000-0000-0000-0000-000000000001",
        "kind": "background",
        "slug": "bg_stars",
        "cost_coins": 30,
        "unlock_rule": None,
    },
]


def upgrade() -> None:
    conn = op.get_bind()
    for d in _DEFINITIONS:
        conn.execute(
            sa.text(
                """
                INSERT INTO reward_definitions (id, kind, slug, cost_coins, unlock_rule)
                VALUES (:id, :kind, :slug, :cost_coins, CAST(:unlock_rule AS jsonb))
                ON CONFLICT (slug) DO NOTHING
                """
            ),
            {
                "id": d["id"],
                "kind": d["kind"],
                "slug": d["slug"],
                "cost_coins": d["cost_coins"],
                "unlock_rule": None if d["unlock_rule"] is None
                    else json.dumps(d["unlock_rule"]),
            },
        )


def downgrade() -> None:
    op.execute(
        "DELETE FROM reward_definitions WHERE slug IN ({})".format(
            ", ".join(f"'{d['slug']}'" for d in _DEFINITIONS)
        )
    )