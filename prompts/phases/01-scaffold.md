# Phase 01 — Monorepo Scaffold & Tooling

## Goal
Create the complete FlexiKeys monorepo skeleton with working tooling, CI, and local dev environment. No product features yet — but everything that runs must actually run.

## Build

**Repo structure** exactly as specified in `CLAUDE.md` (app/, backend/, shared/, infra/, docs/).

**Backend**
- FastAPI app factory (`flexikeys.main:create_app`) with: settings via pydantic-settings (env-driven, `.env.example` provided), async SQLAlchemy engine + session dependency, Redis client dependency, structured JSON logging (request id, user id when present), CORS, global exception handlers producing RFC 7807 problem+json, `/health` and `/version` endpoints.
- Module skeleton dirs under `src/flexikeys/modules/` (auth, users, children, curriculum, sessions, adaptive, progress, rewards, parent, teacher, admin, ai_assistant, notifications, media) each with empty `router.py`, `service.py`, `repository.py`, `schemas.py`, `models.py` and a module README describing its responsibility.
- Tooling: ruff (strict), mypy (strict), pytest + pytest-asyncio + httpx test client, coverage config. One real test: health endpoint returns 200.
- Alembic initialized (no product tables yet).

**Flutter app**
- `flutter create` with org `com.flexikeys`, then restructure to `core/`, `design_system/`, `features/`, `services/`, `l10n/` per CLAUDE.md.
- Dependencies: flutter_riverpod, go_router, freezed + json_serializable, drift, dio, rive, just_audio, intl/flutter_localizations. Strict analysis_options.
- Boot flow: `main.dart` → ProviderScope → `FkApp` with go_router and a temporary splash screen using placeholder theme constants (real design system in Phase 06).
- l10n scaffolding with en/uz/ru ARB files containing app title only.
- One widget test: app boots to splash.

**Infra**
- `infra/docker-compose.yml`: postgres:16, redis:7, backend (with hot reload), minio (S3-compatible) — healthchecks, named volumes, env wiring.
- Backend Dockerfile (multi-stage, non-root user).
- GitHub Actions CI: backend job (ruff, mypy, pytest with postgres+redis services), app job (flutter analyze, flutter test). Cache dependencies.

**Docs**
- `docs/adr/0001-monorepo.md`, `docs/adr/0002-fastapi-over-django.md` (record reasoning), `docs/architecture.md` with a mermaid system diagram.

## Acceptance Criteria
- [ ] `docker compose up` boots postgres, redis, minio, backend; `GET /health` returns 200 with db+redis connectivity status
- [ ] `pytest`, `ruff check`, `mypy src` all pass clean
- [ ] `flutter analyze` and `flutter test` pass; app boots to splash on an emulator
- [ ] CI workflow file is valid (lint it) and covers both jobs
- [ ] No secrets committed; `.env.example` documents every variable

## Verify
Run every command in the checklist yourself and show the output before declaring the phase done.
