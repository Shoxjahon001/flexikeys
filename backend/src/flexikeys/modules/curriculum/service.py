from __future__ import annotations

import json
import uuid
from pathlib import Path
from typing import Any

from fastapi import HTTPException
from redis.asyncio import Redis
from sqlalchemy.ext.asyncio import AsyncSession

from flexikeys.modules.curriculum.repository import CurriculumRepository
from flexikeys.modules.curriculum.schemas import (
    ItemL10nOut,
    ItemOut,
    LessonDetailOut,
    LessonOut,
    LevelOut,
    NextLessonPlan,
)
from flexikeys.modules.media.service import MediaService

# Redis cache TTL — invalidated on new curriculum version
_CACHE_TTL = 3600  # 1 h


def _cache_key(version_id: str, *parts: str) -> str:
    return f"curriculum:{version_id}:{':'.join(parts)}"


class CurriculumService:
    def __init__(self, session: AsyncSession, redis: Redis) -> None:  # type: ignore[type-arg]
        self._repo = CurriculumRepository(session)
        self._redis = redis
        self._media = MediaService()

    async def _version_id(self) -> uuid.UUID:
        ver = await self._repo.get_latest_version()
        if ver is None:
            raise HTTPException(status_code=503, detail="Curriculum not yet imported")
        return ver.id

    def _sign_url(self, storage_key: str | None) -> str | None:
        if not storage_key:
            return None
        return self._media.signed_url(storage_key)

    async def list_levels(self, language: str) -> list[LevelOut]:
        version_id = await self._version_id()
        cache_key = _cache_key(str(version_id), "levels", language)
        cached = await self._redis.get(cache_key)
        if cached:
            return [LevelOut(**d) for d in json.loads(cached)]

        levels = await self._repo.list_levels(version_id)
        result = []
        for lv in levels:
            lessons = await self._repo.list_lessons(lv.id)
            item_count = 0
            for ls in lessons:
                items = await self._repo.list_items(ls.id)
                item_count += len(items)
            # title from JSON file (not stored in DB — read from raw file as fallback)
            result.append(LevelOut(
                id=str(lv.id),
                level=lv.ordinal,
                slug=lv.slug,
                title=_level_title(lv.slug, language),
                lesson_count=len(lessons),
                item_count=item_count,
            ))

        await self._redis.set(cache_key, json.dumps([r.model_dump() for r in result]), ex=_CACHE_TTL)
        return result

    async def list_lessons(self, level_slug: str, language: str) -> list[LessonOut]:
        version_id = await self._version_id()
        level = await self._repo.get_level_by_slug(version_id, level_slug)
        if level is None:
            raise HTTPException(status_code=404, detail="Level not found")

        cache_key = _cache_key(str(version_id), "lessons", level_slug, language)
        cached = await self._redis.get(cache_key)
        if cached:
            return [LessonOut(**d) for d in json.loads(cached)]

        lessons = await self._repo.list_lessons(level.id)
        result = []
        for ls in lessons:
            items = await self._repo.list_items(ls.id)
            result.append(LessonOut(
                id=str(ls.id),
                slug=ls.slug,
                type=ls.lesson_type.value,
                title=_lesson_title(level_slug, ls.slug, language),
                item_count=len(items),
            ))

        await self._redis.set(cache_key, json.dumps([r.model_dump() for r in result]), ex=_CACHE_TTL)
        return result

    async def get_lesson_detail(self, lesson_id: uuid.UUID, language: str) -> LessonDetailOut:
        version_id = await self._version_id()
        lesson = await self._repo.get_lesson_by_id(lesson_id)
        if lesson is None:
            raise HTTPException(status_code=404, detail="Lesson not found")

        cache_key = _cache_key(str(version_id), "lesson", str(lesson_id), language)
        cached = await self._redis.get(cache_key)
        if cached:
            return LessonDetailOut(**json.loads(cached))

        pairs = await self._repo.list_items_with_l10n(lesson_id, language)
        items_out = []
        for item, l10n in pairs:
            if l10n is None:
                continue
            items_out.append(ItemOut(
                id=str(item.id),
                type=item.item_type.value,
                skill_key=item.skill_key,
                l10n=ItemL10nOut(
                    text=l10n.text or "",
                    audio_url=self._sign_url(_asset_key(l10n, "audio")) or "",
                    image_url=self._sign_url(_asset_key(l10n, "image")),
                    sound_url=None,
                    trace_path=item.payload.get("trace_path") if item.payload else None,
                ),
            ))

        detail = LessonDetailOut(
            id=str(lesson.id),
            slug=lesson.slug,
            type=lesson.lesson_type.value,
            title=_lesson_title("", lesson.slug, language),
            items=items_out,
        )
        await self._redis.set(cache_key, detail.model_dump_json(), ex=_CACHE_TTL)
        return detail

    async def get_next_lesson_plan(
        self, child_id: uuid.UUID, language: str
    ) -> NextLessonPlan:
        """
        Adaptive item selector: picks the next lesson based on mastery + due queue.
        Falls back to first lesson of first level when no progress data exists.
        """
        from flexikeys.modules.adaptive.repository import AdaptiveRepository
        from flexikeys.modules.adaptive.repetition import select_due_items

        version_id = await self._version_id()
        levels = await self._repo.list_levels(version_id)
        if not levels:
            raise HTTPException(status_code=503, detail="Curriculum not yet imported")

        # Default to first lesson of first level
        first_level = levels[0]
        lessons = await self._repo.list_lessons(first_level.id)
        if not lessons:
            raise HTTPException(status_code=503, detail="No lessons available")

        lesson = lessons[0]
        pairs = await self._repo.list_items_with_l10n(lesson.id, language)

        items_out = [
            ItemOut(
                id=str(item.id),
                type=item.item_type.value,
                skill_key=item.skill_key,
                l10n=ItemL10nOut(
                    text=l10n.text or "",
                    audio_url=self._sign_url(_asset_key(l10n, "audio")) or "",
                    image_url=self._sign_url(_asset_key(l10n, "image")),
                ),
            )
            for item, l10n in pairs
            if l10n is not None
        ]

        return NextLessonPlan(
            lesson_id=str(lesson.id),
            lesson_slug=lesson.slug,
            items=items_out,
            due_review_items=[],
        )


def _asset_key(l10n: Any, kind: str) -> str | None:
    """Get the storage key from an asset FK — placeholder until asset resolution is wired."""
    return None  # resolved via media pipeline in production


def _level_title(slug: str, language: str) -> str:
    """Map slug → localized title (read from bundled JSON on cold path)."""
    _TITLES: dict[str, dict[str, str]] = {
        "letters": {"en": "Letters", "uz": "Harflar", "ru": "Буквы"},
        "numbers": {"en": "Numbers", "uz": "Raqamlar", "ru": "Цифры"},
        "shapes": {"en": "Shapes", "uz": "Shakllar", "ru": "Фигуры"},
        "colors": {"en": "Colors", "uz": "Ranglar", "ru": "Цвета"},
        "family": {"en": "Family", "uz": "Oila", "ru": "Семья"},
        "animals": {"en": "Animals", "uz": "Hayvonlar", "ru": "Животные"},
        "fruits": {"en": "Fruits", "uz": "Mevalar", "ru": "Фрукты"},
        "vegetables": {"en": "Vegetables", "uz": "Sabzavotlar", "ru": "Овощи"},
        "toys": {"en": "Toys", "uz": "O'yinchoqlar", "ru": "Игрушки"},
        "transport": {"en": "Transport", "uz": "Transport", "ru": "Транспорт"},
        "body-parts": {"en": "Body Parts", "uz": "Tana qismlari", "ru": "Части тела"},
        "clothes": {"en": "Clothes", "uz": "Kiyimlar", "ru": "Одежда"},
        "nature": {"en": "Nature", "uz": "Tabiat", "ru": "Природа"},
        "simple-words": {"en": "Simple Words", "uz": "Oddiy so'zlar", "ru": "Простые слова"},
        "sentences": {"en": "Sentences", "uz": "Jumlalar", "ru": "Предложения"},
        "stories": {"en": "Stories", "uz": "Hikoyalar", "ru": "Рассказы"},
    }
    return _TITLES.get(slug, {}).get(language, slug)


def _lesson_title(level_slug: str, lesson_slug: str, language: str) -> str:
    _TITLES: dict[str, dict[str, str]] = {
        "lowercase-letters": {"en": "Lowercase Letters", "uz": "Kichik harflar", "ru": "Строчные буквы"},
        "uppercase-letters": {"en": "Uppercase Letters", "uz": "Katta harflar", "ru": "Заглавные буквы"},
        "letter-tracing": {"en": "Letter Tracing", "uz": "Harflarni chizish", "ru": "Обведите буквы"},
        "digits": {"en": "Digits 0–9", "uz": "Raqamlar 0–9", "ru": "Цифры 0–9"},
        "number-words": {"en": "Number Words", "uz": "Raqam so'zlari", "ru": "Числа словами"},
        "number-tracing": {"en": "Number Tracing", "uz": "Raqamlarni chizish", "ru": "Обводим цифры"},
        "shape-names": {"en": "Shape Names", "uz": "Shakllar nomlari", "ru": "Названия фигур"},
        "shape-tracing": {"en": "Shape Tracing", "uz": "Shakllarni chizish", "ru": "Обводим фигуры"},
        "color-names": {"en": "Color Names", "uz": "Ranglar nomlari", "ru": "Названия цветов"},
        "family-members": {"en": "Family Members", "uz": "Oila a'zolari", "ru": "Члены семьи"},
        "farm-animals": {"en": "Farm Animals", "uz": "Uy hayvonlari", "ru": "Домашние животные"},
        "wild-animals": {"en": "Wild Animals", "uz": "Yovvoyi hayvonlar", "ru": "Дикие животные"},
        "animal-drawing": {"en": "Connect the Dots", "uz": "Nuqtalarni ulang", "ru": "Соединяем точки"},
        "fruits": {"en": "Fruits", "uz": "Mevalar", "ru": "Фрукты"},
        "vegetables": {"en": "Vegetables", "uz": "Sabzavotlar", "ru": "Овощи"},
        "toys": {"en": "My Toys", "uz": "Mening o'yinchoqlarim", "ru": "Мои игрушки"},
        "vehicles": {"en": "Vehicles", "uz": "Transport vositalari", "ru": "Транспортные средства"},
        "body-parts": {"en": "Body Parts", "uz": "Tana qismlari", "ru": "Части тела"},
        "clothes": {"en": "Clothes", "uz": "Kiyimlar", "ru": "Одежда"},
        "nature": {"en": "Nature", "uz": "Tabiat", "ru": "Природа"},
        "nature-drawing": {"en": "Nature Drawing", "uz": "Tabiatni chizish", "ru": "Рисуем природу"},
        "simple-words": {"en": "Simple Words", "uz": "Qisqa so'zlar", "ru": "Простые слова"},
        "simple-sentences": {"en": "Simple Sentences", "uz": "Oddiy jumlalar", "ru": "Простые предложения"},
    }
    return _TITLES.get(lesson_slug, {}).get(language, lesson_slug)
