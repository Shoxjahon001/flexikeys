# Progress Log

## Uzbek AAC voiceovers — human recordings wired in (2026-09-02)

**What changed**

- 42 of 45 Uzbek AAC audio keys now play a human recording instead of falling
  through to TTS. Files live at `shared/aac/audio/uz/{key}.m4a` (AAC LC,
  44.1kHz, mono, 96kbps, loudness-normalized to −16 LUFS — converted by the
  user from the original `.ogg`/Opus recordings for iOS compatibility, since
  Opus isn't in AVFoundation's supported format list).
- `shared/aac/category_*.json` — `audio_asset.uz` updated for the 42 confirmed
  keys, `.mp3` → `.m4a`, same path convention as en/ru (`generate_aac_audio.py`
  target paths). en/ru untouched (they had no bundled audio before this either
  — `shared/aac/audio/` didn't exist at all prior to this work).
- **Real bug found and fixed**: `pubspec.yaml`'s `- shared/aac/` directory
  asset declaration is **not recursive** — proven with a full clean rebuild
  that produced zero files under `shared/aac/audio/` in the bundled output,
  despite `shared/aac/` being declared. Added an explicit
  `- shared/aac/audio/uz/` entry. Without this fix, every step of this task
  would have been silently broken in production too, not just in tests —
  `AssetSource` lookups use the same asset-bundling mechanism as `flutter test`.
  The same gap affects `shared/aac/animations/` (also nested, also never
  bundled) but that's currently harmless since nothing in the app reads the
  `animation_asset` field yet — flagging for whoever eventually wires that up.
- `lib/features/aac/data/aac_audio_player.dart` — doc comment updated to
  reflect that bundled audio containers aren't uniform across languages
  anymore (en/ru will be Azure MP3 once generated, uz is human-recorded M4A).
  No functional/lookup code changed — `AssetSource` was always
  extension-agnostic.
- New test: `test/features/aac/data/aac_uz_audio_coverage_test.dart` — asserts
  every uz audio key either resolves to a real bundled asset or is one of the
  3 documented pending exceptions below; fails if either list goes stale.
- `voice_uzb/mapping.csv` — key → original recording filename → transcript,
  for the 42 wired keys.

**MISSING list — 3 keys still on the TTS fallback, no human recording wired**

| key | why |
|---|---|
| `pe_dad` | Closest candidate recording (`Men adamni hohlayman.ogg`) doesn't clearly say "otam" (dad) — "adam" isn't a standard Uzbek word for father. Needs a listen + confirm, or a re-record. |
| `pa_tablet` | Recording says "I want to play with the tablet" (`Men planshet o'ynamoqchiman`); app text is "I want a tablet" (`Men planshetni xohlayman.`) — different communicative intent, not just phrasing. |
| `pl_bedroom` | Recording says "I want to go to my bed" (`Men yotog'imga bormoqchiman`); app text is "I want to go to the bedroom" (`Men yotoqxonaga bormoqchiman.`) — different word (bed vs. bedroom). |

All 3 currently fall through to `AacNeuralTtsService` (backend Azure neural
TTS) then `TtsService` (Google Translate), exactly as every uz key did before
this change — no regression, just not yet upgraded to a human voice.

**Verification**

- `flutter analyze`: clean (1 pre-existing, unrelated info-level lint).
- `flutter test`: 227/227 passing (226 pre-existing + 1 new coverage test).
- `flutter build apk --debug`: succeeds; confirmed via `unzip -l` that all 42
  `.m4a` files are actually present in the built APK under
  `assets/flutter_assets/shared/aac/audio/uz/`.
- Pre-wiring audio QC (decode integrity, format, duration floor, silence):
  all 42 `.m4a` files pass — 0 decode errors, 0 format mismatches against the
  claimed AAC/44.1kHz/mono spec, 0 files under 0.4s (shortest 0.80s), 0
  silent/near-silent files. Loudness spread is tight (3.9dB) post-normalization
  — the two files flagged as quiet outliers in the original `.ogg` set
  (`da_brush_teeth`, `da_bath`) are now right in line with the rest.
- APK size delta: +1.1MB total (the 42 files' combined size) — nothing was
  removed, since no Azure-generated uz MP3s ever existed to remove.

**What's left to do**

1. Decide on the 3 MISSING keys above — confirm/reject `pe_dad`'s candidate,
   decide whether to accept `pa_tablet`/`pl_bedroom`'s close-but-inexact
   recordings or wait for a re-record, then re-run
   `tools/generate_aac_audio.py` (Azure) or wire a corrected human recording
   for whichever keys still need one.
2. `en`/`ru` still have zero bundled audio — `generate_aac_audio.py` has
   never actually been run (needs `AZURE_SPEECH_KEY`/`AZURE_SPEECH_REGION`).
   Once it is, add `shared/aac/audio/en/` and `shared/aac/audio/ru/` to
   `pubspec.yaml`'s `assets:` list explicitly (same non-recursive-directory
   gap applies to them too).
3. `voice_uzb/` (original `.ogg` recordings) and `voice_uzb_m4a/` (converted
   staging folder) are left in place, untracked — not deleted, since they're
   the only source material if a re-record/re-convert is ever needed. Not
   part of the app's asset tree.
