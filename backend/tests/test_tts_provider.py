"""
AzureSpeechProvider unit tests — mocked transport, no real network call.
Mirrors test_ai_service.py's AnthropicProvider test pattern.
"""
from __future__ import annotations

import asyncio

import httpx
import pytest

from flexikeys.services.tts_provider import (
    AzureSpeechProvider,
    TtsSynthesisError,
    build_tts_provider,
)


def _mock_provider(handler) -> AzureSpeechProvider:
    return AzureSpeechProvider(
        key="test-key", region="eastus", transport=httpx.MockTransport(handler)
    )


def test_synthesize_returns_response_bytes_on_200() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(200, content=b"\xff\xfb\x90fake-mp3-bytes")

    provider = _mock_provider(handler)
    audio = asyncio.run(provider.synthesize("Water", "en"))
    assert audio == b"\xff\xfb\x90fake-mp3-bytes"


def test_synthesize_sends_expected_ssml_and_headers() -> None:
    captured: dict[str, object] = {}

    def handler(request: httpx.Request) -> httpx.Response:
        captured["headers"] = request.headers
        captured["body"] = request.content.decode("utf-8")
        return httpx.Response(200, content=b"audio")

    provider = _mock_provider(handler)
    asyncio.run(provider.synthesize("Вода", "ru"))

    headers = captured["headers"]
    assert headers["Ocp-Apim-Subscription-Key"] == "test-key"
    assert headers["Content-Type"] == "application/ssml+xml"
    body = captured["body"]
    assert "ru-RU-SvetlanaNeural" in body
    assert "xml:lang='ru-RU'" in body
    assert "rate='-15%'" in body
    assert "Вода" in body


def test_synthesize_escapes_ssml_special_characters() -> None:
    captured: dict[str, str] = {}

    def handler(request: httpx.Request) -> httpx.Response:
        captured["body"] = request.content.decode("utf-8")
        return httpx.Response(200, content=b"audio")

    provider = _mock_provider(handler)
    asyncio.run(provider.synthesize("Tom & Jerry's \"show\"", "en"))
    assert "&amp;" in captured["body"]
    assert "&quot;" in captured["body"]
    assert "&apos;" in captured["body"]


def test_synthesize_raises_on_unsupported_language() -> None:
    provider = _mock_provider(lambda r: httpx.Response(200, content=b"unused"))
    with pytest.raises(TtsSynthesisError, match="unsupported_lang"):
        asyncio.run(provider.synthesize("Hola", "es"))


def test_synthesize_raises_on_non_200() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(401, text="unauthorized")

    provider = _mock_provider(handler)
    with pytest.raises(TtsSynthesisError, match="http_401"):
        asyncio.run(provider.synthesize("Water", "en"))


def test_synthesize_raises_on_network_error() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        raise httpx.ConnectError("boom")

    provider = _mock_provider(handler)
    with pytest.raises(TtsSynthesisError, match="network_error"):
        asyncio.run(provider.synthesize("Water", "en"))


# ── build_tts_provider factory ─────────────────────────────────────────────


def test_build_tts_provider_none_when_unconfigured() -> None:
    class _Settings:
        azure_speech_key = ""
        azure_speech_region = ""

    assert build_tts_provider(_Settings()) is None


def test_build_tts_provider_returns_provider_when_configured() -> None:
    class _Settings:
        azure_speech_key = "key"
        azure_speech_region = "eastus"

    provider = build_tts_provider(_Settings())
    assert isinstance(provider, AzureSpeechProvider)
