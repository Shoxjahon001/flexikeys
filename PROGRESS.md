# Progress Log

## Russian learning-content localization — Phase 2: Russian content (2026-09-03)

**What changed**

- `ContentItem` gained an optional `pronunciation` field + `spokenText`
  getter (`pronunciation ?? word`) — needed because Cyrillic Ь/Ъ have no
  standalone letter sound and must be spoken by *name* ("мягкий знак" /
  "твёрдый знак") rather than the raw glyph. Every other item is unaffected
  (`pronunciation: null`, `spokenText == word`).
- `letters_content_packs.dart`: English completed from A-O (15) to the full
  A-Z (26). Added the Russian pack — all 33 letters of the modern alphabet,
  in order; Ё included as its own letter (distinct from Е, real "yo"
  sound, no override needed); Ь/Ъ use the `pronunciation` override above.
- `spelling_content_packs.dart`: added `ru` packs for Numbers, Colors,
  Fruits, Animals, Food — same item counts and concepts as `en`
  (e.g. `animals.zebra` → ЗЕБРА), each with `alphabet` set to the full
  33-letter Cyrillic string (`_cyrillicAlphabet`, one shared constant so it
  can't drift). Numbers stay `ordered: true` in numeric order, matching en.
- `letters_stage1_screen.dart`: the hardcoded mid-level celebration trigger
  (`_current == 7`, tuned for the old fixed 15-letter English list) is now
  `_current == _letters.length ~/ 2` — verified to reproduce the exact same
  trigger point for N=15 (`15 ~/ 2 == 7`), and generalizes correctly for
  N=26 (English) and N=33 (Russian). Every TTS call site now routes through
  `_speakTextFor()`, which looks up `spokenText` so Ь/Ъ are pronounced
  correctly instead of TTS trying to voice the bare glyph.

**A known interim UX gap, flagged rather than silently shipped**: Russian
Letters is 33 items in a single flat run today — Phase 2b (not yet built)
is what chunks this into digestible groups via the `LetterGroup`/
`LetterGroupsScreen` pattern already proven in the Drawing module. Until
2b lands, a Russian child does one longer continuous letters run with one
proportional celebration break in the middle — functional and not a
"failure" by CLAUDE.md's rules, just not optimally paced yet.

**Words with a real length "jump" worth a second look** (flagging per your
own instruction, not silently avoided): Colors jumps from 4-7 unique
letters up to ФИОЛЕТОВЫЙ (9) and КОРИЧНЕВЫЙ (10, right at the current
technical ceiling — see below); Fruits jumps from 3 up to АПЕЛЬСИН/
ВИНОГРАД (8). These are the standard, correct Russian words — I didn't
find shorter true synonyms — but call them out per your instruction rather
than deciding unilaterally.

**Real technical ceiling, not just a UX nicety**: `generic_game_screen.dart`'s
`_gridSize` does `target.clamp(uniqueCount, 10)`, which *throws* if a
word's unique-letter count exceeds 10 — untouched in this phase (that's
Phase 3's job). Every ru word was individually checked and is verified
by a test to be ≤10 unique letters (max: КОРИЧНЕВЫЙ at exactly 10, which
is safe but leaves zero distractor room — the single most
Phase-3-motivating data point in this set).

**Tests** (49 new/changed, 292/292 total passing)

- Letters: full 33-letter Russian alphabet order/ids, Ё distinctness,
  Ъ/Ь pronunciation overrides, English A-Z snapshot, ascii-id checks.
- Spelling packs: per-category script-purity (every `ru` word and the
  `alphabet` pool match `^[А-ЯЁ]+$`, i.e. zero Latin characters can appear
  — this is the "assertion that fails loudly on mixed scripts" the spec
  asked for), alphabet-pool coverage (every word's letters exist in the
  pool), the ≤10-unique-letter safety ceiling, item-count parity with en,
  ascii-id uniqueness, and numbers-stay-numeric-order.

**Verification**: `flutter analyze` clean (1 pre-existing unrelated lint);
`flutter test` 292/292 passing.

**What's left to do**

1. Your review of the Russian word list (see chat) before anything further
   lands on top of it.
2. Phase 2b — propose the exact 33-letter grouping split and the group
   navigation UX (sequential unlock vs. all-visible) for approval before
   building.
3. Phase 3 — Cyrillic keyboard: length-scaled key count, narrow-device
   touch-target fix, and — informed by this phase's data — a proper answer
   for the КОРИЧНЕВЫЙ-style zero-distractor edge case.
4. Phase 4 — Russian audio pipeline (still no bundled audio for level
   content at all; this is a new build against `ru-RU-SvetlanaNeural`,
   not an extension of an existing one).

## Russian learning-content localization — Phase 1: content architecture (2026-09-03)

**Context**: FlexiKeys' Letters/Numbers/Colors/Fruits/Animals/Food spelling
tasks were English-only regardless of UI language. Phase 0 investigation
(not repeated here) found two disconnected systems in the codebase — the
one that actually ships (`lib/data/level_configs.dart` +
`GenericGameScreen`/`LettersStage1Screen`, hardcoded English) and a fully
localized but completely unwired one (`shared/curriculum/*.json` +
`LessonPlayerScreen`, unreachable from the app). Decision: target the
shipped system only; the dormant one stays untouched.

**What changed (pure architecture — no new words added yet)**

- New `lib/data/content_packs/` module:
  - `content_pack.dart` — `ContentItem` (stable locale-scoped id, e.g.
    `'en.animals.zebra'`, used for audio lookup/progress — never a
    positional index), `ContentPack` (one category's content for one
    locale), `ContentPackResolver` (resolves a UI locale to its pack,
    falling back to `en` with a loud `debugPrint` when a locale has no
    pack of its own — a silent fallback would ship English words to a
    non-English child with no visible sign anything was wrong).
  - `spelling_content_packs.dart` — `en` packs for numbers/colors/fruits/
    animals/food, migrated verbatim from the old `LevelConfig`/`GameItem`
    data (same ids, words, order, star rewards, colors).
  - `letters_content_packs.dart` — `en` pack for Letters (A-O, 15 letters),
    migrated verbatim from `LettersStage1Screen`'s old hardcoded list.
    Completing English to the full A-Z, and adding the Russian pack, are
    both deferred to Phase 2 (content-writing) — kept out of this
    architecture-only phase so its "behavior unchanged" claim stays exact.
- `lib/screens/levels_screen.dart` — `_onLevelTap` now resolves the
  category's pack via `SpellingContentPacks.resolve`/
  `LettersContentPacks.resolve` using `Localizations.localeOf(context)`
  (the UI language notifier, not a separate content-language setting, per
  spec) and passes the resolved `ContentPack` as the route argument.
- `lib/screens/game/generic_game_screen.dart` and
  `lib/screens/game/letters_stage1_screen.dart` — consume `ContentPack`/
  `ContentItem` instead of `LevelConfig`/`GameItem`; the distractor
  alphabet pool moved from a hardcoded literal into `ContentPack.alphabet`
  (still `'ABCDEFGHIJKLMNOPQRSTUVWXYZ'` for `en`, ready for a Cyrillic pool
  in Phase 3); every `TtsService.speak(...)` call now passes
  `locale: pack.locale` explicitly (was implicitly `'en'` before — for
  every pack that exists today that's the same value, so behavior is
  unchanged, but the plumbing is now real end-to-end for Phase 4).
- Deleted `lib/data/level_configs.dart` (fully superseded, zero remaining
  references).
- `LettersStage2Screen` (a redundant, unreachable `ONE`-`TEN` spelling
  screen — confirmed dead code, no navigation path reaches it) was
  deliberately left untouched, per an explicit decision to keep it out of
  scope.

**Tests** (28 new, 255/255 total passing)

- `test/data/content_packs/{content_pack,spelling_content_packs,
  letters_content_packs}_test.dart` — snapshot every id/word/color/flag in
  every `en` pack against the pre-refactor data; verify `uz`/`ru` both
  resolve to the byte-identical `en` pack instance today (proving the
  hard "EN/UZ behavior unchanged" constraint at the data layer).
- `test/screens/game/{generic_game_screen,letters_stage1_screen}_test.dart`
  — widget-level wiring smoke tests (push the real route with a resolved
  pack argument, assert the right word/letter renders) — catches route-
  argument-plumbing mistakes a data-only test can't. Needed a realistic
  phone-sized test surface (390x844); the default 800x600 test canvas is
  shorter than any real phone and overflowed this screen's `Column` —
  same class of viewport issue Phase 0 flagged as a pre-existing risk on
  narrow real devices, now also visible in the test harness.

**Verification**: `flutter analyze` clean (1 pre-existing unrelated lint);
`flutter test` 255/255 passing.

**What's left to do (see PHASE 0 report in conversation for full plan)**

1. Phase 2 — write the Russian content packs (all 5 categories + full
   33-letter alphabet) and complete English Letters to A-Z alongside it;
   propose the full word list for review before landing.
2. Phase 2b — chunk Russian's 33 letters (English's 26 stays a single flat
   run, unchanged) into groups using the existing `LetterGroup`/
   `LetterGroupsScreen` pattern already proven in the Drawing module.
3. Phase 3 — Cyrillic keyboard: `ContentPack.alphabet` already threads a
   locale-specific distractor pool through; still need the length-scaled
   key-count function and narrow-device layout fix (see Phase 0's flagged
   pre-existing touch-target gap at 10-key boards).
4. Phase 4 — Russian audio pipeline (level content currently has *no*
   bundled audio at all, live Google-Translate TTS only — this is a new
   build, not an extension, following AAC's `ru-RU-SvetlanaNeural` voice).

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
