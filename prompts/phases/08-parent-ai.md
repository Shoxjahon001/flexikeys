# Phase 08 — Parent Dashboard & AI Assistant

## Prerequisites
Phases 01–07.

## 1. Reporting Backend (`modules/parent`, `modules/progress`, workers)
- Nightly worker rolls up `daily_activity`; weekly worker builds `reports` (parent_weekly) with: time spent, items completed, letters/words mastered (per language), accuracy trend, typing speed trend, streak, areas needing practice (lowest-mastery skills with friendly labels), and the week's `adaptation_changes` rendered as localized plain-language sentences.
- API: `GET /parent/children/{id}/summary` (today + streak), `/reports?period=`, `/progress/skills`, `/progress/timeseries?metric=accuracy|speed|time&range=`, `/adaptations` (paginated feed of explained changes).
- All aggregates computed in SQL/worker — never ship raw events to the client.

## 2. Parent Dashboard UI (`features/parent/`)
Adult variant of the design system (denser, still pastel/rounded):
- **Home:** child switcher, today card (minutes, items, mood of practice), streak, "what the system adjusted this week" feed — this feed is the product's trust surface, make it excellent.
- **Progress:** fl_chart line/bar charts (accuracy, speed, time), mastery grid of letters (per learning language, each cell soft-colored by p_known — mint = mastered, yellow = practicing, lavender = not started; never red), words mastered list, drawing/fine-motor trendline.
- **Reports:** daily & weekly views, shareable PDF (server-generated, Phase 09 export service).
- **Settings:** learning language per child, UI language, session length preference (soft cap), notifications, consent & data controls (export/delete my child's data — actually implement both).

## 3. AI Assistant (`modules/ai_assistant` + `features/parent/assistant/`)
- **Provider-agnostic interface** `LlmProvider` (complete with streaming) — Anthropic adapter implemented, provider/model/keys from env; no key → clear disabled state in UI (not a crash), `# STUB:` only at the key level.
- **Grounded, tool-using design:** the assistant answers ONLY from structured context the backend assembles — child's summary, mastery snapshot, recent reports, adaptation feed (pseudonymized: display_name only, no PII). Implement as server-side tool-calling: `get_progress_summary`, `get_weekly_report`, `get_adaptation_history`, `get_suggested_activities` (curated, curriculum-linked home activities + fine-motor game library authored in all 3 languages).
- **System prompt requirements** (write it carefully, store in versioned file): warm, concise, parent-facing; explains progress in plain language; suggests home activities and typing/fine-motor practice; ALWAYS clarifies it provides educational guidance and is not a substitute for medical advice when conversations approach therapy/diagnosis topics; refuses to compare the child to other children; answers in the parent's UI language.
- Chat UI: streaming bubbles, suggested starter questions ("How did this week go?", "What should we practice at home?"), weekly-report "Explain this" deep link. Rate-limited per account; conversation history in `ai_conversations`.
- Safety tests: prompt-injection attempt via child display_name is neutralized; medical-advice question triggers the disclaimer; assistant never fabricates metrics absent from context (test with empty-data child).

## Acceptance Criteria
- [ ] Workers produce correct rollups from simulator-generated data (Phase 04 harness reused as fixture generator)
- [ ] Dashboard renders full flow on emulator with seeded data; charts correct against fixture math
- [ ] Adaptation feed shows human sentences in all 3 UI languages
- [ ] Data export returns complete child archive (JSON); delete cascades correctly (verified in DB)
- [ ] AI assistant e2e with mocked LLM: tool calls fire, grounding enforced, disclaimer behavior tested
- [ ] No child PII in prompts sent to the LLM provider (assert in tests)
