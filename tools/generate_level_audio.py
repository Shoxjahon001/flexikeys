#!/usr/bin/env python3
"""
Offline, standalone generator for level-content (Letters, Numbers, Colors,
Fruits, Animals, Food) pronunciation audio.

Runs on a developer machine only — this script never ships with the app and
is not part of the `flexikeys` Python package. It reads
shared/level_content/audio_manifest.json (generated from the real content
packs by `flutter test tool/export_audio_manifest.dart` — run that first,
or whenever lib/data/content_packs/*.dart changes) and, for every entry,
synthesizes the matching MP3 via Azure Speech neural TTS and writes it to
the declared path. Uses the exact same Azure-calling mechanism as
tools/generate_aac_audio.py, and imports its voice/prosody/format settings
from the shared tools/tts_voices.py — the two scripts cover different
content and are meant to be run separately, but must never disagree on
what a given locale sounds like.

Usage:
    flutter test tool/export_audio_manifest.dart   # regenerate the manifest
    export AZURE_SPEECH_KEY=...
    export AZURE_SPEECH_REGION=...
    python3 tools/generate_level_audio.py                # all langs, skip existing
    python3 tools/generate_level_audio.py --lang ru       # Russian only
    python3 tools/generate_level_audio.py --force         # regenerate everything

The API key is read from the environment only. It is never written to disk,
logged, or embedded in any file this script produces.
"""
from __future__ import annotations

import argparse
import json
import logging
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

from tts_voices import OUTPUT_FORMAT, PROSODY_RATE, VOICES

logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
log = logging.getLogger("generate_level_audio")

REPO_ROOT = Path(__file__).resolve().parent.parent
MANIFEST_PATH = REPO_ROOT / "shared" / "level_content" / "audio_manifest.json"

# VOICES (imported above) has an entry for every AAC-supported locale,
# including uz — but SUPPORTED_LANGS here is deliberately narrower: no `uz`
# ContentPack exists yet for level content (Phase 1 left `uz` on the `en`
# content fallback, see PROGRESS.md), so the manifest never has a `uz` key
# and there is nothing to generate for it. Add "uz" here once a real uz
# content pack exists — the voice is already registered and ready.
SUPPORTED_LANGS = ["en", "ru"]

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
                "X-Microsoft-OutputFormat": OUTPUT_FORMAT,
                "User-Agent": "flexikeys-level-audio-gen",
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


def _run(client: AzureSpeechClient, manifest: dict, langs: list[str], force: bool) -> None:
    generated = 0
    skipped_existing = 0
    failed: list[tuple[str, str, str]] = []

    for lang in langs:
        entries = manifest.get(lang, [])
        log.info("%s (%d items)", lang, len(entries))
        locale, voice = VOICES[lang]

        for entry in entries:
            out_file = REPO_ROOT / entry["path"]
            if out_file.exists() and not force:
                skipped_existing += 1
                continue

            try:
                audio_bytes = client.synthesize(entry["text"], locale, voice)
            except Exception as e:  # noqa: BLE001 - report and continue the batch
                log.error("  FAILED %s [%s]: %r (%s)", entry["id"], lang, entry["text"], e)
                failed.append((entry["id"], lang, str(e)))
                continue

            out_file.parent.mkdir(parents=True, exist_ok=True)
            out_file.write_bytes(audio_bytes)
            generated += 1
            log.info("  + %s [%s]: %r", entry["id"], lang, entry["text"])

    log.info("")
    log.info("=== Summary ===")
    log.info("Generated:        %d", generated)
    log.info("Skipped (exists): %d", skipped_existing)
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

    if not MANIFEST_PATH.exists():
        log.error(
            "%s does not exist — run `flutter test tool/export_audio_manifest.dart` first.",
            MANIFEST_PATH,
        )
        sys.exit(1)

    key = os.environ.get("AZURE_SPEECH_KEY", "")
    region = os.environ.get("AZURE_SPEECH_REGION", "")
    if not key or not region:
        log.error("AZURE_SPEECH_KEY and AZURE_SPEECH_REGION must both be set in the environment.")
        sys.exit(1)

    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    langs = SUPPORTED_LANGS if args.lang == "all" else [args.lang]
    client = AzureSpeechClient(key, region)
    _run(client, manifest, langs, args.force)


if __name__ == "__main__":
    main()
