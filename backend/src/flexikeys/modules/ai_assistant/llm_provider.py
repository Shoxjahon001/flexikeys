from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Protocol, runtime_checkable

import httpx
import structlog

logger = structlog.get_logger()


@dataclass
class ToolCall:
    name: str
    arguments: dict[str, Any]
    call_id: str


@dataclass
class ChatCompletion:
    text: str
    tool_calls: list[ToolCall] = field(default_factory=list)


@runtime_checkable
class LlmProvider(Protocol):
    async def complete(
        self,
        system: str,
        messages: list[dict[str, Any]],
        tools: list[dict[str, Any]] | None = None,
    ) -> ChatCompletion: ...


class StubProvider:
    """Used when ai_provider=stub or no API key. Never crashes — shows disabled state."""

    async def complete(
        self,
        system: str,
        messages: list[dict[str, Any]],
        tools: list[dict[str, Any]] | None = None,
    ) -> ChatCompletion:
        return ChatCompletion(
            text=(
                "[AI assistant is currently unavailable."
                " Please contact support if this persists.]"
            ),
            tool_calls=[],
        )


# ── Anthropic Messages API ──────────────────────────────────────────────────

_ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages"
_ANTHROPIC_VERSION = "2023-06-01"
_MAX_TOKENS = 1024
_REQUEST_TIMEOUT_S = 30.0

_FALLBACK_COMPLETION = ChatCompletion(
    text=(
        "[I couldn't reach the AI service just now. Please try again in a "
        "moment — if this keeps happening, contact support.]"
    ),
    tool_calls=[],
)


def _translate_messages(messages: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """
    Translate the service layer's internal flat message list (OpenAI-ish
    {"role", "content", ...} dicts, with a synthetic "tool" role) into
    Anthropic's content-block wire format.

    Anthropic has no "tool" role: tool results travel back as a "user" turn
    containing tool_result blocks, and a preceding assistant turn's tool
    calls must appear as tool_use blocks in that same turn. Consecutive
    "tool" entries (one per call from the same round) are merged into a
    single "user" turn — Anthropic expects exactly one user turn per
    assistant tool_use turn, not N separate turns.
    """
    out: list[dict[str, Any]] = []
    i = 0
    n = len(messages)
    while i < n:
        msg = messages[i]
        role = msg["role"]

        if role == "tool":
            blocks: list[dict[str, Any]] = []
            while i < n and messages[i]["role"] == "tool":
                tool_msg = messages[i]
                blocks.append(
                    {
                        "type": "tool_result",
                        "tool_use_id": tool_msg["tool_call_id"],
                        "content": tool_msg["content"],
                    }
                )
                i += 1
            out.append({"role": "user", "content": blocks})
            continue

        if role == "assistant" and msg.get("tool_calls"):
            assistant_blocks: list[dict[str, Any]] = []
            if msg.get("content"):
                assistant_blocks.append({"type": "text", "text": msg["content"]})
            for tc in msg["tool_calls"]:
                assistant_blocks.append(
                    {
                        "type": "tool_use",
                        "id": tc["id"],
                        "name": tc["name"],
                        "input": tc["arguments"],
                    }
                )
            out.append({"role": "assistant", "content": assistant_blocks})
            i += 1
            continue

        out.append({"role": role, "content": msg["content"]})
        i += 1

    return out


def _parse_response(data: dict[str, Any]) -> ChatCompletion:
    text_parts: list[str] = []
    tool_calls: list[ToolCall] = []
    for block in data.get("content", []):
        block_type = block.get("type")
        if block_type == "text":
            text_parts.append(block.get("text", ""))
        elif block_type == "tool_use":
            tool_calls.append(
                ToolCall(
                    name=block["name"],
                    arguments=block.get("input", {}),
                    call_id=block["id"],
                )
            )
    return ChatCompletion(text="".join(text_parts), tool_calls=tool_calls)


class AnthropicProvider:
    def __init__(
        self,
        api_key: str,
        model: str,
        transport: httpx.AsyncBaseTransport | None = None,
    ) -> None:
        self._api_key = api_key
        self._model = model or "claude-sonnet-4-6"
        # Injectable only for tests (httpx.MockTransport) — None uses real networking.
        self._transport = transport

    async def complete(
        self,
        system: str,
        messages: list[dict[str, Any]],
        tools: list[dict[str, Any]] | None = None,
    ) -> ChatCompletion:
        body: dict[str, Any] = {
            "model": self._model,
            "max_tokens": _MAX_TOKENS,
            "system": system,
            "messages": _translate_messages(messages),
        }
        if tools:
            body["tools"] = tools

        try:
            async with httpx.AsyncClient(
                timeout=_REQUEST_TIMEOUT_S, transport=self._transport
            ) as client:
                resp = await client.post(
                    _ANTHROPIC_API_URL,
                    json=body,
                    headers={
                        "x-api-key": self._api_key,
                        "anthropic-version": _ANTHROPIC_VERSION,
                        "content-type": "application/json",
                    },
                )
        except httpx.HTTPError:
            logger.exception("anthropic_request_failed")
            return _FALLBACK_COMPLETION

        if resp.status_code != 200:
            logger.warning(
                "anthropic_api_error",
                status=resp.status_code,
                body=resp.text[:500],
            )
            return _FALLBACK_COMPLETION

        try:
            return _parse_response(resp.json())
        except (KeyError, ValueError):
            logger.exception("anthropic_response_parse_failed")
            return _FALLBACK_COMPLETION


def build_provider(settings: Any) -> LlmProvider:
    """Factory — returns StubProvider when no key is available."""
    if settings.ai_provider == "anthropic" and settings.ai_api_key:
        return AnthropicProvider(settings.ai_api_key, settings.ai_model)
    return StubProvider()
