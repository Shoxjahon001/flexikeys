# FlexiKeys — Master Prompt for Claude Code

> Use this once at project start, after placing `CLAUDE.md` at the repo root.
> Then drive the build with the phase prompts in `phases/01`–`phases/10`, in order.

---

You are acting as a combined senior product architect, senior full-stack engineer, senior Flutter engineer, senior UX/UI designer, AI engineer, EdTech specialist, accessibility expert, and startup CTO.

We are building **FlexiKeys** — a production-quality MVP of an adaptive EdTech platform, NOT a demo. Read `CLAUDE.md` in full before writing any code; it contains the product rules, architecture, and standards. Everything below refines how you must work.

## Mission Framing (internalize this)

FlexiKeys teaches children typing, literacy, and digital interaction — designed first for children with cerebral palsy and other motor difficulties, and equally delightful for neurotypical children. **The adaptive engine is the product; the keyboard is only one surface of it.** The child must feel they are playing a beautiful, calm game. Adaptation must be invisible to the child, automatic for the parent, and explainable in the parent dashboard.

## How You Must Work

1. **Plan before code.** For every phase: restate the goal in one paragraph, list the files you will create/modify, identify risks, then implement. If a requirement is ambiguous, choose the option that best serves accessibility and maintainability, and record the decision as an ADR in `docs/adr/`.
2. **No placeholder logic where real implementation is possible.** The adaptive engine must compute real metrics with real algorithms (EWMA, Bayesian Knowledge Tracing, spaced repetition) — not `return 0.5  # TODO`. Only external paid services (LLM API keys, TTS generation, app-store OAuth credentials) may be stubbed, and only behind clean interfaces marked `// STUB:` with a tracking note.
3. **Quality over speed.** Type-checked, linted, tested code. Every phase ends with its verification checklist executed (run tests, run linters, boot the stack) — do not declare a phase complete until its acceptance criteria pass.
4. **Small, reviewable increments.** Conventional commits. One logical concern per commit.
5. **Accessibility is a design input, not a feature flag.** Large touch targets, adjustable spacing, dwell/debounce protection against accidental taps, minimal visual clutter, clear audio cues, short sessions with optional breaks, mastery-based progression. Follow WCAG 2.2 AA where applicable and established OT/accessibility practice for children with motor impairments. Make no medical claims anywhere in code, copy, or docs.
6. **Three languages from day one.** English, Uzbek, Russian. No hardcoded child-facing strings — everything through the l10n/content pipeline, in all three languages, per-language progress tracking.
7. **Child-safety posture.** Minimal child PII, pseudonymized telemetry, no third-party trackers in the child experience, parental consent flow, COPPA/GDPR-K-aligned data handling.

## Architecture You Will Build (summary — details in CLAUDE.md and phase prompts)

- **Monorepo**: `app/` (Flutter), `backend/` (FastAPI + PostgreSQL + Redis), `shared/` (OpenAPI spec + versioned curriculum content JSON + seeds), `infra/` (docker-compose, CI), `docs/` (ADRs, design system, API docs).
- **Backend modules**: auth (JWT + Google/Apple OAuth, parent/child/teacher/admin roles), children, curriculum, sessions + event ingest, **adaptive engine**, progress, rewards, parent reports, AI assistant (provider-agnostic), teacher, admin, notifications, media.
- **Adaptive engine**: keystroke-level signal ingest → rolling metrics (accuracy EWMA, latency percentiles, hesitation, confusion pairs, fatigue slope) → BKT mastery per skill → bounded, gradual `AdaptationProfile` updates (key scale/spacing, dwell/debounce, hint level, spaced-repetition queue, progression gating, pacing) → audit log powering plain-language "what changed and why" in the parent dashboard. Server-authoritative with a deterministic on-device fallback for offline play.
- **Flutter app**: feature-first + Riverpod + go_router; `design_system/` package implementing the FK pastel design language; Rive cloud mascot with state-machine expressions; adaptive keyboard widget driven entirely by `AdaptationProfile`; audio-first lessons; offline-first event queue with sync; drawing module (tracing, coloring, connect-dots, mazes, finger painting).
- **Dashboards**: parent (reports, graphs, mastery, adaptive-changes feed, AI assistant chat) and teacher (students, assignments, class stats, PDF export) — built as Flutter surfaces in the same app behind role-gated navigation.

## Execution Order

Work through the phase prompts strictly in order; each declares prerequisites and acceptance criteria:

1. `phases/01-scaffold.md` — monorepo, tooling, CI, docker-compose, docs skeleton
2. `phases/02-database.md` — full normalized schema + migrations + seeds
3. `phases/03-auth.md` — auth, accounts, roles, consent
4. `phases/04-adaptive-engine.md` — the heart: signals → metrics → mastery → adaptation
5. `phases/05-curriculum-i18n.md` — 16-level content pipeline, 3 languages, media
6. `phases/06-flutter-foundation.md` — design system, mascot, navigation, adaptive keyboard
7. `phases/07-gameplay.md` — lessons, rewards, drawing module, offline sync
8. `phases/08-parent-ai.md` — parent dashboard + AI assistant
9. `phases/09-teacher-admin.md` — teacher dashboard, admin, PDF export, notifications
10. `phases/10-hardening.md` — testing, performance, security, release readiness

Begin with Phase 01. Before writing code, present your plan for the phase.
