"""
Azure Speech neural TTS provider for AAC voice output (modules/aac's
/tts endpoint). Mirrors ai_service.py's provider shape (thin httpx wrapper,
injectable transport for tests) but has no stub/degrade-to-placeholder
path — synthesis either succeeds or raises, and the caller (AacService)
turns that into an HTTP error so the Flutter client falls back to
on-device TTS, per its documented contract. A silent/placeholder audio
clip would be worse than that for a child expecting to hear a word.
"""
from __future__ import annotations

import httpx
import structlog

logger = structlog.get_logger()

_REQUEST_TIMEOUT_S = 10.0

# lang -> (Azure locale, neural voice name). Must match
# tools/generate_aac_audio.py's VOICES exactly — bundled audio and live
# backend audio need to sound identical to the same child (see task spec:
# "a child shouldn't hear two different voices for the same word depending
# on which screen they're on").
VOICES: dict[str, tuple[str, str]] = {
    "en": ("en-US", "en-US-AnaNeural"),
    "uz": ("uz-UZ", "uz-UZ-MadinaNeural"),
    "ru": ("ru-RU", "ru-RU-SvetlanaNeural"),
}

# Slower delivery for a 3-7 year old audience — same rate as the offline
# bundled-audio generator.
_PROSODY_RATE = "-15%"


class TtsSynthesisError(Exception):
    """Synthesis failed: unsupported language, network error, or a non-200
    from Azure. Never silently swallowed into placeholder audio."""


def _escape_ssml(text: str) -> str:
    return (
        text.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
        .replace("'", "&apos;")
    )


class AzureSpeechProvider:
    def __init__(
        self,
        key: str,
        region: str,
        transport: httpx.AsyncBaseTransport | None = None,
    ) -> None:
        self._key = key
        self._region = region
        # Injectable only for tests (httpx.MockTransport) — None uses real networking.
        self._transport = transport

    async def synthesize(self, text: str, lang: str) -> bytes:
        if lang not in VOICES:
            raise TtsSynthesisError(f"unsupported_lang:{lang}")
        locale, voice = VOICES[lang]
        ssml = (
            f"<speak version='1.0' xml:lang='{locale}'>"
            f"<voice name='{voice}'>"
            f"<prosody rate='{_PROSODY_RATE}'>{_escape_ssml(text)}</prosody>"
            f"</voice></speak>"
        )
        url = f"https://{self._region}.tts.speech.microsoft.com/cognitiveservices/v1"

        try:
            async with httpx.AsyncClient(
                timeout=_REQUEST_TIMEOUT_S, transport=self._transport
            ) as client:
                resp = await client.post(
                    url,
                    content=ssml.encode("utf-8"),
                    headers={
                        "Ocp-Apim-Subscription-Key": self._key,
                        "Content-Type": "application/ssml+xml",
                        "X-Microsoft-OutputFormat": "audio-24khz-96kbitrate-mono-mp3",
                        "User-Agent": "flexikeys-backend",
                    },
                )
        except httpx.HTTPError as e:
            logger.exception("azure_speech_request_failed", lang=lang)
            raise TtsSynthesisError("network_error") from e

        if resp.status_code != 200:
            logger.warning(
                "azure_speech_api_error",
                status=resp.status_code,
                body=resp.text[:300],
            )
            raise TtsSynthesisError(f"http_{resp.status_code}")

        return resp.content


def build_tts_provider(settings: object) -> AzureSpeechProvider | None:
    """Factory — None when unconfigured, so the router can return 503
    (client falls back to device TTS) instead of a confusing 500."""
    key = getattr(settings, "azure_speech_key", "")
    region = getattr(settings, "azure_speech_region", "")
    if key and region:
        return AzureSpeechProvider(key, region)
    return None
