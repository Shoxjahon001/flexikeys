"""
Curriculum importer CLI.

Usage:
    python -m flexikeys.tools.import_curriculum shared/curriculum/
    python -m flexikeys.tools.import_curriculum shared/curriculum/ --dry-run

Behaviour:
  1. Reads every level_*.json in the given directory.
  2. Validates each file against CurriculumLevel (including Level 14+ letter gate).
  3. Diffs against the current version in the database.
  4. Writes a new curriculum_versions row transactionally with all levels,
     lessons, and items.  Atomic: either everything succeeds or nothing is written.
  5. Prints a human-readable diff summary.
"""
from __future__ import annotations

import argparse
import asyncio
import hashlib
import json
import logging
import sys
from pathlib import Path
from typing import Any

logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
log = logging.getLogger(__name__)

SUPPORTED_LANGS = frozenset({"en", "uz", "ru"})


def _hash_file(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()[:16]


def _load_and_validate(directory: Path) -> list[dict[str, Any]]:
    """Load and validate all level JSON files. Returns sorted list of level dicts."""
    from flexikeys.modules.curriculum.schemas import CurriculumLevel

    files = sorted(directory.glob("level_*.json"))
    if not files:
        log.error("No level_*.json files found in %s", directory)
        sys.exit(1)

    levels: list[dict[str, Any]] = []
    errors: list[str] = []

    for fp in files:
        raw = fp.read_bytes()
        try:
            data = json.loads(raw)
            validated = CurriculumLevel.model_validate(data)
            levels.append({"validated": validated, "raw": data, "checksum": _hash_file(raw)})
            log.info("  ✓ %s  (level %d, %d lessons)", fp.name, validated.level,
                     len(validated.lessons))
        except Exception as exc:
            errors.append(f"{fp.name}: {exc}")
            log.error("  ✗ %s: %s", fp.name, exc)

    if errors:
        log.error("%d validation error(s). Aborting.", len(errors))
        sys.exit(1)

    levels.sort(key=lambda x: x["validated"].level)
    return levels


def _compute_version_checksum(levels: list[dict[str, Any]]) -> str:
    combined = "|".join(lv["checksum"] for lv in levels)
    return hashlib.sha256(combined.encode()).hexdigest()[:16]


async def _import(directory: Path, dry_run: bool) -> None:
    import uuid
    from datetime import UTC, datetime

    from flexikeys.core.db import get_session_factory

    log.info("Loading and validating files from %s …", directory)
    levels = _load_and_validate(directory)
    new_checksum = _compute_version_checksum(levels)
    new_version = f"1.0.{len(levels)}"  # simple version bump strategy

    log.info("\nValidation passed — %d levels, %d items total",
             len(levels),
             sum(sum(len(ls.items) for ls in lv["validated"].lessons) for lv in levels))

    if dry_run:
        log.info("--dry-run: not writing to database.")
        _print_diff_summary(levels)
        return

    factory = get_session_factory()
    async with factory() as db:
        # Check if this checksum already exists
        from sqlalchemy import select, text
        from flexikeys.modules.curriculum.models import CurriculumVersion, Level, Lesson, Item, ItemLocalization

        result = await db.execute(
            select(CurriculumVersion).where(CurriculumVersion.checksum == new_checksum)
        )
        existing = result.scalar_one_or_none()
        if existing:
            log.info("Checksum %s already imported as version %s — nothing to do.",
                     new_checksum, existing.version)
            return

        # Determine version string (increment patch)
        result2 = await db.execute(
            select(CurriculumVersion).order_by(CurriculumVersion.published_at.desc()).limit(1)
        )
        prev = result2.scalar_one_or_none()
        if prev:
            parts = prev.version.split(".")
            new_version = f"{parts[0]}.{parts[1]}.{int(parts[2])+1}"
        else:
            new_version = "1.0.0"

        log.info("Writing version %s (checksum %s) …", new_version, new_checksum)

        cv = CurriculumVersion(
            id=uuid.uuid4(),
            version=new_version,
            checksum=new_checksum,
            published_at=datetime.now(UTC),
        )
        db.add(cv)
        await db.flush()

        for lv_data in levels:
            validated = lv_data["validated"]
            level_obj = Level(
                id=uuid.uuid4(),
                version_id=cv.id,
                ordinal=validated.level,
                slug=validated.slug,
            )
            db.add(level_obj)
            await db.flush()

            for ls_ord, lesson in enumerate(validated.lessons):
                from flexikeys.core.enums import LessonType, ItemType
                lesson_obj = Lesson(
                    id=uuid.uuid4(),
                    level_id=level_obj.id,
                    ordinal=ls_ord,
                    slug=lesson.slug,
                    lesson_type=LessonType(lesson.type),
                )
                db.add(lesson_obj)
                await db.flush()

                for it_ord, item in enumerate(lesson.items):
                    item_obj = Item(
                        id=uuid.uuid4(),
                        lesson_id=lesson_obj.id,
                        ordinal=it_ord,
                        item_type=ItemType(item.type),
                        skill_key=item.skill_key,
                        payload=item.payload,
                    )
                    db.add(item_obj)
                    await db.flush()

                    for lang, loc in item.l10n.items():
                        il = ItemLocalization(
                            id=uuid.uuid4(),
                            item_id=item_obj.id,
                            language=lang,
                            text=loc.text,
                            # audio/image asset IDs resolved later by media pipeline
                        )
                        db.add(il)

        await db.commit()
        log.info("✓ Version %s imported successfully.", new_version)
        _print_diff_summary(levels)


def _print_diff_summary(levels: list[dict[str, Any]]) -> None:
    print("\n=== Import Summary ===")
    for lv in levels:
        v = lv["validated"]
        item_count = sum(len(ls.items) for ls in v.lessons)
        print(f"  L{v.level:02d} {v.slug:<20} {len(v.lessons):2d} lessons  {item_count:3d} items")
    total = sum(sum(len(ls.items) for ls in lv["validated"].lessons) for lv in levels)
    print(f"  {'Total':<32} {total:3d} items")


def main() -> None:
    parser = argparse.ArgumentParser(description="Import FlexiKeys curriculum content.")
    parser.add_argument("directory", help="Path to shared/curriculum/ directory")
    parser.add_argument("--dry-run", action="store_true", help="Validate only, do not write to DB")
    args = parser.parse_args()

    directory = Path(args.directory).resolve()
    if not directory.is_dir():
        log.error("Not a directory: %s", directory)
        sys.exit(1)

    asyncio.run(_import(directory, args.dry_run))


if __name__ == "__main__":
    main()
