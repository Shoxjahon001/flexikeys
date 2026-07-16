# Phase 02 — Database Schema & Migrations

## Prerequisites
Phase 01 complete (alembic initialized, docker postgres running).

## Goal
Design and migrate the full normalized PostgreSQL schema. This schema must anticipate every later phase — model it completely now so later phases only add columns, not restructure.

## Schema (SQLAlchemy 2 models + Alembic migration + ERD in docs/)

**Identity & accounts**
- `users` — id (uuid), email (citext, unique, nullable for child accounts), password_hash (argon2, nullable for OAuth-only), role enum (parent|teacher|admin), locale, timezone, created_at, deleted_at (soft delete)
- `oauth_identities` — user_id, provider enum (google|apple), provider_subject, unique(provider, provider_subject)
- `children` — id, parent_id FK, display_name, avatar_id, birth_year (year only — minimize PII), learning_language enum (en|uz|ru), ui_language, created_at, deleted_at. **No email/photo/full name for children.**
- `parental_consents` — child_id, consent_type, granted_at, revoked_at
- `refresh_tokens` — user_id, token_hash, device_info, expires_at, revoked_at

**Curriculum (content is versioned and localized)**
- `curriculum_versions` — id, version, published_at, checksum
- `levels` — id, version_id FK, ordinal (1–16), slug (letters, numbers, ... stories), unlock_mastery_threshold numeric
- `lessons` — id, level_id FK, ordinal, slug, lesson_type enum (typing|drawing|listening|story)
- `items` — id, lesson_id FK, ordinal, item_type enum (letter|number|word|sentence|shape|color|trace_path|story_page), skill_key (e.g. `en:letter:b`), payload jsonb (trace paths, sentence tokens)
- `item_localizations` — item_id, language, text, audio_asset_id, image_asset_id, extra_audio_asset_id (animal sound), unique(item_id, language)
- `assets` — id, kind enum (audio|image|rive|font), storage_key, mime, bytes, checksum

**Sessions & telemetry (high-volume, append-only)**
- `learning_sessions` — id, child_id, language, started_at, ended_at, device_info jsonb, client_version
- `interaction_events` — id (bigserial), session_id FK, occurred_at, event_type enum (keystroke|trace_point|item_shown|item_completed|hint_shown|break_taken), item_id nullable, skill_key, payload jsonb (target, actual, latency_ms, time_to_first_touch_ms, touch_offset_x/y, accidental flag), ingest_batch_id for idempotency. Partition by month; index (session_id), (skill_key, occurred_at).

**Adaptive engine state**
- `skill_mastery` — child_id, language, skill_key, p_known numeric (BKT), attempts, correct, ewma_accuracy, ewma_latency_ms, last_seen_at, unique(child_id, language, skill_key)
- `adaptation_profiles` — child_id (unique), params jsonb (key_scale global+per-key, key_spacing, dwell_time_ms, debounce_ms, hint_level, session_pacing), version, updated_at
- `adaptation_changes` — id, child_id, changed_at, param, old_value, new_value, reason_code enum (accuracy_drop|latency_rise|fatigue|mastery_gain|accidental_taps|...), explanation_key (for localized parent-facing text)
- `repetition_queue` — child_id, language, skill_key, due_at, interval_days, ease numeric, lapses (SM-2 style)

**Progress & rewards**
- `level_progress` — child_id, language, level_id, status enum (locked|active|mastered), mastered_at
- `wallets` — child_id, coins, stars
- `reward_definitions` — id, kind enum (badge|world|mascot_emotion|background|accessory), slug, cost_coins nullable, unlock_rule jsonb
- `reward_grants` — child_id, reward_definition_id, granted_at, source enum (earned|purchased_with_coins)
- `daily_activity` — child_id, date, seconds_active, items_completed, avg_accuracy (rollup table filled by worker)

**Teacher & classroom**
- `classes` — id, teacher_id FK, name, join_code unique
- `class_enrollments` — class_id, child_id, enrolled_at, unique pair
- `assignments` — id, class_id, level_id/lesson_id, due_at, instructions
- `assignment_status` — assignment_id, child_id, status, completed_at

**Platform**
- `ai_conversations` / `ai_messages` — parent-scoped assistant history
- `notifications` — user_id, kind, payload jsonb, read_at, sent_at
- `reports` — id, scope enum (parent_daily|parent_weekly|teacher_class), subject_id, period, payload jsonb, pdf_asset_id nullable

## Rules
- All FKs indexed; updated_at triggers; soft delete only where required (users, children).
- Write `repository.py` base class with generic async CRUD used by all modules.
- Seed script (`shared/seeds/`): admin user, demo parent + 2 children (one with adaptation profile showing adjusted params), demo teacher + class, curriculum version 1 with Level 1 (letters) fully populated in all 3 languages (text only; asset keys reference Phase 05 media).

## Acceptance Criteria
- [ ] `alembic upgrade head` from empty DB succeeds; `alembic downgrade base` succeeds
- [ ] ERD (mermaid) in `docs/database.md` matching migrations
- [ ] Seed script idempotent (safe to run twice)
- [ ] mypy/ruff clean; model round-trip tests for every table
- [ ] `interaction_events` insert benchmark: batch of 500 events < 1s locally
