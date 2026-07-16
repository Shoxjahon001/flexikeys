from __future__ import annotations

import uuid
from datetime import UTC, datetime, timedelta

from flexikeys.modules.adaptive.models import AdaptationChange
from flexikeys.modules.progress.models import ChildGameProgress
from flexikeys.modules.progress.repository import ProgressRepository
from flexikeys.modules.progress.schemas import (
    AdaptationFeedItemOut,
    GameProgressIn,
    GameProgressOut,
    SkillSummaryOut,
    TimeseriesPointOut,
)

# ── Adaptation sentence templates ─────────────────────────────────────────────
# Keys: (reason_code, param) → human-language sentence
# Wildcard param "*" used as fallback for a given reason_code.

_ADAPTATION_SENTENCES: dict[str, dict[tuple[str, str], str]] = {
    "en": {
        ("accuracy_drop", "key_scale"): "Keys were made a bit larger to be easier to tap.",
        ("accuracy_drop", "hint_level"): "More visual hints were added to guide practice.",
        ("accuracy_drop", "*"): "The keyboard was adjusted after a drop in accuracy.",
        ("latency_rise", "dwell_time_ms"): "A short hold-time was set to reduce accidental taps.",
        ("latency_rise", "debounce_ms"): "A brief pause between taps was added.",
        ("latency_rise", "*"): "Response timing was adjusted to better match practice pace.",
        ("fatigue", "session_pacing"): "Practice sessions were adjusted to prevent tiredness.",
        ("fatigue", "*"): "Session length was adapted to reduce fatigue.",
        ("mastery_gain", "hint_level"): "Hints were reduced — great progress is being made!",
        ("mastery_gain", "key_scale"): "Keys were returned to normal size after great progress.",
        ("mastery_gain", "*"): "The keyboard adapted to match improved skill.",
        ("accidental_taps", "dwell_time_ms"): "Keys now require a short hold to register.",
        ("accidental_taps", "debounce_ms"): "A brief wait was added to prevent accidental repeats.",
        ("accidental_taps", "*"): "Tap sensitivity was adjusted to reduce accidental presses.",
    },
    "uz": {
        ("accuracy_drop", "key_scale"): "Tugmalar biroz kattalashtirildi.",
        ("accuracy_drop", "hint_level"): "Ko'proq vizual maslahatlar qo'shildi.",
        ("accuracy_drop", "*"): "Aniqlik pasaygandan so'ng klaviatura sozlandi.",
        ("latency_rise", "dwell_time_ms"): "Qisqa ushlab turish vaqti o'rnatildi.",
        ("latency_rise", "debounce_ms"): "Bosishlar orasiga qisqa pauza qo'shildi.",
        ("latency_rise", "*"): "Javob vaqti mashq sur'atiga moslashtirildi.",
        ("fatigue", "session_pacing"): "Charchoqni oldini olish uchun mashq moslashtirildi.",
        ("fatigue", "*"): "Sessiya davomiyligi charchoqni kamaytirish uchun sozlandi.",
        ("mastery_gain", "hint_level"): "Maslahatlar kamaytirildi - zo'r natijalar!",
        ("mastery_gain", "key_scale"): "Yutuqdan keyin tugmalar oddiy hajmga qaytarildi.",
        ("mastery_gain", "*"): "Klaviatura yaxshilangan ko'nikmalarga moslashdi.",
        ("accidental_taps", "dwell_time_ms"): "Tugmalar ushlab turishni talab qiladi.",
        ("accidental_taps", "debounce_ms"): "Takroriy bosishlar uchun pauza qo'shildi.",
        ("accidental_taps", "*"): "Sezgirlik tasodifiy bosishlarni kamaytirish uchun sozlandi.",
    },
    "ru": {
        ("accuracy_drop", "key_scale"): "Клавиши немного увеличены для удобного нажатия.",
        ("accuracy_drop", "hint_level"): "Добавлены визуальные подсказки для обучения.",
        ("accuracy_drop", "*"): "Клавиатура скорректирована после снижения точности.",
        ("latency_rise", "dwell_time_ms"): "Установлено время удержания для снижения ошибок.",
        ("latency_rise", "debounce_ms"): "Добавлена небольшая пауза между нажатиями.",
        ("latency_rise", "*"): "Время отклика адаптировано под темп занятий.",
        ("fatigue", "session_pacing"): "Занятия скорректированы для предотвращения усталости.",
        ("fatigue", "*"): "Длительность сессии адаптирована для снижения усталости.",
        ("mastery_gain", "hint_level"): "Подсказки уменьшены — достигнут отличный прогресс!",
        ("mastery_gain", "key_scale"): "После прогресса клавиши вернулись к обычному размеру.",
        ("mastery_gain", "*"): "Клавиатура адаптировалась к улучшенным навыкам.",
        ("accidental_taps", "dwell_time_ms"): "Клавиши теперь требуют короткого удержания.",
        ("accidental_taps", "debounce_ms"): "Добавлена задержка для предотвращения повторов.",
        ("accidental_taps", "*"): "Чувствительность нажатий снижена для точности.",
    },
}


class ProgressService:
    def __init__(self, repo: ProgressRepository) -> None:
        self._repo = repo

    async def get_skills(
        self, child_id: uuid.UUID, language: str
    ) -> list[SkillSummaryOut]:
        rows = await self._repo.get_skill_mastery(child_id, language)
        return [
            SkillSummaryOut(
                skill_key=r.skill_key,
                label=self._skill_label(r.skill_key),
                p_known=float(r.p_known),
                attempts=r.attempts,
                correct=r.correct,
            )
            for r in rows
        ]

    async def get_timeseries(
        self, child_id: uuid.UUID, metric: str, range_days: int
    ) -> list[TimeseriesPointOut]:
        to_date = datetime.now(UTC).date()
        from_date = to_date - timedelta(days=range_days)
        rows = await self._repo.get_daily_activity(child_id, from_date, to_date)
        activity_map = {r.date: r for r in rows}

        points: list[TimeseriesPointOut] = []
        for i in range(range_days + 1):
            day = from_date + timedelta(days=i)
            row = activity_map.get(day)
            if metric == "accuracy":
                value = float(row.avg_accuracy) if row and row.avg_accuracy is not None else None
            elif metric == "time":
                value = float(row.seconds_active) / 60.0 if row else None
            elif metric == "speed":
                if row and row.seconds_active and row.seconds_active > 0:
                    value = float(row.items_completed) / (float(row.seconds_active) / 60.0)
                else:
                    value = None
            else:
                value = None
            points.append(TimeseriesPointOut(date=day, value=value))
        return points

    async def get_adaptations(
        self,
        child_id: uuid.UUID,
        ui_language: str,
        limit: int,
        offset: int,
    ) -> list[AdaptationFeedItemOut]:
        rows = await self._repo.get_adaptation_changes(child_id, limit, offset)
        return [
            AdaptationFeedItemOut(
                id=r.id,
                changed_at=r.changed_at,
                param=r.param,
                old_value=r.old_value,
                new_value=r.new_value,
                reason_code=(
                    r.reason_code.value
                    if hasattr(r.reason_code, "value")
                    else str(r.reason_code)
                ),
                sentence=self._render_sentence(r, ui_language),
            )
            for r in rows
        ]

    async def get_game_progress(self, child_id: uuid.UUID) -> list[GameProgressOut]:
        rows = await self._repo.list_game_progress(child_id)
        return [self._to_out(r) for r in rows]

    async def sync_game_progress(
        self, child_id: uuid.UUID, incoming: list[GameProgressIn]
    ) -> list[GameProgressOut]:
        """Last-write-wins per level_slug: an incoming row only overwrites
        the stored row if its updated_at is newer. Returns the full, current
        state for the child so the client can reconcile anything that lost.
        """
        for item in incoming:
            existing = await self._repo.get_game_progress_row(child_id, item.level_slug)
            if existing is not None and existing.updated_at >= item.updated_at:
                continue
            await self._repo.upsert_game_progress(
                existing,
                child_id=child_id,
                level_slug=item.level_slug,
                completed=item.completed,
                stars=item.stars,
                completed_activities=item.completed_activities,
                updated_at=item.updated_at,
            )
        return await self.get_game_progress(child_id)

    @staticmethod
    def _to_out(row: ChildGameProgress) -> GameProgressOut:
        return GameProgressOut(
            level_slug=row.level_slug,
            completed=row.completed,
            stars=row.stars,
            completed_activities=row.completed_activities,
            updated_at=row.updated_at,
        )

    @staticmethod
    def _skill_label(skill_key: str) -> str:
        """Convert 'en:letter:a' → 'Letter A', 'uz:word:olma' → 'Word: olma'."""
        parts = skill_key.split(":")
        if len(parts) >= 3:
            category = parts[1].capitalize()
            value = parts[2].upper() if len(parts[2]) == 1 else parts[2]
            return f"{category} {value}"
        return skill_key

    @staticmethod
    def _render_sentence(change: AdaptationChange, ui_language: str) -> str:
        lang = ui_language if ui_language in _ADAPTATION_SENTENCES else "en"
        templates = _ADAPTATION_SENTENCES[lang]
        reason = (
            change.reason_code.value
            if hasattr(change.reason_code, "value")
            else str(change.reason_code)
        )
        key = (reason, change.param)
        if key in templates:
            return templates[key]
        wildcard = (reason, "*")
        if wildcard in templates:
            return templates[wildcard]
        return "The keyboard adapted to better support practice."
