#!/usr/bin/env python3
"""
Idempotent dev seed script.
Run from the backend/ directory:
    APP_SECRET_KEY=x DATABASE_URL=... python scripts/seed.py
"""
from __future__ import annotations

import asyncio
import hashlib
import os
import sys
import uuid
from datetime import UTC, datetime, timedelta

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from flexikeys.core.config import get_settings
from flexikeys.core.security import hash_password

# Fixed UUIDs so the seed is idempotent
ADMIN_ID = uuid.UUID("00000000-0000-0000-0000-000000000001")
PARENT_ID = uuid.UUID("00000000-0000-0000-0000-000000000002")
TEACHER_ID = uuid.UUID("00000000-0000-0000-0000-000000000003")
CHILD_AISHA_ID = uuid.UUID("00000000-0000-0000-0000-000000000010")
CHILD_BOBUR_ID = uuid.UUID("00000000-0000-0000-0000-000000000011")
CLASS_ID = uuid.UUID("00000000-0000-0000-0000-000000000020")
CURRICULUM_V1_ID = uuid.UUID("00000000-0000-0000-0000-000000000030")
LEVEL_1_ID = uuid.UUID("00000000-0000-0000-0000-000000000031")
LESSON_1_ID = uuid.UUID("00000000-0000-0000-0000-000000000032")


async def seed(session: AsyncSession) -> None:
    env = get_settings().app_env
    if env == "production":
        print("Skipping seed: APP_ENV=production")
        return

    print("Seeding dev data …")

    # ── Users ─────────────────────────────────────────────────────────────────
    await session.execute(text("""
        INSERT INTO users (id, email, password_hash, role, locale, timezone)
        VALUES
            (:admin_id, 'admin@flexikeys.app', :admin_pw, 'admin', 'en', 'UTC'),
            (:parent_id, 'parent@demo.app', :demo_pw, 'parent', 'en', 'Asia/Tashkent'),
            (:teacher_id, 'teacher@demo.app', :demo_pw, 'teacher', 'uz', 'Asia/Tashkent')
        ON CONFLICT (id) DO NOTHING
    """), {
        "admin_id": str(ADMIN_ID),
        "parent_id": str(PARENT_ID),
        "teacher_id": str(TEACHER_ID),
        "admin_pw": hash_password("admin-secret-change-me"),
        "demo_pw": hash_password("demo1234"),
    })

    # ── Children ──────────────────────────────────────────────────────────────
    await session.execute(text("""
        INSERT INTO children (id, parent_id, display_name, birth_year, learning_language, ui_language)
        VALUES
            (:aisha_id, :parent_id, 'Aisha', 2021, 'en', 'en'),
            (:bobur_id, :parent_id, 'Bobur', 2020, 'uz', 'uz')
        ON CONFLICT (id) DO NOTHING
    """), {
        "aisha_id": str(CHILD_AISHA_ID),
        "bobur_id": str(CHILD_BOBUR_ID),
        "parent_id": str(PARENT_ID),
    })

    # ── Parental consents ─────────────────────────────────────────────────────
    now = datetime.now(UTC)
    for child_id in (CHILD_AISHA_ID, CHILD_BOBUR_ID):
        for consent_type in ("data_processing", "coppa_parent_consent"):
            cid = uuid.uuid5(child_id, consent_type)
            await session.execute(text("""
                INSERT INTO parental_consents (id, child_id, consent_type, granted_at)
                VALUES (:id, :child_id, :consent_type, :granted_at)
                ON CONFLICT (id) DO NOTHING
            """), {
                "id": str(cid),
                "child_id": str(child_id),
                "consent_type": consent_type,
                "granted_at": now,
            })

    # ── Wallets ───────────────────────────────────────────────────────────────
    await session.execute(text("""
        INSERT INTO wallets (child_id, coins, stars)
        VALUES (:aisha_id, 0, 0), (:bobur_id, 12, 3)
        ON CONFLICT (child_id) DO NOTHING
    """), {"aisha_id": str(CHILD_AISHA_ID), "bobur_id": str(CHILD_BOBUR_ID)})

    # ── Adaptation profile for Bobur (shows adjusted params) ──────────────────
    bobur_profile_id = uuid.uuid5(CHILD_BOBUR_ID, "profile")
    await session.execute(text("""
        INSERT INTO adaptation_profiles (id, child_id, params, version)
        VALUES (:id, :child_id, CAST(:params AS jsonb), 3)
        ON CONFLICT (child_id) DO NOTHING
    """), {
        "id": str(bobur_profile_id),
        "child_id": str(CHILD_BOBUR_ID),
        "params": (
            '{"key_scale": 1.4, "key_spacing": 1.2, '
            '"dwell_time_ms": 120, "debounce_ms": 80, '
            '"hint_level": 2, "session_pacing": {"break_interval_min": 8}}'
        ),
    })

    # ── Teacher + class + enrollment ──────────────────────────────────────────
    await session.execute(text("""
        INSERT INTO classes (id, teacher_id, name, join_code)
        VALUES (:id, :teacher_id, 'FlexiKeys Demo Class', 'DEMO2026')
        ON CONFLICT (id) DO NOTHING
    """), {"id": str(CLASS_ID), "teacher_id": str(TEACHER_ID)})

    enrollment_id = uuid.uuid5(CLASS_ID, str(CHILD_AISHA_ID))
    await session.execute(text("""
        INSERT INTO class_enrollments (id, class_id, child_id)
        VALUES (:id, :class_id, :child_id)
        ON CONFLICT (id) DO NOTHING
    """), {
        "id": str(enrollment_id),
        "class_id": str(CLASS_ID),
        "child_id": str(CHILD_AISHA_ID),
    })

    # ── Curriculum Version 1 ──────────────────────────────────────────────────
    await session.execute(text("""
        INSERT INTO curriculum_versions (id, version, published_at, checksum)
        VALUES (:id, '1.0.0', :pub, 'seed-checksum-v1')
        ON CONFLICT (id) DO NOTHING
    """), {"id": str(CURRICULUM_V1_ID), "pub": now})

    # Level 1 — Letters
    await session.execute(text("""
        INSERT INTO levels (id, version_id, ordinal, slug, unlock_mastery_threshold)
        VALUES (:id, :version_id, 1, 'letters', 0.8000)
        ON CONFLICT (id) DO NOTHING
    """), {"id": str(LEVEL_1_ID), "version_id": str(CURRICULUM_V1_ID)})

    # Lesson 1 — Typing Letters
    await session.execute(text("""
        INSERT INTO lessons (id, level_id, ordinal, slug, lesson_type)
        VALUES (:id, :level_id, 1, 'typing-letters', 'typing')
        ON CONFLICT (id) DO NOTHING
    """), {"id": str(LESSON_1_ID), "level_id": str(LEVEL_1_ID)})

    # 26 letter items with localizations in en / uz / ru
    letters_en = list("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    letters_uz = list("ABCDEFGHIJKLMNOPQRSTUVWXYZ")  # Uzbek Latin uses same base
    letters_ru = list("АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ")

    for i, letter in enumerate(letters_en):
        item_id = uuid.uuid5(LESSON_1_ID, f"letter-{letter}")
        await session.execute(text("""
            INSERT INTO items (id, lesson_id, ordinal, item_type, skill_key, payload)
            VALUES (:id, :lesson_id, :ordinal, 'letter', :skill_key, CAST(:payload AS jsonb))
            ON CONFLICT (id) DO NOTHING
        """), {
            "id": str(item_id),
            "lesson_id": str(LESSON_1_ID),
            "ordinal": i + 1,
            "skill_key": f"en:letter:{letter.lower()}",
            "payload": f'{{"letter": "{letter}"}}',
        })

        localizations = [
            ("en", letters_en[i]),
            ("uz", letters_uz[i]),
            ("ru", letters_ru[i] if i < len(letters_ru) else letter),
        ]
        for lang, text_val in localizations:
            loc_id = uuid.uuid5(item_id, lang)
            await session.execute(text("""
                INSERT INTO item_localizations (id, item_id, language, text)
                VALUES (:id, :item_id, :language, :text)
                ON CONFLICT (id) DO NOTHING
            """), {
                "id": str(loc_id),
                "item_id": str(item_id),
                "language": lang,
                "text": text_val,
            })

    # ── Level progress for Aisha (level 1 active) ─────────────────────────────
    progress_id = uuid.uuid5(CHILD_AISHA_ID, "level1-en")
    await session.execute(text("""
        INSERT INTO level_progress (id, child_id, language, level_id, status)
        VALUES (:id, :child_id, 'en', :level_id, 'active')
        ON CONFLICT (id) DO NOTHING
    """), {
        "id": str(progress_id),
        "child_id": str(CHILD_AISHA_ID),
        "level_id": str(LEVEL_1_ID),
    })

    await session.commit()
    print("Seed complete.")


async def main() -> None:
    settings = get_settings()
    engine = create_async_engine(settings.database_url, echo=False)
    session_factory = async_sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)
    async with session_factory() as session:
        await seed(session)
    await engine.dispose()


if __name__ == "__main__":
    asyncio.run(main())
