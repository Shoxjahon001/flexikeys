# "My Voice" — AAC Module Phase 1: Data Model & Architecture

> Status: **DRAFT — awaiting approval before Phase 2.**
> Companion to `docs/aac_design_system.md` (Phase 0). Covers what Phase 1
> actually asked for: models, repository layer, migration plan, folder
> structure.

## Decisions confirmed this phase

- **drift approved and added** (`pubspec.yaml`: `drift`, `sqlite3_flutter_libs`,
  `path`; dev: `drift_dev`, `build_runner`). Chosen over reusing the
  `TelemetryService` SharedPreferences-queue pattern because that pattern
  already documents itself as a stub for exactly this failure mode (see
  `lib/services/telemetry/telemetry_service.dart:15-17`) — full-blob rewrite
  per event and unbounded growth on prolonged offline, both worse at AAC's
  per-tap volume than at TelemetryService's per-session volume.
- **AAC vocabulary is a bundled Flutter asset (`shared/aac/*.json` +
  `pubspec.yaml` `assets:`), not backend-fetched** — a deliberate departure
  from how curriculum content works (`shared/curriculum/*.json` ->
  `import_curriculum.py` -> Postgres -> `GET /curriculum/next` -> Flutter
  over HTTP, confirmed zero local-asset-loading precedent anywhere in this
  app). AAC vocabulary is the child's only voice; the original spec's hard
  rule — "Everything works offline; sync is a bonus, never a requirement" —
  applies to it more strictly than to prefetchable lesson content.

## Folder structure

```
lib/
├── services/local_db/
│   ├── app_database.dart       # drift @DriftDatabase — AacEvents table
│   └── app_database.g.dart     # generated (dart run build_runner build)
├── design_system/aac/
│   └── aac_theme.dart          # Phase 0 — AacTheme, AacCategory, AacSizes
└── features/aac/
    ├── domain/
    │   ├── aac_card_def.dart       # AacCardDef, AacCardKind, AacFringeOption, AacLanguage
    │   └── aac_progression.dart    # AacLevel, AacProgressionState
    ├── data/
    │   ├── aac_card_repository.dart     # bundled vocabulary + custom cards
    │   ├── aac_event_repository.dart    # drift-backed tap log + sync
    │   └── aac_custom_card_store.dart   # SharedPreferences, parent-created cards
    └── presentation/               # Phase 2 — not built yet
        └── (empty)

shared/aac/
├── category_daily_activities.json   # 7 cards
├── category_needs.json              # 7 cards (incl. "Food" branch card)
├── category_feelings.json           # 6 cards (incl. "Pain" branch card)
├── category_people.json             # 5 cards
├── category_places.json             # 6 cards
└── category_play.json               # 6 cards
                                      # = 37 cards total

test/design_system/aac_theme_test.dart   # Phase 0
test/features/aac/                       # Phase 1 (this phase)
```

**State-management split** (confirmed via codebase inspection, not assumed):
child-facing AAC gameplay screens (Phase 2) will follow the plain
`StatefulWidget` + service-singleton pattern used by `lib/screens/game/*`
(zero Riverpod there today); the parent-facing AAC settings/dashboard
(Phase 4) will follow the `ConsumerWidget`/`StateNotifierProvider` pattern
used by `lib/features/parent/*`. The repository layer built this phase
(`AacCardRepository.instance`, `AacEventRepository.instance`,
`AacCustomCardStore.instance`) is plain-Dart singletons either style can
consume — same seam `ProgressRepository.instance`/`TtsService.instance`
already use across both styles today.

## Card model

`AacCardDef` (full fields/behavior in `aac_card_def.dart`): `id`, `category`
(`AacCategory`, from Phase 0's theme file — one enum, not duplicated),
`kind` (`direct` | `branch`), localized `label`/`sentenceTemplate` (uz/ru/en
maps), `animationAsset`, localized `audioAsset`, optional
`customPhotoPath`, `difficultyTier` (1-4), `isCustom`, and — for branch
cards — `fringeOptions: List<AacFringeOption>`.

**Two-step (core+fringe) flow**: a `branch` card's `sentenceTemplate`
carries a `{noun}` placeholder (e.g. `"I want {noun}."`); each
`AacFringeOption` supplies a `fillValue` substituted in on selection.
`AacCardDef.sentenceFor(lang, chosenFringe: option)` produces the final
sentence. Implemented for both spec examples — "Food" (Needs) branches to
Apple/Banana/Bread/Rice, "Pain" (Feelings) branches to Head/Stomach/
Tooth/Leg.

**Uz/ru grammar note** (flagging honestly, not glossing over it): naive
`{noun}` substitution reads correctly in English for every combination in
the starter set. For Uzbek, bare word-stem substitution would sometimes
produce ungrammatical possessive suffixation (e.g. "qorin" + "im" ≠
"qornim" — a real vowel-elision rule), so fringe `fillValue`s for the
"Pain" card are pre-written as the fully-inflected correct forms
("boshim", "qornim", "tishim", "oyog'im") rather than computed by
string concatenation. This works for the current 4 body-part options; any
future branch card added to the vocabulary should follow the same
pre-inflect-don't-concatenate rule for uz specifically. Russian's
"У меня болит {noun}" and "Я хочу {noun}" constructions both happen to take
nominative/nominative-shaped accusative for every noun used, so no
equivalent issue there in the current set — but that's a property of these
specific sentences, not a guarantee for future ones.

## Starter vocabulary content

37 cards across the 6 spec'd categories, split into 4 difficulty tiers so
`AacLevel.cardCeiling` (6 / 12 / 24 / all) lines up exactly:

| Tier | Count | Cumulative | Cards |
|---|---|---|---|
| 1 | 6 | 6 | eat, toilet, pain*, water, help, mom |
| 2 | 6 | 12 | drink, happy, sad, food*, hug, dad |
| 3 | 12 | 24 | brush_teeth, wash_hands, bath, sleep, angry, scared, tired, blanket, medicine, break, bathroom, outside |
| 4 | 13 | 37 | kitchen, bedroom, school, hospital, teacher, grandma, doctor, ball, drawing, music, tablet, book, toy |

(*branch cards)

**This tier assignment is a reasonable starting point, not a clinically
validated one.** I sequenced it toward urgent physical/safety needs first
(water, help, toilet, pain) per general AAC core-vocabulary practice
referenced in `docs/FLEXIKEYS_DOMAIN_KNOWLEDGE.md`, but I'm not a speech-
language pathologist — a real AAC/SLP consultant reviewing this ordering
before it reaches an actual child is genuinely worth doing, not a formality.
Same honesty applies to the uz/ru translations themselves: linguistically
reasonable, not native-speaker-reviewed.

**Asset paths are a defined convention, not produced assets.** Every card's
`animation_asset`/`audio_asset` fields point to files that don't exist on
disk yet (`assets/aac/animations/*.json`, `assets/aac/audio/{lang}/*.mp3`)
— that's real production work (recording/generating 3 languages × ~40
audio clips, plus ~40 animations), out of scope for a data-model phase and
gated on the Lottie-vs-custom-drawn decision below.

## Progression system

`AacLevel` enum (`level1`..`level4`) with `cardCeiling` (6/12/24/null).
`level4.cardCeiling == null` — deliberately uncapped. The original spec says
"Level 4 = sentence building," which I read as: level 4 is a *mode* change
(unlocks the Sentence Strip screen), not a fourth vocabulary tier — capping
it at 24 would leave 13 authored cards permanently unreachable, which can't
be the intent. Flagging this reading explicitly since the spec doesn't say
it in so many words.

`AacProgressionState` — `level`, `manuallySet`, `updatedAt`. See the doc
comment in `aac_progression.dart` for how this interacts with CLAUDE.md's
"parents never configure adaptation" rule (short version: that rule is
about the learning-adaptation engine; AAC vocabulary pacing is a
communication/curriculum decision the parent drives directly, by original
spec design — confirm this reading is what you intended).

## Migration plan

**Drift schema versioning**: `AppDatabase.schemaVersion = 1` today (single
table, `AacEvents`). Any future column/table change bumps this and adds a
`MigrationStrategy.onUpgrade` step — standard drift practice, no custom
tooling needed. Generated code (`app_database.g.dart`) is committed to the
repo (no existing `.g.dart`/`.freezed.dart` precedent either way in this
codebase to follow, so defaulting to "commit generated code" for
zero-setup-friction — anyone cloning the repo can `flutter run` without
first knowing to run `build_runner`); regenerate via
`dart run build_runner build --delete-conflicting-outputs` whenever a table
changes.

**No data migration needed yet** — this is a new table, nothing to migrate
*from*. (Separately, and not part of this phase: `TelemetryService`'s own
stub comment anticipates migrating *it* onto a drift table too, now that
the plumbing exists. That's a real, valuable follow-up — but it's an
existing-system migration with its own data-continuity concerns, not
something to fold silently into "Phase 1 of a new AAC module." Flagging it
as a discrete task to pick up separately if you want it.)

## Backend sync contract (design only — not implemented)

Client → `POST /aac/events`, child-session auth (matching
`TelemetryService`'s `/sessions/:id/events` pattern):

```json
{
  "child_id": "uuid",
  "batch_id": "uuid",
  "events": [
    {
      "card_id": "ne_water",
      "category": "needs",
      "sentence_spoken": "I want water.",
      "language": "en",
      "tapped_at": "2026-07-24T10:15:00.000Z"
    }
  ]
}
```

This endpoint doesn't exist on the backend yet — Phase 1 only defines the
shape the client already codes against (`AacEventRepository.flush()`).
Implementing the actual FastAPI route is a separate, small follow-up
(mirrors the existing `sessions/events` router closely) — happy to do it
now as an explicit add-on if you'd rather not wait for Phase 3/4, otherwise
it naturally lands whenever Phase 3's backend AI-layer work starts touching
the backend anyway.

## Open questions carried over from Phase 0

1. **Lottie vs. custom-drawn card animations** — still open, now the actual
   blocker for Phase 2 (every card needs its animation asset resolved to
   build the real screens). I'll bring a concrete comparison when we get
   there.
2. **Custom-card TTS fallback** (Phase 4: parent types text instead of
   recording their voice) — the app's existing `TtsService` scrapes Google
   Translate's public endpoint and is hardcoded to English regardless of
   app language (a real existing limitation, `tts_service.dart`). Fixing
   that endpoint's locale param avoids a new dependency; adding
   `flutter_tts` for proper platform TTS is more robust but is another new
   dependency to ask about. Not blocking now — flagging so it's not a
   surprise at Phase 4.
