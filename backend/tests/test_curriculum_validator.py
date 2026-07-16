"""
Curriculum schema validator tests.

Covers:
- Missing language in l10n raises ValueError
- Missing audio ref raises ValueError
- Level 14+ items with unintroduced letters raises ValueError
- Uzbek multi-char units (o', g', ch, sh, ng) treated as single skill units
- Valid level files parse without error
- All 16 JSON level files in shared/curriculum/ pass validation
"""
from __future__ import annotations

import json
from pathlib import Path

import pytest
from pydantic import ValidationError

from flexikeys.modules.curriculum.schemas import (
    LEVEL1_LETTERS,
    CurriculumItem,
    CurriculumLesson,
    CurriculumLevel,
)

SHARED_CURRICULUM = Path(__file__).parent.parent.parent.parent / "shared" / "curriculum"

# ── Helpers ───────────────────────────────────────────────────────────────────

def _valid_l10n(
    en_text: str = "Cat",
    uz_text: str = "Mushuk",
    ru_text: str = "Кот",
) -> dict:
    return {
        "en": {"text": en_text, "audio": "audio/en/cat.mp3"},
        "uz": {"text": uz_text, "audio": "audio/uz/cat.mp3"},
        "ru": {"text": ru_text, "audio": "audio/ru/cat.mp3"},
    }


def _valid_item(type_: str = "word", l10n: dict | None = None) -> dict:
    return {
        "type": type_,
        "skill_key": "en:word:cat",
        "l10n": l10n or _valid_l10n(),
    }


def _valid_lesson(items: list[dict] | None = None) -> dict:
    return {
        "slug": "typing-1",
        "type": "typing",
        "title": {"en": "Lesson 1", "uz": "Dars 1", "ru": "Урок 1"},
        "items": items or [_valid_item()],
    }


def _valid_level(level: int = 1, lessons: list[dict] | None = None) -> dict:
    return {
        "level": level,
        "slug": "letters",
        "version": "1.0.0",
        "title": {"en": "Letters", "uz": "Harflar", "ru": "Буквы"},
        "lessons": lessons or [_valid_lesson()],
    }


# ── Missing language tests ────────────────────────────────────────────────────

class TestMissingLanguage:
    def test_missing_uz_raises(self) -> None:
        l10n = {
            "en": {"text": "Cat", "audio": "audio/en/cat.mp3"},
            "ru": {"text": "Кот", "audio": "audio/ru/cat.mp3"},
        }
        with pytest.raises(ValidationError, match="Missing language"):
            CurriculumItem(**_valid_item(l10n=l10n))

    def test_missing_en_raises(self) -> None:
        l10n = {
            "uz": {"text": "Mushuk", "audio": "audio/uz/cat.mp3"},
            "ru": {"text": "Кот", "audio": "audio/ru/cat.mp3"},
        }
        with pytest.raises(ValidationError, match="Missing language"):
            CurriculumItem(**_valid_item(l10n=l10n))

    def test_missing_ru_raises(self) -> None:
        l10n = {
            "en": {"text": "Cat", "audio": "audio/en/cat.mp3"},
            "uz": {"text": "Mushuk", "audio": "audio/uz/cat.mp3"},
        }
        with pytest.raises(ValidationError, match="Missing language"):
            CurriculumItem(**_valid_item(l10n=l10n))

    def test_all_langs_present_ok(self) -> None:
        item = CurriculumItem(**_valid_item())
        assert set(item.l10n.keys()) == {"en", "uz", "ru"}

    def test_level_title_missing_lang_raises(self) -> None:
        data = _valid_level()
        data["title"] = {"en": "Letters", "uz": "Harflar"}  # missing ru
        with pytest.raises(ValidationError, match="missing language"):
            CurriculumLevel(**data)


# ── Missing audio ref tests ───────────────────────────────────────────────────

class TestMissingAudio:
    def test_empty_audio_raises(self) -> None:
        l10n = {
            "en": {"text": "Cat", "audio": ""},
            "uz": {"text": "Mushuk", "audio": "audio/uz/cat.mp3"},
            "ru": {"text": "Кот", "audio": "audio/ru/cat.mp3"},
        }
        with pytest.raises(ValidationError, match="Missing audio ref"):
            CurriculumItem(**_valid_item(l10n=l10n))

    def test_valid_audio_ok(self) -> None:
        item = CurriculumItem(**_valid_item())
        for lang_data in item.l10n.values():
            assert lang_data.audio


# ── Level 14+ letter constraint tests ────────────────────────────────────────

class TestLevel14Constraint:
    def _l14_item(self, en: str, uz: str, ru: str) -> dict:
        return {
            "type": "word",
            "skill_key": "en:word:test",
            "l10n": {
                "en": {"text": en, "audio": "audio/en/test.mp3"},
                "uz": {"text": uz, "audio": "audio/uz/test.mp3"},
                "ru": {"text": ru, "audio": "audio/ru/test.mp3"},
            },
        }

    def test_valid_l14_word_passes(self) -> None:
        # "cat" uses only c, a, t — all in LEVEL1_LETTERS["en"]
        data = _valid_level(
            level=14,
            lessons=[_valid_lesson(items=[self._l14_item("cat", "ot", "кот")])],
        )
        level = CurriculumLevel(**data)
        assert level.level == 14

    def test_invalid_en_letter_raises(self) -> None:
        # "zebra" — all basic letters but this is level 14+, these are introduced in L1
        # To test failure: use a character NOT in LEVEL1_LETTERS["en"]
        # LEVEL1_LETTERS["en"] is the full alphabet, so we need a non-alpha char
        # Use a digit which would appear in text for numeric items — but item.type="word"
        # A better test: use a Cyrillic character in English text
        data = _valid_level(
            level=14,
            lessons=[_valid_lesson(items=[self._l14_item("кот", "ot", "кот")])],
        )
        # "кот" contains Cyrillic not in en LEVEL1_LETTERS
        with pytest.raises(ValidationError, match="not introduced in Level 1"):
            CurriculumLevel(**data)

    def test_valid_level_below_14_no_constraint(self) -> None:
        # Level 13 has no letter restriction — complex words are fine
        data = _valid_level(
            level=13,
            lessons=[_valid_lesson(items=[self._l14_item("xylophone", "o'simlik", "объект")])],
        )
        level = CurriculumLevel(**data)
        assert level.level == 13

    def test_letters_only_checked_for_word_types(self) -> None:
        # story_page type is also checked; letter/number types are not
        data = _valid_level(
            level=14,
            lessons=[_valid_lesson(items=[{
                "type": "letter",
                "skill_key": "en:letter:z",
                "l10n": {
                    "en": {"text": "Z", "audio": "audio/en/z.mp3"},
                    "uz": {"text": "Z", "audio": "audio/uz/z.mp3"},
                    "ru": {"text": "З", "audio": "audio/ru/z.mp3"},
                },
            }])],
        )
        # No error expected for letter type
        level = CurriculumLevel(**data)
        assert level.level == 14


# ── Uzbek multi-char unit tests ───────────────────────────────────────────────

class TestUzbekMultiChar:
    def test_o_apostrophe_in_level1(self) -> None:
        assert "o'" in LEVEL1_LETTERS["uz"]

    def test_g_apostrophe_in_level1(self) -> None:
        assert "g'" in LEVEL1_LETTERS["uz"]

    def test_ch_in_level1(self) -> None:
        assert "ch" in LEVEL1_LETTERS["uz"]

    def test_sh_in_level1(self) -> None:
        assert "sh" in LEVEL1_LETTERS["uz"]

    def test_ng_in_level1(self) -> None:
        assert "ng" in LEVEL1_LETTERS["uz"]

    def test_uz_word_with_multi_char_unit_passes_l14(self) -> None:
        # "o'qi" — o', q, i are all in LEVEL1_LETTERS["uz"] as single skill units
        data = _valid_level(
            level=14,
            lessons=[_valid_lesson(items=[{
                "type": "word",
                "skill_key": "{lang}:word:read",
                "l10n": {
                    "en": {"text": "in", "audio": "audio/en/in.mp3"},
                    "uz": {"text": "o'qi", "audio": "audio/uz/oqi.mp3"},
                    "ru": {"text": "ин", "audio": "audio/ru/in.mp3"},
                },
            }])],
        )
        level = CurriculumLevel(**data)
        assert level.level == 14


# ── Full level file validation ────────────────────────────────────────────────

@pytest.mark.skipif(
    not SHARED_CURRICULUM.exists(),
    reason="shared/curriculum/ directory not found",
)
class TestAllLevelFiles:
    """Load and validate every JSON level file from shared/curriculum/."""

    def _level_files(self) -> list[Path]:
        return sorted(SHARED_CURRICULUM.glob("level_*.json"))

    def test_all_16_files_exist(self) -> None:
        files = self._level_files()
        assert len(files) == 16, f"Expected 16 level files, found {len(files)}"

    @pytest.mark.parametrize("level_num", range(1, 17))
    def test_level_file_parses(self, level_num: int) -> None:
        candidates = list(SHARED_CURRICULUM.glob(f"level_{level_num:02d}_*.json"))
        assert candidates, f"No file for level {level_num}"
        raw = json.loads(candidates[0].read_text(encoding="utf-8"))
        level = CurriculumLevel(**raw)
        assert level.level == level_num

    @pytest.mark.parametrize("level_num", range(1, 17))
    def test_level_item_counts_positive(self, level_num: int) -> None:
        candidates = list(SHARED_CURRICULUM.glob(f"level_{level_num:02d}_*.json"))
        if not candidates:
            pytest.skip(f"No file for level {level_num}")
        raw = json.loads(candidates[0].read_text(encoding="utf-8"))
        level = CurriculumLevel(**raw)
        total = sum(len(lesson.items) for lesson in level.lessons)
        assert total > 0, f"Level {level_num} has no items"

    def test_all_levels_have_all_three_langs(self) -> None:
        for f in self._level_files():
            raw = json.loads(f.read_text(encoding="utf-8"))
            level = CurriculumLevel(**raw)
            for lesson in level.lessons:
                for item in lesson.items:
                    langs = set(item.l10n.keys())
                    missing = {"en", "uz", "ru"} - langs
                    assert not missing, (
                        f"{f.name} item {item.skill_key} missing langs: {missing}"
                    )

    def test_all_audio_refs_non_empty(self) -> None:
        for f in self._level_files():
            raw = json.loads(f.read_text(encoding="utf-8"))
            level = CurriculumLevel(**raw)
            for lesson in level.lessons:
                for item in lesson.items:
                    for lang, loc in item.l10n.items():
                        assert loc.audio, (
                            f"{f.name} item {item.skill_key} [{lang}]: empty audio ref"
                        )