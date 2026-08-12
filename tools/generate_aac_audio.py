#!/usr/bin/env python3
"""
Offline, standalone generator for the AAC module's bundled audio files.

Runs on a developer machine only — this script never ships with the app and
is not part of the `flexikeys` Python package. It reads the 6
`shared/aac/category_*.json` files, and for every audio_asset path already
declared in them, synthesizes the matching MP3 via Azure Speech neural TTS
and writes it to that exact path.

What text gets spoken for each unit:
  - A "direct" card (e.g. ne_water)   -> its sentence_template[lang]
    ("I want water."), matching what AacAudioPlayer speaks on a direct tap.
  - A "branch" card (e.g. ne_food)    -> its label[lang] ("Food"), NOT
    sentence_template, whose "{noun}" placeholder is unfilled until a
    fringe option is chosen and would read as literal garbage. This matches
    aac_card_grid_screen.dart's own onSpeak special-case for branch cards.
  - A fringe option (e.g. ne_food_apple) -> its label[lang] ("Apple") -
    fringe options have no sentence_template field at all.

Usage:
    export AZURE_SPEECH_KEY=...
    export AZURE_SPEECH_REGION=...
    python3 tools/generate_aac_audio.py                # all langs, skip existing
    python3 tools/generate_aac_audio.py --lang ru       # Russian only
    python3 tools/generate_aac_audio.py --force         # regenerate everything

The API key is read from the environment only. It is never written to disk,
logged, or embedded in any file this script produces.
"""
from __future__ import annotations

import argparse
import glob
import json
import logging
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
log = logging.getLogger("generate_aac_audio")

REPO_ROOT = Path(__file__).resolve().parent.parent
CATEGORY_GLOB = str(REPO_ROOT / "shared" / "aac" / "category_*.json")
SUPPORTED_LANGS = ["en", "uz", "ru"]

# lang code -> (Azure locale, neural voice name)
VOICES: dict[str, tuple[str, str]] = {
    "en": ("en-US", "en-US-AnaNeural"),
    "uz": ("uz-UZ", "uz-UZ-MadinaNeural"),
    "ru": ("ru-RU", "ru-RU-SvetlanaNeural"),
}

# Slower delivery for a 3-7 year old audience.
PROSODY_RATE = "-15%"

TOKEN_URL_FMT = "https://{region}.api.cognitive.microsoft.com/sts/v1.0/issueToken"
TTS_URL_FMT = "https://{region}.tts.speech.microsoft.com/cognitiveservices/v1"


class AzureSpeechClient:
    """Subscription-key -> bearer-token -> SSML TTS, stdlib-only (urllib) so
    this script has zero dependencies beyond the interpreter itself."""

    def __init__(self, key: str, region: str) -> None:
        self._key = key
        self._region = region
        self._token: str | None = None

    def _fetch_token(self) -> str:
        req = urllib.request.Request(
            TOKEN_URL_FMT.format(region=self._region),
            data=b"",
            headers={"Ocp-Apim-Subscription-Key": self._key},
            method="POST",
        )
        with urllib.request.urlopen(req, timeout=10) as resp:
            return resp.read().decode("utf-8")

    def synthesize(self, text: str, locale: str, voice: str) -> bytes:
        if self._token is None:
            self._token = self._fetch_token()
        ssml = (
            "<speak version='1.0' xml:lang='{locale}'>"
            "<voice name='{voice}'>"
            "<prosody rate='{rate}'>{text}</prosody>"
            "</voice></speak>"
        ).format(locale=locale, voice=voice, rate=PROSODY_RATE, text=_escape_ssml(text))
        return self._post_ssml(ssml.encode("utf-8"), retried=False)

    def _post_ssml(self, ssml_bytes: bytes, *, retried: bool) -> bytes:
        req = urllib.request.Request(
            TTS_URL_FMT.format(region=self._region),
            data=ssml_bytes,
            headers={
                "Authorization": f"Bearer {self._token}",
                "Content-Type": "application/ssml+xml",
                "X-Microsoft-OutputFormat": "audio-24khz-96kbitrate-mono-mp3",
                "User-Agent": "flexikeys-aac-audio-gen",
            },
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                return resp.read()
        except urllib.error.HTTPError as e:
            if e.code == 401 and not retried:
                # Token expired mid-run (they last ~10 min; this job can
                # outlive that) - refresh once and retry this one request.
                self._token = self._fetch_token()
                return self._post_ssml(ssml_bytes, retried=True)
            raise


def _escape_ssml(text: str) -> str:
    return (
        text.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
        .replace("'", "&apos;")
    )


def _iter_audio_units(card: dict) -> list[tuple[str, dict, dict, str]]:
    """Yields (ref_id, source_text_map, audio_asset_map, source_field) for a
    card and every one of its fringe options."""
    units = []
    source = card["sentence_template"] if card["kind"] == "direct" else card["label"]
    source_field = "sentence_template" if card["kind"] == "direct" else "label (branch card)"
    units.append((card["id"], source, card.get("audio_asset", {}), source_field))
    for opt in card.get("fringe_options", []):
        units.append((opt["id"], opt["label"], opt.get("audio_asset", {}), "label (fringe option)"))
    return units


def _run(client: AzureSpeechClient, langs: list[str], force: bool) -> None:
    generated = 0
    skipped_existing = 0
    skipped_no_path = 0
    failed: list[tuple[str, str, str]] = []

    for fp in sorted(glob.glob(CATEGORY_GLOB)):
        data = json.loads(Path(fp).read_text(encoding="utf-8"))
        log.info("%s (%d cards)", Path(fp).name, len(data["cards"]))

        for card in data["cards"]:
            for ref_id, source_map, audio_map, source_field in _iter_audio_units(card):
                for lang in langs:
                    rel_path = audio_map.get(lang)
                    text = source_map.get(lang)
                    if not rel_path:
                        skipped_no_path += 1
                        continue
                    if not text:
                        log.warning("  %s [%s]: no %s text for lang=%s, skipping", ref_id, lang, source_field, lang)
                        continue

                    out_file = REPO_ROOT / rel_path
                    if out_file.exists() and not force:
                        skipped_existing += 1
                        continue

                    locale, voice = VOICES[lang]
                    try:
                        audio_bytes = client.synthesize(text, locale, voice)
                    except Exception as e:  # noqa: BLE001 - report and continue the batch
                        log.error("  FAILED %s [%s]: %s (%s)", ref_id, lang, text, e)
                        failed.append((ref_id, lang, str(e)))
                        continue

                    out_file.parent.mkdir(parents=True, exist_ok=True)
                    out_file.write_bytes(audio_bytes)
                    generated += 1
                    log.info("  + %s [%s] <- %s: %r", ref_id, lang, source_field, text)

    log.info("")
    log.info("=== Summary ===")
    log.info("Generated:        %d", generated)
    log.info("Skipped (exists): %d", skipped_existing)
    if skipped_no_path:
        log.info("Skipped (no path declared): %d", skipped_no_path)
    log.info("Failed:           %d", len(failed))
    for ref_id, lang, err in failed:
        log.info("  - %s [%s]: %s", ref_id, lang, err)
    if failed:
        sys.exit(1)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--lang", default="all", choices=[*SUPPORTED_LANGS, "all"],
                         help="Language to generate (default: all)")
    parser.add_argument("--force", action="store_true", help="Overwrite existing audio files")
    args = parser.parse_args()

    key = os.environ.get("AZURE_SPEECH_KEY", "")
    region = os.environ.get("AZURE_SPEECH_REGION", "")
    if not key or not region:
        log.error("AZURE_SPEECH_KEY and AZURE_SPEECH_REGION must both be set in the environment.")
        sys.exit(1)

    langs = SUPPORTED_LANGS if args.lang == "all" else [args.lang]
    client = AzureSpeechClient(key, region)
    _run(client, langs, args.force)


if __name__ == "__main__":
    main()
