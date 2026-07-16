# Phase 10 — Hardening, Testing, Performance & Release Readiness

## Prerequisites
Phases 01–09. Nothing new gets built here — everything gets proven.

## 1. Test Completion
- Backend: coverage report — enforce ≥ 80% overall, ≥ 90% on `modules/adaptive` and `modules/auth`. Add missing integration tests: full child journey (register parent → create child → sessions with simulator events → adaptation fires → progress → weekly report → PDF).
- Flutter: `integration_test/` suites — child journey (profile pick → lesson → reward), parent journey (dashboard → report → AI chat with mock), teacher journey. Golden test suite run at 3 screen sizes (phone small, phone large, tablet).
- Contract tests: generated OpenAPI spec (`shared/openapi.json`) validated against the Dart client models in CI — schema drift fails the build.
- Adaptive engine: re-run all simulator scenarios (Phase 04) against the *final* integrated stack, not just the module.

## 2. Performance
- Backend: load-test event ingest (locust or k6 script in `infra/load/`) — target 200 concurrent children, p95 ingest < 150ms, no event loss (verify counts). Profile and fix N+1 queries (add sqlalchemy echo audit); verify all list endpoints paginate.
- App: frame profiling on lesson player + keyboard resize + world map scroll — no jank > 16ms frames in profile mode on a mid-tier device profile; app cold start < 2.5s; asset cache bounded (LRU with size cap); memory audit on 20-minute session.

## 3. Security & Privacy Audit
Work through and document in `docs/security-review.md`:
- OWASP ASVS L2 pass on auth, session, access control, input validation
- Dependency audit (`pip-audit`, `dart pub outdated` review); pin all versions
- All endpoints re-checked for role guards (write an authz matrix test that iterates every route × every role and asserts expected status)
- PII inventory doc: what child data exists, where, retention, export/delete verified end-to-end
- Signed URL expiry, rate limits, request size limits, security headers verified
- Secrets: env-only, compose files clean, CI secrets documented

## 4. Accessibility Audit
- Child UI: touch-target sweep (every interactive element ≥ 64dp; automated test walking the widget tree), contrast check of pastel palette against ink text (adjust ink shades if any pair < 4.5:1 for text), screen-reader labels on parent/teacher surfaces (child surfaces: audio-first by design), reducedMotion honored everywhere (test), no time-pressure mechanic anywhere (design review).
- Dwell/debounce verified with simulated tremor input patterns.

## 5. Operations & Release
- `infra/`: production docker-compose + Dockerfile hardening (read-only fs, healthchecks), DB backup/restore script + tested restore, log aggregation-ready JSON logs, Sentry hooks behind env flag (backend + Flutter), versioned config documented.
- CI/CD: release workflow — tag → backend image build+push, Flutter build (appbundle + ipa config), changelog generation. Store metadata checklist (privacy nutrition labels, COPPA declarations) drafted in `docs/release/`.
- Observability: `/metrics` (Prometheus) — request latencies, ingest queue depth, worker lag, adaptation-change rate.
- Final docs pass: `README.md` (root, with 5-minute local setup), `docs/architecture.md` updated to as-built, ADR index, API reference generated from OpenAPI.

## Acceptance Criteria (release gate)
- [ ] All test suites green in CI; coverage thresholds enforced in CI config
- [ ] Load test report committed; targets met
- [ ] Authz matrix test covers 100% of routes
- [ ] Security review + PII inventory + accessibility audit documented with all findings resolved or ticketed
- [ ] Fresh-clone test: new machine → README steps → full stack running + app connected in ≤ 5 commands
- [ ] Demo script (`docs/demo.md`): seeded walkthrough showing the adaptive engine visibly responding to a struggling-child simulation — the product's core proof
