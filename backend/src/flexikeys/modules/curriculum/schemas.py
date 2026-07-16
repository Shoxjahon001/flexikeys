"""
Curriculum Pydantic models.

These models validate the per-level JSON files in shared/curriculum/ and serve
as the response types for curriculum API endpoints.

The per-level file format is:
  {
    "level": 6, "slug": "animals", "version": "1.0.0",
    "lessons": [{
      "slug": "farm-animals", "type": "typing",
      "items": [{
        "type": "word", "skill_key": "{lang}:word:cow",
        "l10n": {
          "en": {"text": "Cow", "audio": "audio/en/cow.mp3",
                 "sound": "audio/fx/cow_moo.mp3", "image": "img/animals/cow.webp"},
          ...
        }
      }]
    }]
  }
"""
from __future__ import annotations

import re
from typing import Annotated, Any, Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator

SUPPORTED_LANGS = frozenset({"en", "uz", "ru"})

# All letters introduced in Level 1 per language — used by Level 14+ validator.
# Letters are in frequency/ease order (the same order as the content files).
LEVEL1_LETTERS: dict[str, list[str]] = {
    "en": list("etaoinshrdlcumwfgypbvkjxqz"),
    "uz": ["a","i","o","u","e","n","r","s","t","l","k","d","m","b","y","g","z",
           "ch","sh","ng","o'","g'","f","h","p","v","x","j","c","q"],
    "ru": list("оеаинтсрвлкмдпуяызбгчйжхшфэцюёщъь"),
}


class ItemL10n(BaseModel):
    """Localization record for one language."""
    text: str
    audio: str       # storage key (relative)
    image: str | None = None
    sound: str | None = None   # animal sounds, etc.
    trace_path: list[list[float]] | None = None  # normalized [x,y] points for drawing


class CurriculumItem(BaseModel):
    """A single learnable item inside a lesson."""
    type: Literal["letter","number","word","sentence","shape","color","trace_path","story_page"]
    skill_key: str = Field(min_length=1, max_length=200)
    l10n: dict[str, ItemL10n]
    payload: dict[str, Any] | None = None

    @field_validator("l10n")
    @classmethod
    def _all_langs_present(cls, v: dict[str, ItemL10n]) -> dict[str, ItemL10n]:
        missing = SUPPORTED_LANGS - v.keys()
        if missing:
            raise ValueError(f"Missing language(s): {sorted(missing)}")
        return v

    @field_validator("l10n")
    @classmethod
    def _audio_refs_not_empty(cls, v: dict[str, ItemL10n]) -> dict[str, ItemL10n]:
        for lang, loc in v.items():
            if not loc.audio:
                raise ValueError(f"Missing audio ref for language '{lang}'")
        return v


class CurriculumLesson(BaseModel):
    """A lesson is a sequence of items with a shared type."""
    slug: str = Field(min_length=1, max_length=64)
    type: Literal["typing","drawing","listening","story"]
    title: dict[str, str]
    items: list[CurriculumItem] = Field(min_length=1)

    @field_validator("title")
    @classmethod
    def _title_all_langs(cls, v: dict[str, str]) -> dict[str, str]:
        missing = SUPPORTED_LANGS - v.keys()
        if missing:
            raise ValueError(f"Lesson title missing language(s): {sorted(missing)}")
        return v


class CurriculumLevel(BaseModel):
    """Top-level structure for one level file."""
    model_config = ConfigDict(extra="forbid")

    level: int = Field(ge=1, le=16)
    slug: str = Field(min_length=1, max_length=64)
    version: str = Field(pattern=r"^\d+\.\d+\.\d+$")
    title: dict[str, str]
    lessons: list[CurriculumLesson] = Field(min_length=1)

    @field_validator("title")
    @classmethod
    def _title_all_langs(cls, v: dict[str, str]) -> dict[str, str]:
        missing = SUPPORTED_LANGS - v.keys()
        if missing:
            raise ValueError(f"Level title missing language(s): {sorted(missing)}")
        return v

    @model_validator(mode="after")
    def _level14_word_constraint(self) -> "CurriculumLevel":
        """Level 14+ items may only use letters introduced in Level 1."""
        if self.level < 14:
            return self
        for lesson in self.lessons:
            for item in lesson.items:
                if item.type not in ("word", "sentence", "story_page"):
                    continue
                for lang, loc in item.l10n.items():
                    allowed = set(LEVEL1_LETTERS.get(lang, []))
                    text = loc.text.lower()
                    _check_unintroduced_letters(text, lang, allowed, item.skill_key)
        return self


def _check_unintroduced_letters(
    text: str, lang: str, allowed: set[str], skill_key: str
) -> None:
    """Raise ValueError if text contains characters not in the allowed set."""
    if lang == "uz":
        # Uzbek multi-char units: o', g', ch, sh, ng must be checked as units
        check = text
        multi = ["o'", "g'", "ch", "sh", "ng"]
        for m in sorted(multi, key=len, reverse=True):
            if m in allowed:
                check = check.replace(m, "")
        remaining = re.sub(r"[^a-z]", "", check)
        for ch in remaining:
            if ch not in allowed:
                raise ValueError(
                    f"Level 14+ item '{skill_key}' [{lang}]: "
                    f"letter '{ch}' not introduced in Level 1"
                )
    else:
        for ch in re.sub(r"[^a-zа-яё]", "", text):
            if ch not in allowed:
                raise ValueError(
                    f"Level 14+ item '{skill_key}' [{lang}]: "
                    f"letter '{ch}' not introduced in Level 1"
                )


# ── API response models ───────────────────────────────────────────────────────

class ItemL10nOut(BaseModel):
    text: str
    audio_url: str
    image_url: str | None = None
    sound_url: str | None = None
    trace_path: list[list[float]] | None = None


class ItemOut(BaseModel):
    id: str
    type: str
    skill_key: str
    l10n: ItemL10nOut


class LessonOut(BaseModel):
    id: str
    slug: str
    type: str
    title: str
    item_count: int


class LessonDetailOut(BaseModel):
    id: str
    slug: str
    type: str
    title: str
    items: list[ItemOut]


class LevelOut(BaseModel):
    id: str
    level: int
    slug: str
    title: str
    lesson_count: int
    item_count: int


class NextLessonPlan(BaseModel):
    """Adaptive item selector output — the next lesson plan for the client."""
    lesson_id: str
    lesson_slug: str
    items: list[ItemOut]
    due_review_items: list[ItemOut]  # from repetition_queue
