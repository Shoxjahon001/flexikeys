#!/usr/bin/env python3
"""
Guards against tools/generate_aac_audio.py and tools/generate_level_audio.py
ever resolving to different voice/prosody/format settings for the same
locale — e.g. if someone "temporarily" re-declares a local VOICES override
in one script instead of editing tools/tts_voices.py.

Stdlib-only (unittest), matching the zero-dependency ethos of the scripts
it covers. Run directly:

    python3 tools/test_tts_voices_parity.py

or via pytest if available:

    python3 -m pytest tools/test_tts_voices_parity.py
"""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import generate_aac_audio as aac  # noqa: E402
import generate_level_audio as level  # noqa: E402
import tts_voices  # noqa: E402


class TtsVoicesParityTest(unittest.TestCase):
    def test_both_scripts_import_the_shared_voices_object_itself(self) -> None:
        """Not just equal values — the exact same object, so a script can't
        silently shadow it with a same-looking local dict."""
        self.assertIs(aac.VOICES, tts_voices.VOICES)
        self.assertIs(level.VOICES, tts_voices.VOICES)

    def test_both_scripts_import_the_shared_prosody_rate(self) -> None:
        self.assertIs(aac.PROSODY_RATE, tts_voices.PROSODY_RATE)
        self.assertIs(level.PROSODY_RATE, tts_voices.PROSODY_RATE)

    def test_both_scripts_import_the_shared_output_format(self) -> None:
        self.assertIs(aac.OUTPUT_FORMAT, tts_voices.OUTPUT_FORMAT)
        self.assertIs(level.OUTPUT_FORMAT, tts_voices.OUTPUT_FORMAT)

    def test_every_aac_locale_has_a_voice_registered(self) -> None:
        for lang in aac.SUPPORTED_LANGS:
            self.assertIn(lang, tts_voices.VOICES, f"missing voice for {lang}")

    def test_every_level_content_locale_has_a_voice_registered(self) -> None:
        for lang in level.SUPPORTED_LANGS:
            self.assertIn(lang, tts_voices.VOICES, f"missing voice for {lang}")

    def test_level_content_locales_are_a_subset_of_aac_locales(self) -> None:
        """Level content may lag AAC (no uz ContentPack yet), but must never
        support a locale AAC doesn't — that would mean level content has a
        voice AAC was never taught to speak with."""
        self.assertTrue(set(level.SUPPORTED_LANGS).issubset(set(aac.SUPPORTED_LANGS)))

    def test_backend_endpoint_voices_documented_as_matching(self) -> None:
        """backend/src/flexikeys/services/tts_provider.py declares its own
        independent copy (a different Python package — see tts_voices.py's
        own docstring for why it isn't imported directly). This test can't
        reach across that package boundary, so it instead pins down the
        exact values that file must keep matching by hand, failing loudly
        if tts_voices.py itself ever changes without that file being
        updated to match."""
        self.assertEqual(
            tts_voices.VOICES,
            {
                "en": ("en-US", "en-US-AnaNeural"),
                "uz": ("uz-UZ", "uz-UZ-MadinaNeural"),
                "ru": ("ru-RU", "ru-RU-SvetlanaNeural"),
            },
        )
        self.assertEqual(tts_voices.PROSODY_RATE, "-15%")
        self.assertEqual(tts_voices.OUTPUT_FORMAT, "audio-24khz-96kbitrate-mono-mp3")


if __name__ == "__main__":
    unittest.main()
