"""
AAC module unit tests — no database required (see memory: object.__new__ +
fake-redis injection pattern, matching tests/test_rewards.py).
"""
from __future__ import annotations

import uuid
from datetime import UTC, datetime, timedelta
from types import SimpleNamespace
from typing import Any
from unittest.mock import AsyncMock, MagicMock

import httpx
import pytest

from flexikeys.modules.aac.schemas import (
    AacEventBatchIn,
    AacEventIn,
    ComposeSentenceRequest,
)
from flexikeys.modules.aac.service import AacService, TtsUnavailableError
from flexikeys.services.ai_service import ChatCompletion
from flexikeys.services.tts_provider import AzureSpeechProvider, TtsSynthesisError

# ── Fake Redis (dict-backed, SET NX / GET / DEL semantics) ────────────────────


def _fake_redis() -> Any:
    _store: dict[str, str] = {}

    async def _set(key: str, val: str, ex: int | None = None, nx: bool = False) -> bool | None:
        if nx:
            if key in _store:
                return False
            _store[key] = val
            return True
        _store[key] = val
        return None

    async def _get(key: str) -> str | None:
        return _store.get(key)

    async def _delete(key: str) -> None:
        _store.pop(key, None)

    redis = MagicMock()
    redis.set = _set
    redis.get = _get
    redis.delete = _delete
    return redis


# ── Service builder ─────────────────────────────────────────────────────────


def _degraded_provider() -> MagicMock:
    """Default provider for tests that don't care about AI behavior — acts
    like a real degraded StubProvider/AnthropicProvider (see ai_service.py),
    so compose_sentence/generate_insights's AI-upgrade paths cleanly no-op
    down to their deterministic fallback instead of awaiting a plain
    MagicMock (which raises: not awaitable)."""
    provider = MagicMock()
    provider.complete = AsyncMock(return_value=ChatCompletion(text="", degraded=True))
    return provider


def _svc(
    repo: MagicMock | None = None,
    redis: Any | None = None,
    provider: Any | None = None,
    tts_provider: Any | None = None,
) -> AacService:
    svc: AacService = object.__new__(AacService)
    svc._repo = repo or MagicMock()  # type: ignore[attr-defined]
    svc._redis = redis or _fake_redis()  # type: ignore[attr-defined]
    svc._provider = provider or _degraded_provider()  # type: ignore[attr-defined]
    svc._tts_provider = tts_provider  # type: ignore[attr-defined]
    return svc


def _event(card_id: str, category: str, days_ago: float, now: datetime) -> SimpleNamespace:
    return SimpleNamespace(
        card_id=card_id,
        category=category,
        tapped_at=now - timedelta(days=days_ago),
    )


# ── ingest_events ────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_ingest_events_accepts_new_batch() -> None:
    repo = MagicMock()
    repo.insert_event_batch = AsyncMock(return_value=2)
    svc = _svc(repo=repo)

    batch = AacEventBatchIn(
        child_id=uuid.uuid4(),
        batch_id=uuid.uuid4(),
        events=[
            AacEventIn(
                card_id="ne_water",
                category="needs",
                sentence_spoken="I want water.",
                language="en",
                tapped_at=datetime.now(UTC),
            ),
            AacEventIn(
                card_id="ne_help",
                category="needs",
                sentence_spoken="I need help.",
                language="en",
                tapped_at=datetime.now(UTC),
            ),
        ],
    )
    accepted, deduplicated = await svc.ingest_events(batch)
    assert accepted == 2
    assert deduplicated is False
    repo.insert_event_batch.assert_awaited_once()


@pytest.mark.asyncio
async def test_ingest_events_deduplicates_repeated_batch_id() -> None:
    repo = MagicMock()
    repo.insert_event_batch = AsyncMock(return_value=1)
    redis = _fake_redis()
    svc = _svc(repo=repo, redis=redis)

    batch = AacEventBatchIn(
        child_id=uuid.uuid4(),
        batch_id=uuid.uuid4(),
        events=[
            AacEventIn(
                card_id="ne_water",
                category="needs",
                sentence_spoken="I want water.",
                language="en",
                tapped_at=datetime.now(UTC),
            )
        ],
    )
    first = await svc.ingest_events(batch)
    second = await svc.ingest_events(batch)
    assert first == (1, False)
    assert second == (0, True)
    repo.insert_event_batch.assert_awaited_once()  # not called again on dedup


# ── compose_sentence ─────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_compose_sentence_empty_words_returns_template() -> None:
    svc = _svc()
    result = await svc.compose_sentence(
        ComposeSentenceRequest(child_id=uuid.uuid4(), words=["   "], language="en")
    )
    assert result.source == "template"
    assert result.sentence == ""


@pytest.mark.asyncio
async def test_compose_sentence_uses_ai_when_available() -> None:
    provider = MagicMock()
    provider.complete = AsyncMock(
        return_value=ChatCompletion(text="I want cold water, please.", degraded=False)
    )
    svc = _svc(provider=provider)
    result = await svc.compose_sentence(
        ComposeSentenceRequest(
            child_id=uuid.uuid4(), words=["water", "cold", "please"], language="en"
        )
    )
    assert result.source == "ai"
    assert result.sentence == "I want cold water, please."


@pytest.mark.asyncio
async def test_compose_sentence_falls_back_to_template_when_degraded() -> None:
    provider = MagicMock()
    provider.complete = AsyncMock(
        return_value=ChatCompletion(text="[stub message]", degraded=True)
    )
    svc = _svc(provider=provider)
    result = await svc.compose_sentence(
        ComposeSentenceRequest(child_id=uuid.uuid4(), words=["water", "please"], language="en")
    )
    assert result.source == "template"
    assert result.sentence == "water please"


@pytest.mark.asyncio
async def test_compose_sentence_caches_ai_result_and_skips_second_provider_call() -> None:
    provider = MagicMock()
    provider.complete = AsyncMock(
        return_value=ChatCompletion(text="I want water.", degraded=False)
    )
    redis = _fake_redis()
    svc = _svc(redis=redis, provider=provider)
    request = ComposeSentenceRequest(child_id=uuid.uuid4(), words=["water"], language="en")

    first = await svc.compose_sentence(request)
    second = await svc.compose_sentence(request)

    assert first.sentence == second.sentence == "I want water."
    assert provider.complete.await_count == 1  # second call served from cache


# ── synthesize_speech (neural TTS for Sentence Strip) ──────────────────────────


def _mock_azure_provider(handler) -> AzureSpeechProvider:
    return AzureSpeechProvider(
        key="test-key", region="eastus", transport=httpx.MockTransport(handler)
    )


@pytest.mark.asyncio
async def test_synthesize_speech_raises_unavailable_when_no_provider_configured() -> None:
    svc = _svc(tts_provider=None)
    with pytest.raises(TtsUnavailableError):
        await svc.synthesize_speech("Water", "en")


@pytest.mark.asyncio
async def test_synthesize_speech_calls_provider_and_returns_audio_on_cache_miss() -> None:
    tts_provider = _mock_azure_provider(lambda r: httpx.Response(200, content=b"mp3-bytes"))
    svc = _svc(tts_provider=tts_provider)

    audio = await svc.synthesize_speech("Water", "en")

    assert audio == b"mp3-bytes"


@pytest.mark.asyncio
async def test_synthesize_speech_caches_and_skips_second_provider_call() -> None:
    call_count = 0

    def handler(request: httpx.Request) -> httpx.Response:
        nonlocal call_count
        call_count += 1
        return httpx.Response(200, content=b"mp3-bytes")

    tts_provider = _mock_azure_provider(handler)
    redis = _fake_redis()
    svc = _svc(redis=redis, tts_provider=tts_provider)

    first = await svc.synthesize_speech("Water", "en")
    second = await svc.synthesize_speech("Water", "en")

    assert first == second == b"mp3-bytes"
    assert call_count == 1  # second call served from cache


@pytest.mark.asyncio
async def test_synthesize_speech_different_lang_is_a_separate_cache_entry() -> None:
    call_count = 0

    def handler(request: httpx.Request) -> httpx.Response:
        nonlocal call_count
        call_count += 1
        return httpx.Response(200, content=f"audio-{call_count}".encode())

    tts_provider = _mock_azure_provider(handler)
    redis = _fake_redis()
    svc = _svc(redis=redis, tts_provider=tts_provider)

    en_audio = await svc.synthesize_speech("Water", "en")
    ru_audio = await svc.synthesize_speech("Water", "ru")

    assert call_count == 2
    assert en_audio != ru_audio


@pytest.mark.asyncio
async def test_synthesize_speech_propagates_synthesis_error_uncached() -> None:
    tts_provider = _mock_azure_provider(lambda r: httpx.Response(401, text="unauthorized"))
    redis = _fake_redis()
    svc = _svc(redis=redis, tts_provider=tts_provider)

    with pytest.raises(TtsSynthesisError):
        await svc.synthesize_speech("Water", "en")

    # A failed synthesis must not poison the cache with a bad/empty entry.
    cache_key = AacService._tts_cache_key("Water", "en")
    assert await redis.get(cache_key) is None


# ── generate_insights / _compute_insights (pure logic) ────────────────────────


def test_compute_insights_no_insight_below_min_recent_taps() -> None:
    now = datetime.now(UTC)
    events = [_event("ne_water", "needs", 1, now), _event("ne_water", "needs", 2, now)]
    insights = AacService._compute_insights(events, now)
    assert insights == []


def test_compute_insights_no_insight_without_baseline_data() -> None:
    now = datetime.now(UTC)
    # 5 recent taps, zero baseline taps -> can't claim "more than usual" honestly.
    events = [_event("ne_water", "needs", d, now) for d in (0.1, 0.5, 1, 1.5, 2)]
    insights = AacService._compute_insights(events, now)
    assert insights == []


def test_compute_insights_emits_neutral_insight_on_real_spike() -> None:
    now = datetime.now(UTC)
    # Baseline: 1 tap over the 11-day baseline window (~0.09/day).
    events = [_event("pa_ball", "play", 10, now)]
    # Recent: 5 taps in the last 3 days (~1.67/day) -> well above 1.5x baseline.
    events += [_event("pa_ball", "play", d, now) for d in (0.1, 0.5, 1.0, 1.5, 2.0)]
    insights = AacService._compute_insights(events, now)
    assert len(insights) == 1
    assert insights[0].category == "play"
    assert insights[0].tone == "neutral"
    assert "play" in insights[0].body.lower()


def test_compute_insights_attention_tone_for_pain_card_in_feelings() -> None:
    now = datetime.now(UTC)
    events = [_event("fe_pain", "feelings", 10, now)]
    events += [_event("fe_pain", "feelings", d, now) for d in (0.1, 0.5, 1.0, 1.5, 2.0)]
    insights = AacService._compute_insights(events, now)
    assert len(insights) == 1
    assert insights[0].tone == "attention"
    assert "doctor" in insights[0].body.lower() or "therapist" in insights[0].body.lower()


def test_compute_insights_neutral_for_needs_category_without_attention_card() -> None:
    now = datetime.now(UTC)
    # "needs" is an attention-eligible category, but ne_hug isn't a listed
    # attention card_id -> should stay neutral, not attention.
    events = [_event("ne_hug", "needs", 10, now)]
    events += [_event("ne_hug", "needs", d, now) for d in (0.1, 0.5, 1.0, 1.5, 2.0)]
    insights = AacService._compute_insights(events, now)
    assert len(insights) == 1
    assert insights[0].tone == "neutral"


def test_insights_disclaimer_present_only_when_attention_tone_exists() -> None:
    now = datetime.now(UTC)
    attention_events = [_event("fe_pain", "feelings", 10, now)]
    attention_events += [
        _event("fe_pain", "feelings", d, now) for d in (0.1, 0.5, 1.0, 1.5, 2.0)
    ]
    attention_insights = AacService._compute_insights(attention_events, now)
    assert AacService.insights_disclaimer(attention_insights) is not None

    neutral_events = [_event("pa_ball", "play", 10, now)]
    neutral_events += [_event("pa_ball", "play", d, now) for d in (0.1, 0.5, 1.0, 1.5, 2.0)]
    neutral_insights = AacService._compute_insights(neutral_events, now)
    assert AacService.insights_disclaimer(neutral_insights) is None

    assert AacService.insights_disclaimer([]) is None


@pytest.mark.asyncio
async def test_generate_insights_caches_result_per_day() -> None:
    now = datetime.now(UTC)
    events = [_event("pa_ball", "play", 10, now)]
    events += [_event("pa_ball", "play", d, now) for d in (0.1, 0.5, 1.0, 1.5, 2.0)]

    repo = MagicMock()
    repo.get_events_since = AsyncMock(return_value=events)
    svc = _svc(repo=repo)
    child_id = uuid.uuid4()

    first = await svc.generate_insights(child_id, as_of=now)
    second = await svc.generate_insights(child_id, as_of=now)

    assert len(first) == 1
    assert [i.model_dump() for i in first] == [i.model_dump() for i in second]
    repo.get_events_since.assert_awaited_once()  # second call served from cache


# ── get_stats (Today + 7-day trend, parent dashboard) ─────────────────────────


@pytest.mark.asyncio
async def test_get_stats_shapes_today_and_trend_from_repo_rows() -> None:
    repo = MagicMock()
    repo.get_card_counts_between = AsyncMock(
        return_value=[("ne_water", "needs", 12), ("fe_happy", "feelings", 5)]
    )
    repo.get_daily_category_counts = AsyncMock(
        return_value=[
            (datetime(2026, 7, 20).date(), "needs", 4),
            (datetime(2026, 7, 21).date(), "needs", 6),
        ]
    )
    svc = _svc(repo=repo)

    result = await svc.get_stats(uuid.uuid4(), as_of=datetime.now(UTC))

    assert [s.card_id for s in result.today] == ["ne_water", "fe_happy"]
    assert result.today[0].count == 12
    assert len(result.trend) == 2
    assert result.trend[0].category == "needs"
    assert result.trend[0].count == 4


@pytest.mark.asyncio
async def test_get_stats_caches_result_and_skips_second_repo_call() -> None:
    repo = MagicMock()
    repo.get_card_counts_between = AsyncMock(return_value=[("ne_water", "needs", 3)])
    repo.get_daily_category_counts = AsyncMock(return_value=[])
    svc = _svc(repo=repo)
    child_id = uuid.uuid4()
    now = datetime.now(UTC)

    first = await svc.get_stats(child_id, as_of=now)
    second = await svc.get_stats(child_id, as_of=now)

    assert first.model_dump() == second.model_dump()
    repo.get_card_counts_between.assert_awaited_once()
    repo.get_daily_category_counts.assert_awaited_once()


@pytest.mark.asyncio
async def test_get_stats_empty_when_no_events() -> None:
    repo = MagicMock()
    repo.get_card_counts_between = AsyncMock(return_value=[])
    repo.get_daily_category_counts = AsyncMock(return_value=[])
    svc = _svc(repo=repo)

    result = await svc.get_stats(uuid.uuid4(), as_of=datetime.now(UTC))
    assert result.today == []
    assert result.trend == []


# ── Insight AI polish (Phase 5) ────────────────────────────────────────────────


def _spike_events(card_id: str, category: str, now: datetime) -> list[SimpleNamespace]:
    events = [_event(card_id, category, 10, now)]
    events += [_event(card_id, category, d, now) for d in (0.1, 0.5, 1.0, 1.5, 2.0)]
    return events


@pytest.mark.asyncio
async def test_generate_insights_uses_ai_polish_when_valid() -> None:
    events = _spike_events("pa_ball", "play", datetime.now(UTC))
    repo = MagicMock()
    repo.get_events_since = AsyncMock(return_value=events)
    provider = MagicMock()
    provider.complete = AsyncMock(
        return_value=ChatCompletion(
            text="Looks like play has been extra popular the last few days!",
            degraded=False,
        )
    )
    svc = _svc(repo=repo, provider=provider)

    insights = await svc.generate_insights(uuid.uuid4(), as_of=datetime.now(UTC))

    assert len(insights) == 1
    assert insights[0].body == "Looks like play has been extra popular the last few days!"


@pytest.mark.asyncio
async def test_generate_insights_falls_back_when_polish_drops_doctor_mention() -> None:
    events = _spike_events("fe_pain", "feelings", datetime.now(UTC))
    repo = MagicMock()
    repo.get_events_since = AsyncMock(return_value=events)
    provider = MagicMock()
    # Attention-tone insight, but the "rewrite" strips the doctor/therapist
    # suggestion entirely -> must be rejected, not silently accepted.
    provider.complete = AsyncMock(
        return_value=ChatCompletion(text="Feelings cards were used a lot lately!", degraded=False)
    )
    svc = _svc(repo=repo, provider=provider)

    insights = await svc.generate_insights(uuid.uuid4(), as_of=datetime.now(UTC))

    assert len(insights) == 1
    assert insights[0].tone == "attention"
    assert "doctor" in insights[0].body.lower() or "therapist" in insights[0].body.lower()


@pytest.mark.asyncio
async def test_generate_insights_falls_back_when_polish_uses_forbidden_word() -> None:
    events = _spike_events("pa_ball", "play", datetime.now(UTC))
    repo = MagicMock()
    repo.get_events_since = AsyncMock(return_value=events)
    provider = MagicMock()
    provider.complete = AsyncMock(
        return_value=ChatCompletion(
            text="This pattern could indicate a disorder worth discussing.", degraded=False
        )
    )
    svc = _svc(repo=repo, provider=provider)

    insights = await svc.generate_insights(uuid.uuid4(), as_of=datetime.now(UTC))

    assert len(insights) == 1
    assert "disorder" not in insights[0].body.lower()


@pytest.mark.asyncio
async def test_generate_insights_falls_back_when_provider_degraded() -> None:
    events = _spike_events("pa_ball", "play", datetime.now(UTC))
    repo = MagicMock()
    repo.get_events_since = AsyncMock(return_value=events)
    # _svc()'s default provider already returns degraded=True.
    svc = _svc(repo=repo)

    insights = await svc.generate_insights(uuid.uuid4(), as_of=datetime.now(UTC))

    assert len(insights) == 1
    assert "play" in insights[0].body.lower()
    assert "cards were selected" in insights[0].body  # the deterministic template's own phrasing


def test_is_polish_valid_rejects_wildly_different_length() -> None:
    original = "Over the last 3 days, 'play' cards were selected 5 times."
    too_short = "Yes."
    too_long = original * 5
    assert AacService._is_polish_valid(too_short, original, False) is False
    assert AacService._is_polish_valid(too_long, original, False) is False


def test_is_polish_valid_accepts_reasonable_rewrite() -> None:
    original = "Over the last 3 days, 'play' cards were selected 5 times."
    rewrite = "Play has come up quite a bit over the past three days!"
    assert AacService._is_polish_valid(rewrite, original, False) is True
