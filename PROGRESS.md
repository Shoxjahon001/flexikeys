# Progress Log

## Russian learning-content localization — Phase 4b: voice-config parity audit (2026-09-03)

Before running any real generation, verified — by direct quote comparison,
not inference — that `tools/generate_level_audio.py` would speak with the
exact same voice/prosody/format AAC already uses, for every locale that
overlaps. Full comparison table posted in chat; summary:

- `en`/`ru` voice, rate (`-15%`), format (`audio-24khz-96kbitrate-mono-mp3`),
  and SSML shape were already identical across the AAC script, the AAC
  `/aac/tts` backend endpoint, and my level-content script — confirmed, not
  assumed.
- **Real defect found**: `uz` exists in AAC (`uz-UZ-MadinaNeural`) but was
  entirely absent from `generate_level_audio.py`'s voice table — not a
  default substitution, a missing entry. Root cause: no `uz` `ContentPack`
  exists yet for level content (Phase 1 left `uz` on the `en` fallback),
  so there was nothing to generate for it — but the script should still
  know the voice exists.
- The two AAC sources (script and backend endpoint) already had this same
  problem *before* this phase's work — an independent inline copy each,
  kept in sync by comment/convention only. That's out of scope here (a
  separate Python package boundary — see `tools/tts_voices.py`'s docstring)
  and hasn't been touched; flagged for a future decision.

**Fix**: new `tools/tts_voices.py` — the single source of truth (`VOICES`,
with `uz` restored, `PROSODY_RATE`, `OUTPUT_FORMAT`). Both
`generate_aac_audio.py` and `generate_level_audio.py` now import from it;
neither declares its own copy anymore. Changing a voice for any locale now
requires editing exactly one file.

**Proof the AAC script's actual output is unchanged**: no Azure credentials
are available in this environment, so a literal before/after live-generation
hash comparison wasn't possible (flagged to the user, who accepted the
substitute). Instead: captured the exact SSML string `AzureSpeechClient.
synthesize()` would send for one sample per locale (en/ru/uz) using the
*unmodified* script, then again using the *refactored* script — SHA-256 of
both snapshots is `683661c8...` — byte-for-byte identical. `git diff` on
`generate_aac_audio.py` shows only the VOICES/PROSODY_RATE declarations
were removed in favor of an import, and the hardcoded output-format string
replaced with the same-valued imported constant — nothing else touched.

**New drift guard**: `tools/test_tts_voices_parity.py` (stdlib `unittest`,
matching the scripts' own zero-dependency design) — asserts both scripts
import the exact same `VOICES`/`PROSODY_RATE`/`OUTPUT_FORMAT` objects (not
just equal values), every `SUPPORTED_LANGS` entry has a registered voice,
level content's locale set stays a subset of AAC's, and pins the values
`tts_voices.py` must keep matching in the backend's independent copy.
`python3 tools/test_tts_voices_parity.py` — 7/7 passing.

## Russian learning-content localization — Phase 4: audio pipeline (in progress, blocked on Azure credentials) (2026-09-03)

**Status: pipeline built and verified end-to-end; no real audio generated
yet.** `AZURE_SPEECH_KEY`/`AZURE_SPEECH_REGION` aren't set in this
environment — the same state AAC's own `en`/`ru` voices are already in
(configured, never actually generated). Everything up to the actual Azure
call is done and tested; waiting on credentials to run it for real.

**What changed**

- `tool/export_audio_manifest.dart` — a new Dart script (run via `flutter
  test tool/export_audio_manifest.dart`, not `dart run`, since it
  transitively imports `package:flutter/material.dart` through the
  content-pack files and plain `dart run` can't compile that outside the
  Flutter toolchain) that reads the real `ContentPack` data — the single
  source of truth — and writes `shared/level_content/audio_manifest.json`:
  one `{id, text, path}` entry per item, `text` = `item.spokenText` (so
  Ь/Ъ get their letter-name pronunciation, not the bare glyph). This
  bridges the Dart/Python boundary: level content lives in typed Dart,
  but the actual TTS generator (matching AAC's proven pattern) is Python.
  Currently 85 `en` items + 92 `ru` items.
- `tools/generate_level_audio.py` — new, sibling to `generate_aac_audio.py`,
  reusing its exact `AzureSpeechClient` (stdlib-only, token-then-SSML
  pattern) and `VOICES` table (`en-US-AnaNeural`, `ru-RU-SvetlanaNeural` —
  same voices AAC uses). Reads the manifest above instead of AAC's
  `category_*.json` cards. `python3 tools/generate_level_audio.py` once
  credentials are set.
- `lib/services/level_audio_player.dart` — new `LevelAudioPlayer`, mirrors
  `AacAudioPlayer`'s tiered-fallback pattern (minus its neural-TTS-backend
  middle tier — no such endpoint exists for level content, out of scope
  here): tier 1 tries the bundled asset at
  `shared/level_content/audio/{locale}/{bare id}.mp3`; tier 2 falls back
  to the existing `TtsService` (live, cached) exactly as every level-
  content call site already did before this phase. `assetPathFor()` is
  the one place this path is built — the manifest exporter now calls it
  directly rather than reimplementing the same logic, so the two can't
  drift apart.
- `generic_game_screen.dart` and `letters_stage1_screen.dart`: every
  `TtsService.instance.speak(...)` call site replaced with
  `LevelAudioPlayer.instance.speak(item, locale: ...)`. Applied to *every*
  locale, not gated behind a ru-only flag like Phase 3's changes — unlike
  a visual/layout change, an asset-first-then-identical-TTS-fallback is
  not an observable behavior difference when the asset doesn't exist
  (which is true for every locale right now), and this is what makes the
  app ready to pick up `en` audio too, whenever that gets generated.

**Tests** (3 new, 326/326 total passing): `assetPathFor` path-convention
unit tests. No regressions — every existing widget test that exercises
these two screens still passes, since the tier-2 TTS fallback is
byte-identical to what those call sites did directly before.

**Deliberately not done yet, and why**

- `pubspec.yaml` doesn't declare `shared/level_content/audio/en/` or
  `.../ru/` — declaring a nonexistent asset directory fails the Flutter
  build (the exact same non-recursive-directory lesson from the Uzbek AAC
  work). Adding it now, before real files exist, would break `flutter
  build`/`flutter test` for everyone.
- The build/test-time "every content item has a matching audio asset"
  coverage test isn't written yet — writing it against zero real files
  would just fail permanently, which isn't a useful regression guard.
  Both of these land in the same commit as the real generated audio.

**What's left to do**

1. You provide `AZURE_SPEECH_KEY`/`AZURE_SPEECH_REGION`; I run
   `tools/generate_level_audio.py` for real, report the generated file
   count per locale, add the two pubspec asset entries, and add the
   coverage test — then it'll actually pass, meaningfully.
2. Manual QA once real audio exists: confirm a spoken word/letter
   actually matches what's shown, in both `en` and `ru`.

## Russian learning-content localization — Phase 3: Cyrillic keyboard (2026-09-03)

**What changed**

- New `lib/data/content_packs/keyboard_key_count.dart`: `keyCountFor(int
  uniqueLetterCount)` — the single, unit-tested mapping from an answer's
  unique-letter count to board size (6→8→10, targeting ~3 distractors,
  degrading gracefully to as few as 0 once the 10-key ceiling can't fit
  the target — true today only for КОРИЧНЕВЫЙ, exactly 10 unique letters).
  Full generated table reviewed and approved before wiring (see chat).
  Also `stableHash(text)` — the same DJB2 hash `TtsService._key` already
  uses, reused here to seed a deterministic per-item `Random` so a given
  item's keyboard always shuffles the same way (a retry/relaunch shows
  the identical board).
- `ContentPack` gained `answerDrivenKeyCount: bool` (default false). When
  true: `GenericGameScreen`'s key count comes from `keyCountFor` instead
  of the old position-based 6/8/10 stages, and the grid shuffle is seeded
  from `stableHash(item.id)` instead of the screen's shared unseeded
  `Random`. Set `true` on all 5 `ru` spelling packs; every `en`/`uz` pack
  leaves it `false` and is provably byte-identical to before this phase
  (see the regression-guard test below) — applying this universally would
  have changed English's existing behavior (a real tension between the
  spec's general framing and the hard "EN/UZ unchanged" constraint,
  resolved in favor of the constraint, flagged and confirmed in chat).
- Narrow-device layout fix: 8- and 10-key boards (when
  `answerDrivenKeyCount`) now share a 4-column layout — a plain 2×5 grid
  computed to ~53pt tiles on a 320pt-wide device, well under the 64dp
  child touch-target minimum; 4 columns (10 wraps to 3 rows) holds ≥64dp
  down to that same width. En/uz keep the exact original 5-column layout
  at >8 keys, untouched. Reclaiming the vertical room a 3rd grid row
  needs on a short device required trimming several paddings/gaps
  (section gaps, question-card padding, the digit-hint tile size) — all
  gated behind the same flag, so en/uz spacing is pixel-for-pixel
  unchanged.
- Answer slots: no new code needed — the existing `FittedBox(fit:
  BoxFit.scaleDown)` around the word-boxes row already scales the whole
  row down uniformly rather than clipping/overflowing, verified to hold
  up at the longest real word (ОДИННАДЦАТЬ, 11 characters) on the
  narrowest device.

**Tests** (13 new, 323/323 total passing):
- `keyCountFor`/`stableHash` unit tests (monotonic, never below the
  answer's own letter count, deterministic, no collisions among real ids).
- The exact scenario the spec named: ОДИННАДЦАТЬ (longest ru word, 10-key
  board) rendered at 320×568 — asserts zero exceptions, all 10 tiles
  ≥64dp, every letter still findable (not clipped).
- КОРИЧНЕВЫЙ (the zero-distractor edge case) — renders without crashing.
- Regression guard: an `en` word forced onto a 10-key board still uses
  5 columns, not the new 4-column ru layout (this test exists because I
  initially wrote the layout fix unconditionally and caught the EN
  regression myself before it shipped).
- Determinism: pushing the identical `ru` item twice produces the
  identical keyboard tile order both times.

**Verification**: `flutter analyze` clean (1 pre-existing unrelated lint);
`flutter test` 323/323 passing.

**What's left to do**

1. Phase 4 — Russian audio pipeline (still no bundled audio for level
   content at all; a new build against `ru-RU-SvetlanaNeural`).
2. Manual QA once Phase 4 lands: a real device playthrough — Phase 3 was
   verified with widget tests (including an actual 320×568 render) but
   not a physical device.

## Russian learning-content localization — Phase 2b: sequencing & grouping (2026-09-03)

**What changed**

- `ContentPack` gained two new fields, both data-driven (no `if (locale ==
  'ru')` branches anywhere):
  - `groupSizes: List<int>?` — when set, the pack is too long for one
    sitting and should be presented as small groups (null = flat run,
    today's behavior for every existing pack). New `splitIntoGroups(pack)`
    turns it into real, independently-progress-trackable `ContentPack`s.
  - `lengthSort: bool` — when true, items are presented shortest-word-first
    (deterministic tie-break by original position, never random) instead
    of `ordered`'s fixed-vs-shuffled choice.
- New `orderItemsForSession(pack, rng)` (in `content_pack.dart`) is the one
  place both the shuffle/fixed/length-sort decision lives — `generic_game_
  screen.dart`'s `_initQuestions()` now just calls it instead of carrying
  the logic inline, so it's unit-testable directly.
- Russian Letters pack (33 letters) now sets `groupSizes: [4,4,4,4,4,4,3,
  3,3]` — 9 groups (А-Г, Д-Ж, З-К, Л-О, П-Т, У-Ц, Ч-Щ, Ъ-Ь, Э-Я), the same
  front-load-4s-then-3s convention already proven for English's 26 letters
  in the Drawing module's `kLetterGroups`. Its `starsReward` dropped to 5
  (from the default 10) — it's now 9 separately-rewarded units, matching
  the Drawing module's own per-group reward value, not one lump sum.
  English/Uzbek Letters packs are untouched (no `groupSizes` — stay a flat
  run exactly as Phase 2 shipped).
- Russian Colors/Fruits/Animals/Food now set `lengthSort: true`. Numbers
  stays exempt (`ordered: true`, already-numeric item order, untouched) —
  confirmed no other category has an inherent order that would be broken
  by length-sorting.
- New `lib/screens/game/letters_group_picker_screen.dart` — reuses the
  exact UX already shipped for the Drawing module's letter groups
  (`letter_groups_screen.dart`): all groups visible as cards, sequential
  unlock with lock icons, but built on this feature's own legacy
  `AppTheme` surface rather than that screen's `FkPlayTheme` (per
  CLAUDE.md's design-system migration boundary — Learn-tab gameplay stays
  legacy). Registered at `/letters_group_picker`.
- `levels_screen.dart`'s `_onLevelTap` now branches on `pack.groupSizes !=
  null` (data, not a locale check) to decide whether tapping "Letters"
  goes to the new picker first or straight to `/game_stage1` as before.
- `letters_stage1_screen.dart`'s `_onComplete()` generalized from
  hardcoded `'letters_1'`/`'letters'`/`10` to the pack's own
  `categoryId`/`starsReward` — verified to reproduce the exact prior
  behavior byte-for-byte for the ungrouped case (both en/uz packs default
  to `starsReward: 10`). A single group's completion instead just marks
  its own slug (`letters_ru_group_N`); the picker screen detects "every
  group done" and fires the umbrella `letters`/`letters_1` completion
  (0 additional stars — each group already paid out its own), which is
  what actually unlocks Numbers for a Russian child, same as it always
  has for English.

**Tests** (17 new, 311/311 total passing): `splitIntoGroups` correctness
(9 groups, exact `[4,4,4,4,4,4,3,3,3]` split, unique slugs, ids reused
verbatim, no gaps/dupes across all 33 letters); `orderItemsForSession`
exercised directly (not re-implemented in the test) — deterministic
length-ramp for all 4 `ru` word categories, numbers untouched, en/uz
still shuffle exactly as before; a widget test pushing the real picker
screen and confirming a tap on the first group opens `LettersStage1Screen`
scoped to just 4 letters, not the full 33.

**Verification**: `flutter analyze` clean (1 pre-existing unrelated lint);
`flutter test` 311/311 passing.

**What's left to do**

1. Phase 3 — Cyrillic keyboard: length-scaled key count (a documented,
   unit-tested function, not magic numbers at call sites), narrow-device
   layout fix for the pre-existing touch-target gap, and the
   КОРИЧНЕВЫЙ-style zero-distractor edge case this phase's data surfaced.
2. Phase 4 — Russian audio pipeline (still no bundled audio for level
   content at all; a new build against `ru-RU-SvetlanaNeural`).
3. Manual QA once Phase 3/4 land: a real Russian playthrough of the new
   group picker on a physical device — this phase was verified with
   widget tests only, not a real device run.

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
