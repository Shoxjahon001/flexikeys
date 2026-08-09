"""
Shared AI service unit tests — no database or real LLM required.

Covers message translation to Anthropic's content-block wire format and
AnthropicProvider's parsing/degradation behavior. Moved out of
test_ai_assistant.py when llm_provider.py became services/ai_service.py
(shared by ai_assistant and aac, not owned by either).
"""
from __future__ import annotations

import asyncio
import json

import httpx

from flexikeys.services.ai_service import AnthropicProvider, _translate_messages

# ── _translate_messages ────────────────────────────────────────────────────


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
