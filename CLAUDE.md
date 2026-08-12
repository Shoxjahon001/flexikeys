# FlexiKeys — Project Memory (CLAUDE.md)

> Place this file at the repository root. Claude Code reads it automatically in every session.

## What FlexiKeys Is

FlexiKeys is an **adaptive EdTech platform** that teaches children (ages 3–10) typing, literacy, and digital interaction. It is designed first for children with cerebral palsy and other motor difficulties, and must work perfectly for neurotypical children too.

**The adaptive learning engine is the product.** The keyboard, lessons, games, and dashboards all exist to serve it. When any design or code decision conflicts with adaptation quality, adaptation wins.

## Non-Negotiable Product Rules

1. **Never stigmatize.** There is no "disability mode", no "special needs" label, no separate app path visible to the child. Adaptation is invisible.
2. **No failures.** The child cannot lose, fail, or see errors framed negatively. Every outcome is progress. No red X marks, no error buzzers, no "wrong!" copy.
3. **Effort-based praise only.** Mascot says "Great effort", "You improved", "Take your time" — never "Perfect!!", "Amazing!!", "You're the best!!". No exclamation-mark spam.
4. **Mastery-based progression.** Levels unlock by demonstrated performance, never by elapsed time or payment.
5. **Never pay-to-win.** Rewards are earned only through play.
6. **Parents never configure adaptation.** The engine tunes itself. Parents only *observe* adaptive changes in reports.
7. **AI assistant gives educational guidance only** and must always disclose it is not a substitute for medical advice.
8. **Child data privacy is sacred.** COPPA/GDPR-K posture: minimal PII on children, no third-party analytics SDKs in the child experience, no ads, all telemetry pseudonymized at ingest.

## Tech Stack

| Layer | Choice | Notes |
|---|---|---|
| Mobile | Flutter (stable channel), Dart 3 | Riverpod for state, go_router, freezed, drift (offline store), rive (mascot), just_audio |
| Backend | FastAPI, Python 3.12 | SQLAlchemy 2 (async), Alembic, Pydantic v2 |
| DB | PostgreSQL 16 | Normalized 3NF; JSONB only for adaptation params & event payloads |
| Cache/queues | Redis 7 | Session cache, rate limits, Celery/Arq task queue |
| Storage | S3-compatible object storage | Audio, images, rive files, exported PDFs |
| Auth | JWT (access+refresh), OAuth2: Google, Apple | Argon2id password hashing |
| AI | Provider-agnostic `ai_service` module | LLM behind an interface; swappable |

## Monorepo Layout

```
flexikeys/
├── CLAUDE.md
├── docs/                    # ADRs, design system spec, API spec
├── app/                     # Flutter application
│   ├── lib/
│   │   ├── core/            # theme, router, di, constants, extensions, error handling
│   │   ├── design_system/   # tokens, atoms, molecules (fk_button, fk_card, mascot, ...)
│   │   ├── features/        # feature-first modules (see below)
│   │   ├── services/        # audio, tts_cache, telemetry, sync, local_store
│   │   └── l10n/            # en, uz, ru ARB files
│   └── test/
├── backend/
│   ├── src/flexikeys/
│   │   ├── core/            # config, security, db, redis, logging
│   │   ├── modules/         # auth, users, children, curriculum, sessions,
│   │   │                    # adaptive, progress, rewards, parent, teacher,
│   │   │                    # admin, ai_assistant, notifications, media
│   │   ├── workers/         # async jobs (metrics rollups, reports, notifications)
│   │   └── main.py
│   ├── alembic/
│   └── tests/
├── shared/                  # OpenAPI spec, curriculum content JSON, seed data
└── infra/                   # docker-compose, Dockerfiles, CI, terraform stubs
```

Each backend module = `router.py`, `service.py`, `repository.py`, `schemas.py`, `models.py`. Routers never touch the DB directly; services never import other modules' repositories (use services).

Each Flutter feature = `presentation/` (screens, widgets, controllers), `application/` (providers, state), `domain/` (entities), `data/` (repos, DTOs).

## The Adaptive Engine (heart of the product)

**Signals collected per interaction:** target key, actual key, keystroke latency, time-to-first-touch (hesitation), touch coordinates & offset from key center, accidental-tap flags, retries, session duration, within-session performance slope (fatigue proxy).

**Derived metrics (per child, per skill/key):** EWMA accuracy, latency percentiles, error confusion pairs (b↔d etc.), mastery score via Bayesian Knowledge Tracing (per-skill P(known)), fatigue index.

**Adaptation outputs (the `AdaptationProfile`):**
- `key_scale` — global + per-key size multipliers (struggling key grows)
- `key_spacing` — spacing multiplier
- `dwell_time_ms` — press-and-hold threshold to reject accidental taps
- `debounce_ms` — repeated-tap rejection window
- `hint_level` — 0 none → 3 full guidance (highlight, ghost hand, audio prompt)
- `repetition_queue` — spaced-repetition schedule of weak items
- `progression_gate` — new items introduced only when mastery ≥ threshold
- `session_pacing` — break suggestions when fatigue index rises

**Rules:** engine runs server-side; profile syncs to device; client has a deterministic fallback policy for offline. Every profile change is written to `adaptation_changes` (audit log) so the parent dashboard can explain *what changed and why* in plain language. Adaptation must move gradually (bounded step sizes) so children never notice a jump.

## Design System (FK)

**2026 visual refresh** — punchy, saturated brand colors over soft pastel surfaces: Indigo `#6C63E0` (primary), Sky Blue `#4A90D9` (secondary), Coral `#E0567B` (accent), Leaf `#4CAF50` (success), Sunshine `#FFC107` (attention — never red), plus Grape `#9C27B0` and Tangerine `#FF8C42` as playful extras for color pickers/confetti/badges. Background: Lavender Mist `#E8ECFA`. Surface: white. Text ink: `#2A2F45` primary / `#6B7186` secondary. **Never**: neon, dark backgrounds, aggressive red, heavy gradients.
- Radius: 16–32px everywhere (10px floor for small chips/icon buttons). No sharp corners.
- Child touch targets ≥ 64×64dp (adaptive keyboard can grow to 96+). Parent/teacher UI ≥ 44dp.
- Motion: soft ease-in-out, 200–400ms, mascot idle float loop; honor reduced-motion setting.
- Typography: rounded humanist sans (e.g., Nunito); large sizes in child UI; no walls of text for children.
- Sound: every letter/word/object has pronunciation audio; animals play their sound first, then the word ("Moooo" → "Cow"). One calm professional child-friendly voice per language.

**Implementation note:** The design-token system lives in `lib/design_system/tokens/` (`AppColors`, `AppTypography`, `AppSpacing`, `AppRadius`, `AppShadows`, `AppMotion` — flat static-const classes, no `.of(context)` needed) and is assembled into `ThemeData` by `FlexiKeysTheme.light()` / `.dark()` (`lib/design_system/theme/app_theme.dart`), which also registers the `FkPlayTheme` and `AacTheme` `ThemeExtension`s. `FkTheme` has been retired — the 3 auth screens, `fk_keyboard.dart`, and the shared atoms in `lib/design_system/atoms/` all read from the token classes now, not a `ThemeExtension`. The one documented exemption from the token system: `lib/design_system/components/keyboard/fk_keyboard_metrics.dart` holds the adaptive keyboard's sizing/layout math (key size, spacing, dwell geometry) outside the 4pt spacing scale, since those are ergonomic constraints (finger size, device DPI, adaptive-profile bounds) rather than design tokens — it consumes `AppColors`/`AppTypography` for skin only. Two systems remain outside this migration, each a distinct future phase: the legacy `AppTheme` (`lib/theme/app_theme.dart`) still drives the entire child gameplay stack (onboarding, levels, games, shop, profile); `FkPlayTheme` (built from the palette above) still drives the levels dashboard, game screens, and drawing/coloring screens, and `lib/design_system/fk_tokens.dart`'s legacy `FkColors` aliases still back the remaining teacher/parent/rewards/lesson/drawing screens and the AAC module. Do not introduce a third ad hoc palette — new work either consumes the token classes above, or, inside an already-`FkPlayTheme`-driven surface, `FkPlayTheme.of(context)`.

## Mascot

A floating cloud. Expressions: happy, thinking, sleeping, celebrating, encouraging, surprised, waving. Implemented as a Rive state machine (`mascot.riv`) with a `MascotController` API: `setExpression()`, `say(messageKey)`. All mascot copy comes from a curated localized string catalog — never generated free-form at runtime in the child UI.

## Localization

Learning languages: **English, Uzbek (Latin), Russian**. Parents choose the learning language per child; UI language and learning language are independent settings. Everything switches: voice, text, curriculum items, progress tracking (progress is tracked **per language**). Curriculum content lives in `shared/curriculum/` as versioned JSON with localized fields — never hardcode words in widgets.

**Exception — the AAC "My Voice" module follows the UI language, not the learning language.** This reverses an earlier decision (AAC used to track the learning language like curriculum content does). Rationale: AAC is a communication tool, not curriculum — its spoken output has to be in the language of the person the child is talking *to*, and that's the language the parent set as the interface language, not necessarily whichever language the child happens to be practicing that day. Curriculum/letters/shapes/numbers are unaffected and still track the learning language exactly as described above. In code: AAC screens derive their active language reactively from `Localizations.localeOf(context)` (see `lib/features/aac/presentation/aac_language.dart`'s `aacLanguageOf()`), not from `UserService.getLanguage()` — this makes an already-open AAC screen switch language live if the parent changes the UI language mid-session, including re-rendering an in-progress Sentence Strip composition and canceling any in-flight audio playback (`AacAudioPlayer`'s `_playId` generation guard). AAC's bundled per-card audio is generated offline (`tools/generate_aac_audio.py`, Azure Speech neural voices) rather than at runtime; ad-hoc Sentence Strip compositions (text not known ahead of time) go through the backend's `POST /aac/tts` neural-TTS endpoint instead, falling back to on-device TTS if that's unreachable.

## Curriculum (16 levels)

1 Letters · 2 Numbers · 3 Shapes · 4 Colors · 5 Family · 6 Animals · 7 Fruits · 8 Vegetables · 9 Toys · 10 Transport · 11 Body Parts · 12 Clothes · 13 Nature · 14 Simple Words · 15 Sentences · 16 Stories. Each level: images, voice, animations, typing exercises, rewards, feedback. Plus a **Drawing module** (tracing letters/numbers/shapes/animals, coloring, connect-dots, mazes, finger painting) targeting fine-motor skills.

## Engineering Standards

- **Backend:** ruff + mypy strict; pytest with ≥80% coverage on `modules/adaptive` and `modules/auth`; async everywhere; all endpoints typed with Pydantic response models; RFC 7807 problem+json errors; structured JSON logging; idempotent event ingest.
- **Flutter:** `flutter analyze` clean with strict lints; widget tests for design-system atoms; golden tests for key screens; no logic in widgets — controllers/providers only; repositories return `Result<T, Failure>`, never throw across layers.
- **Both:** conventional commits; small PR-sized changes; every module gets a brief README; ADR in `docs/adr/` for any architectural decision.
- **Never** put secrets in code; use env config. **Never** add placeholder/mock logic where real implementation is possible — if something must be stubbed (e.g., TTS provider key), isolate it behind an interface and mark `// STUB:` with an issue reference.

## Commands

```bash
# backend
cd backend && uvicorn flexikeys.main:app --reload
pytest -q            # tests
ruff check . && mypy src   # lint + types
alembic upgrade head # migrations
# app
cd app && flutter run
flutter test && flutter analyze
# full stack
docker compose -f infra/docker-compose.yml up
```

## When Working in This Repo

- Read `docs/adr/` before changing architecture.
- Adaptive engine changes require unit tests demonstrating the metric → adaptation mapping.
- Any child-facing copy must exist in all three languages before merge.
- Verify each phase against its acceptance criteria in `prompts/phases/` before declaring done.
