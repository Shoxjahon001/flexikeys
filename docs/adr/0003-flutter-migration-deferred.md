# ADR-0003 — Flutter App Migration Deferred to Phase 06

**Status:** Accepted  
**Date:** 2026-07-10  
**Deciders:** Engineering team

## Context

CLAUDE.md specifies the Flutter app lives at `app/` with a clean feature-first architecture (Riverpod, go_router, drift, clean layers). At the time Phase 01 was started, a working Flutter prototype already existed at the repository root using `setState`, named routes, and no drift. That prototype contains validated UX flows for letters, shapes, and drawing.

## Decision

- Phase 01: create `backend/`, `shared/`, `infra/`, `docs/` — do **not** move or restructure the existing Flutter code.
- The existing Flutter app stays at repo root and remains the actively-developed product surface until Phase 06.
- Phase 06 ("Flutter Foundation") will create `app/` with the full clean-architecture skeleton, migrate the design system, and port validated screens from the prototype one feature at a time.
- An ADR will be filed in Phase 06 documenting each migration decision.

## Consequences

**Good:** The current working app is never broken; UX validation continues in parallel with backend build-out; no wasted migration effort on prototype code that will be replaced during design-system work.

**Bad:** Two Flutter "layouts" exist briefly (root prototype, `app/` target). Mitigated by a clear deprecation note in the root `README.md` and by completing the migration fully before Phase 07.