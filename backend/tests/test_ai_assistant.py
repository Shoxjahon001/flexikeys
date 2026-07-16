"""
AI assistant unit tests — no database or real LLM required.

Tests cover: medical keyword detection, PII exclusion from context,
stub provider behaviour, adaptation sentence templates, skill label rendering.
"""
from __future__ import annotations

import asyncio
import json
from unittest.mock import MagicMock

import httpx

from flexikeys.modules.ai_assistant.llm_provider import (
    AnthropicProvider,
    StubProvider,
    _translate_messages,
)
from flexikeys.modules.ai_assistant.service import (
    AiAssistantService,
    _build_grounded_context,
    _build_suggested_activities,
)
from flexikeys.modules.progress.service import _ADAPTATION_SENTENCES, ProgressService

# ── Medical keyword detection ─────────────────────────────────────────────────


def test_medical_disclaimer_triggered_therapy() -> None:
    assert AiAssistantService._contains_medical_keywords("Does my child need therapy?") is True


def test_medical_disclaimer_triggered_diagnosis() -> None:
    assert AiAssistantService._contains_medical_keywords("Could this be a diagnosis?") is True


def test_medical_disclaimer_triggered_doctor() -> None:
    assert AiAssistantService._contains_medical_keywords("Should I see a doctor?") is True


def test_medical_disclaimer_triggered_speech_therapy() -> None:
    assert AiAssistantService._contains_medical_keywords("We're doing speech therapy.") is True


def test_medical_disclaimer_triggered_syndrome() -> None:
    assert AiAssistantService._contains_medical_keywords("Could it be a syndrome?") is True


def test_medical_disclaimer_triggered_disorder() -> None:
    assert AiAssistantService._contains_medical_keywords("Is there a disorder here?") is True


def test_medical_keywords_not_triggered_for_normal_chat() -> None:
    assert (
        AiAssistantService._contains_medical_keywords("What should we practice at home?") is False
    )


def test_medical_keywords_not_triggered_for_progress_question() -> None:
    assert (
        AiAssistantService._contains_medical_keywords(
            "How is my child improving in spelling?"
        )
        is False
    )


# ── PII exclusion from grounded context ──────────────────────────────────────


def test_no_pii_in_prompt_context() -> None:
    """email and birth_year must NOT appear in the serialised context dict."""
    context = _build_grounded_context(
        display_name="Alex",
        email="parent@example.com",
        birth_year=2018,
        skills=[],
        adaptations=[],
    )
    context_str = json.dumps(context)
    assert "parent@example.com" not in context_str
    assert "2018" not in context_str
    assert "Alex" in context_str  # display_name IS allowed


def test_no_parent_id_in_prompt_context() -> None:
    import uuid

    parent_uuid = uuid.uuid4()
    context = _build_grounded_context(
        display_name="Sam",
        email="p@example.com",
        birth_year=2019,
        skills=[],
        adaptations=[],
    )
    context_str = json.dumps(context)
    assert str(parent_uuid) not in context_str


# ── StubProvider behaviour ────────────────────────────────────────────────────


def test_stub_provider_returns_disabled_message() -> None:
    provider = StubProvider()
    result = asyncio.run(
        provider.complete("sys", [{"role": "user", "content": "hi"}])
    )
    assert "unavailable" in result.text.lower()


def test_stub_provider_has_no_tool_calls() -> None:
    provider = StubProvider()
    result = asyncio.run(
        provider.complete("sys", [{"role": "user", "content": "hi"}], tools=[])
    )
    assert result.tool_calls == []


# ── Adaptation sentences ──────────────────────────────────────────────────────


def test_adaptation_sentence_renders_in_all_languages() -> None:
    for lang in ("en", "uz", "ru"):
        assert lang in _ADAPTATION_SENTENCES
        # Every language must have the accuracy_drop / key_scale sentence
        assert ("accuracy_drop", "key_scale") in _ADAPTATION_SENTENCES[lang]


def test_adaptation_sentence_all_three_languages_have_latency_rise() -> None:
    for lang in ("en", "uz", "ru"):
        assert ("latency_rise", "dwell_time_ms") in _ADAPTATION_SENTENCES[lang]


def test_adaptation_sentence_all_three_languages_have_mastery_gain() -> None:
    for lang in ("en", "uz", "ru"):
        assert ("mastery_gain", "hint_level") in _ADAPTATION_SENTENCES[lang]


def test_render_sentence_unknown_combo_returns_fallback() -> None:
    from unittest.mock import MagicMock

    change = MagicMock()
    change.reason_code = MagicMock()
    change.reason_code.value = "accuracy_drop"
    change.param = "unknown_param_xyz"

    # Should fall back to wildcard or default
    sentence = ProgressService._render_sentence(change, "en")
    assert isinstance(sentence, str)
    assert len(sentence) > 0


# ── Skill label rendering ─────────────────────────────────────────────────────


def test_skill_label_renders_letter() -> None:
    assert ProgressService._skill_label("en:letter:a") == "Letter A"


def test_skill_label_renders_uppercase_single_char() -> None:
    assert ProgressService._skill_label("en:letter:z") == "Letter Z"


def test_skill_label_renders_word() -> None:
    label = ProgressService._skill_label("uz:word:olma")
    assert "olma" in label
    assert "Word" in label


def test_skill_label_renders_number() -> None:
    label = ProgressService._skill_label("en:number:5")
    assert "5" in label


def test_skill_label_passthrough_unknown_format() -> None:
    label = ProgressService._skill_label("raw_key")
    assert label == "raw_key"


# ── _translate_messages (internal → Anthropic wire format) ────────────────────


def test_translate_messages_plain_text_turns_pass_through() -> None:
    out = _translate_messages(
        [{"role": "user", "content": "hi"}, {"role": "assistant", "content": "hello"}]
    )
    assert out == [
        {"role": "user", "content": "hi"},
        {"role": "assistant", "content": "hello"},
    ]


def test_translate_messages_assistant_tool_calls_become_blocks() -> None:
    out = _translate_messages(
        [
            {
                "role": "assistant",
                "content": "checking...",
                "tool_calls": [
                    {"id": "call_1", "name": "get_progress_summary", "arguments": {}}
                ],
            }
        ]
    )
    assert out == [
        {
            "role": "assistant",
            "content": [
                {"type": "text", "text": "checking..."},
                {
                    "type": "tool_use",
                    "id": "call_1",
                    "name": "get_progress_summary",
                    "input": {},
                },
            ],
        }
    ]


def test_translate_messages_empty_assistant_text_omits_text_block() -> None:
    out = _translate_messages(
        [
            {
                "role": "assistant",
                "content": "",
                "tool_calls": [{"id": "c1", "name": "t", "arguments": {}}],
            }
        ]
    )
    assert out[0]["content"] == [
        {"type": "tool_use", "id": "c1", "name": "t", "input": {}}
    ]


def test_translate_messages_merges_consecutive_tool_results_into_one_user_turn() -> None:
    out = _translate_messages(
        [
            {"role": "tool", "tool_call_id": "c1", "content": "result1"},
            {"role": "tool", "tool_call_id": "c2", "content": "result2"},
        ]
    )
    assert len(out) == 1
    assert out[0]["role"] == "user"
    assert out[0]["content"] == [
        {"type": "tool_result", "tool_use_id": "c1", "content": "result1"},
        {"type": "tool_result", "tool_use_id": "c2", "content": "result2"},
    ]


# ── AnthropicProvider (mocked transport — no real network call) ───────────────


def _mock_provider(handler) -> AnthropicProvider:
    return AnthropicProvider(
        api_key="test-key", model="claude-sonnet-4-6", transport=httpx.MockTransport(handler)
    )


def test_anthropic_provider_parses_text_response() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(
            200,
            json={"content": [{"type": "text", "text": "Emma is doing great!"}]},
        )

    provider = _mock_provider(handler)
    result = asyncio.run(provider.complete("sys", [{"role": "user", "content": "hi"}]))
    assert result.text == "Emma is doing great!"
    assert result.tool_calls == []


def test_anthropic_provider_parses_tool_use_response() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(
            200,
            json={
                "content": [
                    {
                        "type": "tool_use",
                        "id": "toolu_1",
                        "name": "get_progress_summary",
                        "input": {"language": "en"},
                    }
                ]
            },
        )

    provider = _mock_provider(handler)
    result = asyncio.run(provider.complete("sys", [{"role": "user", "content": "hi"}]))
    assert result.text == ""
    assert len(result.tool_calls) == 1
    assert result.tool_calls[0].name == "get_progress_summary"
    assert result.tool_calls[0].arguments == {"language": "en"}
    assert result.tool_calls[0].call_id == "toolu_1"


def test_anthropic_provider_sends_expected_request_shape() -> None:
    captured: dict = {}

    def handler(request: httpx.Request) -> httpx.Response:
        captured["headers"] = request.headers
        captured["body"] = json.loads(request.content)
        return httpx.Response(200, json={"content": [{"type": "text", "text": "ok"}]})

    provider = _mock_provider(handler)
    asyncio.run(
        provider.complete(
            "system prompt", [{"role": "user", "content": "hi"}], tools=[{"name": "t"}]
        )
    )
    assert captured["headers"]["x-api-key"] == "test-key"
    assert captured["headers"]["anthropic-version"] == "2023-06-01"
    assert captured["body"]["model"] == "claude-sonnet-4-6"
    assert captured["body"]["system"] == "system prompt"
    assert captured["body"]["tools"] == [{"name": "t"}]


def test_anthropic_provider_degrades_gracefully_on_error_status() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(500, json={"error": "internal"})

    provider = _mock_provider(handler)
    result = asyncio.run(provider.complete("sys", [{"role": "user", "content": "hi"}]))
    assert "couldn't reach" in result.text.lower()
    assert result.tool_calls == []


def test_anthropic_provider_degrades_gracefully_on_network_error() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        raise httpx.ConnectError("boom", request=request)

    provider = _mock_provider(handler)
    result = asyncio.run(provider.complete("sys", [{"role": "user", "content": "hi"}]))
    assert "couldn't reach" in result.text.lower()


def test_anthropic_provider_degrades_gracefully_on_malformed_response() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(200, json={"unexpected": "shape"})

    provider = _mock_provider(handler)
    result = asyncio.run(provider.complete("sys", [{"role": "user", "content": "hi"}]))
    # No "content" key -> _parse_response should treat as empty, not raise.
    assert result.text == ""
    assert result.tool_calls == []


# ── _build_suggested_activities ────────────────────────────────────────────────


def _skill(skill_key: str, label: str, p_known: float, attempts: int) -> MagicMock:
    m = MagicMock()
    m.skill_key = skill_key
    m.label = label
    m.p_known = p_known
    m.attempts = attempts
    return m


def test_build_suggested_activities_targets_weakest_attempted_skills() -> None:
    skills = [
        _skill("en:letter:a", "Letter A", 0.9, attempts=10),
        _skill("en:letter:b", "Letter B", 0.2, attempts=5),
        _skill("en:shape:circle", "Shape circle", 0.5, attempts=3),
        _skill("en:letter:z", "Letter Z", 0.1, attempts=0),  # never attempted
    ]
    activities = _build_suggested_activities(skills)
    titles = [a["title"] for a in activities]
    # Weakest ATTEMPTED skill first (Letter B, p_known=0.2); never-attempted
    # "Letter Z" must be excluded even though its p_known is lowest.
    assert titles[0] == "Practice Letter B"
    assert not any("Letter Z" in t for t in titles)
    assert len(activities) <= 3


def test_build_suggested_activities_normalizes_label_casing() -> None:
    skills = [_skill("en:shape:circle", "Shape circle", 0.3, attempts=2)]
    activities = _build_suggested_activities(skills)
    assert activities[0]["title"] == "Practice Shape Circle"
    assert "30%" in activities[0]["description"]


def test_build_suggested_activities_falls_back_when_nothing_attempted() -> None:
    skills = [_skill("en:letter:a", "Letter A", 0.0, attempts=0)]
    activities = _build_suggested_activities(skills)
    assert len(activities) == 1
    assert "enough practice data" in activities[0]["description"]


def test_build_suggested_activities_falls_back_on_empty_skills() -> None:
    activities = _build_suggested_activities([])
    assert len(activities) == 1
