"""
TTS generation pipeline.

Usage:
    python -m flexikeys.tools.generate_tts shared/curriculum/ --lang en --out /tmp/audio
    python -m flexikeys.tools.generate_tts shared/curriculum/ --lang all --out /tmp/audio

Voice direction (from CLAUDE.md + spec):
  - Warm, calm, professional child-friendly voice
  - Slow pace (0.85× normal speed)
  - Letters: pronounced phonetically ("aah" not "ay")
  - Words: pronounced naturally
  - Animals: sound first ("Moo"), then word ("Cow")

TTS_PROVIDER env:
  - "elevenlabs"  → ElevenLabs API (recommended for child voice quality)
  - "openai"      → OpenAI TTS
  - unset / empty → silent placeholder (44-byte WAV header) + loud warning
"""
from __future__ import annotations

import abc
import argparse
import asyncio
import hashlib
import logging
import os
import struct
import sys
from pathlib import Path
from typing import Any

import json

logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
log = logging.getLogger(__name__)

SUPPORTED_LANGS = ["en", "uz", "ru"]


# ── TTS Provider interface ────────────────────────────────────────────────────

class TtsProvider(abc.ABC):
    """Interface for Text-to-Speech backends."""

    @abc.abstractmethod
    async def synthesize(
        self, text: str, language: str, *, speed: float = 0.85
    ) -> bytes:
        """Return WAV/MP3 audio bytes for the given text."""


class SilentTtsProvider(TtsProvider):
    """
    Silent placeholder provider — emits a minimal valid WAV file.
    Used when TTS_PROVIDER is not configured.

    # STUB #4 — wire TTS_PROVIDER to a real provider key before production
    # See issue #tts-provider-key
    """

    _WAV_HEADER_SIZE = 44

    def _silent_wav(self, duration_ms: int = 500) -> bytes:
        """Return a minimal silent WAV file (PCM 16-bit, 22050 Hz, mono)."""
        sample_rate = 22050
        num_samples = sample_rate * duration_ms // 1000
        data_size = num_samples * 2  # 16-bit = 2 bytes/sample
        header = struct.pack(
            "<4sI4s4sIHHIIHH4sI",
            b"RIFF", data_size + 36, b"WAVE",
            b"fmt ", 16, 1, 1, sample_rate, sample_rate * 2, 2, 16,
            b"data", data_size,
        )
        return header + b"\x00" * data_size

    async def synthesize(self, text: str, language: str, *, speed: float = 0.85) -> bytes:
        log.warning(
            "STUB TTS: No TTS provider configured (TTS_PROVIDER env unset). "
            "Generating silent placeholder for text=%r lang=%s. "
            "Set TTS_PROVIDER + TTS_API_KEY before production. (issue #tts-provider-key)",
            text[:40], language
        )
        return self._silent_wav(duration_ms=max(300, len(text) * 60))


class ElevenLabsTtsProvider(TtsProvider):
    """ElevenLabs TTS provider — warm child-friendly voices."""

    VOICE_IDS = {
        "en": "21m00Tcm4TlvDq8ikWAM",  # Rachel — calm, warm
        "uz": "21m00Tcm4TlvDq8ikWAM",  # fallback until Uzbek voice available
        "ru": "AZnzlk1XvdvUeBnXmlld",  # Domi — calm Russian
    }

    def __init__(self, api_key: str) -> None:
        self._api_key = api_key

    async def synthesize(self, text: str, language: str, *, speed: float = 0.85) -> bytes:
        import urllib.request
        voice_id = self.VOICE_IDS.get(language, self.VOICE_IDS["en"])
        url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}"
        body = json.dumps({
            "text": text,
            "model_id": "eleven_multilingual_v2",
            "voice_settings": {"stability": 0.75, "similarity_boost": 0.85, "speaking_rate": speed},
        }).encode()
        req = urllib.request.Request(
            url, data=body,
            headers={"xi-api-key": self._api_key, "Content-Type": "application/json"},
        )
        with urllib.request.urlopen(req, timeout=30) as resp:
            return resp.read()


class OpenAITtsProvider(TtsProvider):
    """OpenAI TTS provider."""

    VOICES = {"en": "alloy", "uz": "alloy", "ru": "alloy"}

    def __init__(self, api_key: str) -> None:
        self._api_key = api_key

    async def synthesize(self, text: str, language: str, *, speed: float = 0.85) -> bytes:
        import urllib.request
        url = "https://api.openai.com/v1/audio/speech"
        body = json.dumps({
            "model": "tts-1-hd",
            "input": text,
            "voice": self.VOICES.get(language, "alloy"),
            "speed": speed,
            "response_format": "mp3",
        }).encode()
        req = urllib.request.Request(
            url, data=body,
            headers={"Authorization": f"Bearer {self._api_key}", "Content-Type": "application/json"},
        )
        with urllib.request.urlopen(req, timeout=30) as resp:
            return resp.read()


def get_tts_provider() -> TtsProvider:
    """Factory: selects provider based on TTS_PROVIDER env."""
    provider_name = os.environ.get("TTS_PROVIDER", "").lower().strip()
    api_key = os.environ.get("TTS_API_KEY", "")

    if provider_name == "elevenlabs" and api_key:
        log.info("Using ElevenLabs TTS provider.")
        return ElevenLabsTtsProvider(api_key)
    elif provider_name == "openai" and api_key:
        log.info("Using OpenAI TTS provider.")
        return OpenAITtsProvider(api_key)
    else:
        if provider_name and not api_key:
            log.warning("TTS_PROVIDER=%s but TTS_API_KEY is empty — using silent placeholder.", provider_name)
        return SilentTtsProvider()


# ── Audio generation pipeline ──────────────────────────────────────────────

def _audio_refs(item: dict) -> list[tuple[str, str, str]]:
    """Extract (lang, text, audio_path) tuples from an item's l10n."""
    refs = []
    for lang, loc in item.get("l10n", {}).items():
        text = loc.get("text", "")
        audio = loc.get("audio", "")
        if text and audio:
            refs.append((lang, text, audio))
    return refs


async def generate_for_level(
    level_data: dict,
    provider: TtsProvider,
    out_dir: Path,
    langs: list[str],
    force: bool = False,
) -> int:
    """Generate TTS audio for one level. Returns count of files generated."""
    count = 0
    for lesson in level_data.get("lessons", []):
        for item in lesson.get("items", []):
            # Sound file (animal sound etc.) — not TTS, skip
            for lang, loc in item.get("l10n", {}).items():
                if lang not in langs:
                    continue
                text = loc.get("text", "")
                audio_path = loc.get("audio", "")
                if not text or not audio_path:
                    continue

                out_file = out_dir / audio_path
                if out_file.exists() and not force:
                    continue

                out_file.parent.mkdir(parents=True, exist_ok=True)
                audio_bytes = await provider.synthesize(text, lang)
                out_file.write_bytes(audio_bytes)
                log.debug("Generated %s", out_file)
                count += 1
    return count


async def _run(directory: Path, out_dir: Path, langs: list[str], force: bool) -> None:
    provider = get_tts_provider()
    total = 0
    for fp in sorted(directory.glob("level_*.json")):
        data = json.loads(fp.read_text(encoding="utf-8"))
        log.info("Processing %s …", fp.name)
        n = await generate_for_level(data, provider, out_dir, langs, force=force)
        log.info("  → %d files generated", n)
        total += n
    log.info("Done. Total: %d audio files generated.", total)


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate TTS audio for the curriculum.")
    parser.add_argument("directory", help="Path to shared/curriculum/")
    parser.add_argument("--lang", default="all",
                        help="Language code (en|uz|ru|all). Default: all")
    parser.add_argument("--out", default="./audio_output",
                        help="Output directory for generated audio files")
    parser.add_argument("--force", action="store_true", help="Overwrite existing files")
    args = parser.parse_args()

    directory = Path(args.directory).resolve()
    out_dir = Path(args.out).resolve()

    if not directory.is_dir():
        log.error("Not a directory: %s", directory)
        sys.exit(1)

    langs = SUPPORTED_LANGS if args.lang == "all" else [args.lang]
    asyncio.run(_run(directory, out_dir, langs, args.force))


if __name__ == "__main__":
    main()
