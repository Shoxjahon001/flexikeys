"""
Single source of truth for Azure Speech neural TTS voice/prosody/format
settings shared by every offline audio-generation script in tools/
(generate_aac_audio.py, generate_level_audio.py).

These values MUST match what the AAC backend's live /aac/tts endpoint uses
(backend/src/flexikeys/services/tts_provider.py) — a child must hear the
same voice whether a word comes from bundled audio or a live backend call.
That backend module is a separate Python package (FastAPI/httpx/structlog
dependencies) from these stdlib-only tools/ scripts, so it is not imported
from here; keeping the two in sync is manual, exactly as it already was
before this module existed. If you change a voice here, change it there
too, and vice versa.

Changing a voice for any locale (including adding one) requires editing
exactly this file — no script in tools/ should ever declare its own copy
of VOICES/PROSODY_RATE/OUTPUT_FORMAT.
"""
from __future__ import annotations

# lang code -> (Azure locale, neural voice name).
VOICES: dict[str, tuple[str, str]] = {
    "en": ("en-US", "en-US-AnaNeural"),
    "uz": ("uz-UZ", "uz-UZ-MadinaNeural"),
    "ru": ("ru-RU", "ru-RU-SvetlanaNeural"),
}

# Slower delivery for a 3-7 year old audience.
PROSODY_RATE = "-15%"

# Azure's X-Microsoft-OutputFormat header value — 24kHz mono MP3 at 96kbps.
OUTPUT_FORMAT = "audio-24khz-96kbitrate-mono-mp3"
