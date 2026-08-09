from __future__ import annotations

import asyncio
import hashlib
import json
import uuid
from collections import Counter
from datetime import UTC, datetime, timedelta
from typing import Any

from redis.asyncio import Redis
from sqlalchemy.ext.asyncio import AsyncSession

from flexikeys.modules.aac.models import AacEvent
from flexikeys.modules.aac.repository import AacRepository
from flexikeys.modules.aac.schemas import (
    AacEventBatchIn,
    AacInsightOut,
    AacStatsResponse,
    AacTodayCardStat,
    AacTrendPoint,
    ComposeSentenceRequest,
    ComposeSentenceResponse,
)
from flexikeys.services.ai_service import MEDICAL_DISCLAIMER, LlmProvider

_BATCH_DEDUP_TTL = 86_400  # 24 h, matches sessions' ingest dedup window

_COMPOSE_SYSTEM_PROMPT = (
    "You compose one short, natural, grammatically correct sentence in the "
    "requested language from a sequence of words a nonverbal child selected "
    "on an AAC (assistive communication) device.\n\n"
    "Rules:\n"
    "- Use ONLY the given words' meaning. Never add facts, names, or content "
    "not implied by the input words.\n"
    "- Output ONLY the sentence itself — no preamble, no quotes, no "
    "explanation.\n"
    "- Keep it short (one sentence, under 15 words).\n"
    "- If the words don't obviously form a request/statement, produce the "
    "most natural short reading of them in order (e.g. as an exclamation or "
    "simple statement) rather than forcing an unnatural sentence."
)

_COMPOSE_CACHE_TTL = 60 * 60 * 24 * 30  # 30 days — same word sequence -> same sentence

# Categories/cards where a frequency spike is worth a gentle, non-diagnostic
# note to the parent (see docs/aac_phase3_ai_layer.md). Deliberately narrow
# and explicit — not every category spike warrants an "attention" tone (e.g.
# "play" spiking is just... play), only ones plausibly tied to
# discomfort/distress a parent would want to notice.
_ATTENTION_CATEGORIES = frozenset({"feelings", "needs"})
_ATTENTION_CARD_IDS = frozenset(
    {"fe_pain", "fe_sad", "fe_scared", "fe_tired", "ne_medicine", "ne_help"}
)

_RECENT_WINDOW_DAYS = 3
_BASELINE_WINDOW_DAYS = 11  # the 11 days before the recent window
_MIN_RECENT_TAPS_FOR_INSIGHT = 3
_MIN_DELTA_RATIO_FOR_INSIGHT = 1.5  # recent must be >=50% above baseline daily rate

# Phase 3 originally shipped insights as pure deterministic templates —
# guaranteed-safe wording, no risk of an AI rephrase drifting into
# diagnostic language. Revisited in Phase 5: this now layers an optional AI
# "polish" pass on top of the same guaranteed-safe template, with a strict
# validator — matching compose_sentence's AI-upgrade/guaranteed-fallback
# pattern. The deterministic template is still what's computed and cached
# first; polishing can only reword it, never change what it's allowed to
# say (see docs/aac_phase3_ai_layer.md and _is_polish_valid below).
_INSIGHT_POLISH_SYSTEM_PROMPT = (
    "You rephrase a factual observation about a child's AAC (assistive "
    "communication device) usage into warmer, more natural language for a "
    "parent, while keeping it 100% factually identical.\n\n"
    "Rules:\n"
    "- Do NOT add any new fact, number, claim, or suggestion not already "
    "present in the input.\n"
    "- Do NOT remove or soften any sentence that mentions a doctor or "
    "therapist, if present in the input — keep that suggestion, only make "
    "the phrasing warmer.\n"
    "- Never use diagnostic or clinical language (words like 'diagnosis', "
    "'disorder', 'syndrome', 'condition') even if related words appear in "
    "the input.\n"
    "- Output ONLY the rewritten text — no preamble, no quotes.\n"
    "- Keep it roughly the same length as the input."
)

_FORBIDDEN_POLISH_WORDS = frozenset(
    {
        "diagnosis",
        "diagnosed",
        "diagnose",
        "disorder",
        "syndrome",
        "condition",
        "autism",
        "adhd",
        "epilepsy",
        "disability",
    }
)


class AacService:
    def __init__(
        self,
        session: AsyncSession,
        redis: Redis,
        provider: LlmProvider,
    ) -> None:
        self._repo = AacRepository(session)
        self._redis = redis
        self._provider = provider

    # ── Event ingest ────────────────────────────────────────────────────────

    async def ingest_events(self, batch: AacEventBatchIn) -> tuple[int, bool]:
        """
        Idempotent batch ingest — mirrors sessions.SessionService.ingest_events
        (same Redis SET NX dedup shape, same "already processed" semantics).
        """
        dedup_key = f"ingest:aac_batch:{batch.batch_id}"
        is_new = await self._redis.set(dedup_key, "1", ex=_BATCH_DEDUP_TTL, nx=True)
        if not is_new:
            return 0, True

        rows: list[dict[str, Any]] = [
            {
                "card_id": e.card_id,
                "category": e.category,
                "sentence_spoken": e.sentence_spoken,
                "language": e.language,
                "tapped_at": e.tapped_at,
            }
            for e in batch.events
        ]
        count = await self._repo.insert_event_batch(batch.child_id, batch.batch_id, rows)
        return count, False

    # ── Sentence composer (Sentence Strip / Level 4) ───────────────────────

    async def compose_sentence(
        self, request: ComposeSentenceRequest
    ) -> ComposeSentenceResponse:
        words = [w.strip() for w in request.words if w.strip()]
        template = self._template_sentence(words)
        if not words:
            return ComposeSentenceResponse(sentence=template, source="template")

        cache_key = self._compose_cache_key(words, request.language)
        cached = await self._redis.get(cache_key)
        if cached:
            return ComposeSentenceResponse(sentence=cached, source="ai")

        user_message = (
            f"Words (in order): {', '.join(words)}\nLanguage: {request.language}"
        )
        completion = await self._provider.complete(
            _COMPOSE_SYSTEM_PROMPT, [{"role": "user", "content": user_message}]
        )

        # Real degrade (offline, no key, network error, bad response) ->
        # always fall back to the naive word-join template, never surface a
        # stub/error string as if it were a composed sentence.
        if completion.degraded or not completion.text.strip():
            return ComposeSentenceResponse(sentence=template, source="template")

        sentence = completion.text.strip()
        await self._redis.set(cache_key, sentence, ex=_COMPOSE_CACHE_TTL)
        return ComposeSentenceResponse(sentence=sentence, source="ai")

    @staticmethod
    def _template_sentence(words: list[str]) -> str:
        """
        Pure, always-available fallback — identical in spirit to the
        client's own offline fallback (AacSentenceStripScreen._speak(): a
        naive space-joined word sequence, see app/lib/features/aac/
        presentation/aac_sentence_strip_screen.dart). Deliberately NOT a
        smarter template like "I want {noun}" here — with no structured
        sense of each word's grammatical role, guessing a template would
        often be wrong (e.g. "Sad" + "Help" is not "I want sad help").
        Single/two-step cards already get a *correct* templated sentence for
        free via AacCardDef.sentenceFor() — this fallback only covers
        free-form multi-word Sentence Strip composition.
        """
        return " ".join(words)

    @staticmethod
    def _compose_cache_key(words: list[str], language: str) -> str:
        digest = hashlib.sha256(
            ("|".join(w.lower() for w in words) + f"::{language}").encode("utf-8")
        ).hexdigest()
        return f"aac:compose:{digest}"

    # ── Pattern-analysis insights (parent dashboard) ───────────────────────

    async def generate_insights(
        self, child_id: uuid.UUID, as_of: datetime | None = None
    ) -> list[AacInsightOut]:
        """
        Compares each category's tap rate over the last _RECENT_WINDOW_DAYS
        against its baseline rate over the _BASELINE_WINDOW_DAYS before that.
        Only emits an insight when there's enough data to say something real
        (docs/aac_phase3_ai_layer.md "no invented numbers" rule, same
        standard as the parent AI Assistant's buildInsights()).
        """
        now = as_of or datetime.now(UTC)
        cache_key = f"aac:insights:{child_id}:{now.date().isoformat()}"
        cached = await self._redis.get(cache_key)
        if cached:
            return [AacInsightOut(**item) for item in json.loads(cached)]

        since = now - timedelta(days=_RECENT_WINDOW_DAYS + _BASELINE_WINDOW_DAYS)
        events = await self._repo.get_events_since(child_id, since)
        insights = self._compute_insights(events, now)
        if insights:
            insights = list(
                await asyncio.gather(*(self._polish_insight(i) for i in insights))
            )

        await self._redis.set(
            cache_key,
            json.dumps([i.model_dump() for i in insights]),
            ex=60 * 60 * 24,  # 1 day — matches the "daily" analysis cadence
        )
        return insights

    async def _polish_insight(self, insight: AacInsightOut) -> AacInsightOut:
        """AI-upgrade layer over the deterministic template — see the module
        comment above _INSIGHT_POLISH_SYSTEM_PROMPT. Any degrade or failed
        validation returns the original, untouched insight."""
        requires_doctor_mention = insight.tone == "attention"
        completion = await self._provider.complete(
            _INSIGHT_POLISH_SYSTEM_PROMPT,
            [{"role": "user", "content": insight.body}],
        )
        if completion.degraded or not completion.text.strip():
            return insight

        polished = completion.text.strip()
        if not self._is_polish_valid(polished, insight.body, requires_doctor_mention):
            return insight
        return insight.model_copy(update={"body": polished})

    @staticmethod
    def _is_polish_valid(
        polished: str, original: str, requires_doctor_mention: bool
    ) -> bool:
        """Guards against the AI rewrite dropping a required doctor/
        therapist mention, drifting into diagnostic language, or
        ballooning/truncating into something that no longer resembles a
        faithful rephrase — never a claim that it's semantically identical
        (that would need real NLU), just cheap, high-value defenses against
        the specific failure modes that matter most here."""
        if not polished:
            return False
        if not (0.4 * len(original) <= len(polished) <= 2.5 * len(original)):
            return False
        lowered = polished.lower()
        if requires_doctor_mention and "doctor" not in lowered and "therapist" not in lowered:
            return False
        return not any(word in lowered for word in _FORBIDDEN_POLISH_WORDS)

    @classmethod
    def _compute_insights(
        cls, events: list[AacEvent], now: datetime
    ) -> list[AacInsightOut]:
        recent_cutoff = now - timedelta(days=_RECENT_WINDOW_DAYS)
        baseline_cutoff = recent_cutoff - timedelta(days=_BASELINE_WINDOW_DAYS)

        recent_by_category: Counter[str] = Counter()
        baseline_by_category: Counter[str] = Counter()
        attention_card_hits: Counter[str] = Counter()

        for ev in events:
            if ev.tapped_at >= recent_cutoff:
                recent_by_category[ev.category] += 1
                if ev.card_id in _ATTENTION_CARD_IDS:
                    attention_card_hits[ev.category] += 1
            elif ev.tapped_at >= baseline_cutoff:
                baseline_by_category[ev.category] += 1

        insights: list[AacInsightOut] = []
        for category, recent_count in recent_by_category.items():
            if recent_count < _MIN_RECENT_TAPS_FOR_INSIGHT:
                continue
            baseline_count = baseline_by_category.get(category, 0)
            baseline_daily_rate = baseline_count / _BASELINE_WINDOW_DAYS
            recent_daily_rate = recent_count / _RECENT_WINDOW_DAYS

            # No baseline data yet -> can't claim "more than usual" honestly.
            if baseline_count == 0:
                continue
            if recent_daily_rate < baseline_daily_rate * _MIN_DELTA_RATIO_FOR_INSIGHT:
                continue

            is_attention = (
                category in _ATTENTION_CATEGORIES
                and attention_card_hits.get(category, 0) > 0
            )
            insights.append(
                AacInsightOut(
                    category=category,
                    headline=f"'{category.capitalize()}' selected more than usual",
                    body=(
                        f"Over the last {_RECENT_WINDOW_DAYS} days, '{category}' "
                        f"cards were selected {recent_count} times — about "
                        f"{recent_daily_rate:.1f}/day, compared to roughly "
                        f"{baseline_daily_rate:.1f}/day before that."
                        + (
                            " If this continues, it may be worth mentioning to "
                            "your child's doctor or therapist."
                            if is_attention
                            else ""
                        )
                    ),
                    tone="attention" if is_attention else "neutral",
                )
            )

        return insights

    @staticmethod
    def insights_disclaimer(insights: list[AacInsightOut]) -> str | None:
        if any(i.tone == "attention" for i in insights):
            return MEDICAL_DISCLAIMER
        return None

    # ── Parent dashboard stats (Today + 7-day trend) ────────────────────────

    async def get_stats(
        self, child_id: uuid.UUID, as_of: datetime | None = None
    ) -> AacStatsResponse:
        now = as_of or datetime.now(UTC)
        cache_key = f"aac:stats:{child_id}"
        cached = await self._redis.get(cache_key)
        if cached:
            return AacStatsResponse.model_validate_json(cached)

        day_start = datetime(now.year, now.month, now.day, tzinfo=UTC)
        day_end = day_start + timedelta(days=1)
        today_rows = await self._repo.get_card_counts_between(
            child_id, day_start, day_end
        )
        today = [
            AacTodayCardStat(card_id=card_id, category=category, count=count)
            for card_id, category, count in today_rows
        ]

        trend_since = day_start - timedelta(days=6)  # 7 calendar days, today inclusive
        trend_rows = await self._repo.get_daily_category_counts(child_id, trend_since)
        trend = [
            AacTrendPoint(date=day, category=category, count=count)
            for day, category, count in trend_rows
        ]

        response = AacStatsResponse(today=today, trend=trend)
        # Short TTL — unlike insights (daily cadence), Today's counts change
        # throughout the day as the child keeps tapping.
        await self._redis.set(cache_key, response.model_dump_json(), ex=300)
        return response
