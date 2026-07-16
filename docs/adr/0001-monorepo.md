# ADR-0001 — Monorepo Layout

**Status:** Accepted  
**Date:** 2026-07-10  
**Deciders:** Engineering team

## Context

FlexiKeys has a Flutter mobile client, a FastAPI backend, shared curriculum content, and infra config. We need a repo strategy that lets one developer (or small team) move across layers without friction while keeping CI scopes narrow.

## Decision

Single Git monorepo with top-level directories by concern:

```
flexikeys/
├── app/        Flutter application
├── backend/    FastAPI + Alembic
├── shared/     OpenAPI spec, curriculum JSON, seed data
├── infra/      docker-compose, Dockerfiles, CI, terraform stubs
└── docs/       ADRs, architecture, API docs, design system
```

CI is split into independent jobs (backend, flutter) that only run when their subtree changes, keeping feedback fast.

## Consequences

**Good:** Single source of truth; easy cross-layer refactors; shared types expressed once in `shared/openapi/`; seed data and curriculum content versioned alongside code.

**Bad:** Git clone is larger; contributors must be careful not to run backend tooling from the Flutter root or vice versa. Mitigated by per-directory `Makefile` targets and clear README instructions.