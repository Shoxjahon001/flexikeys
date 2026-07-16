# FlexiKeys Release Checklist

Complete this checklist before tagging a release. Mark each item ✅ when verified.

---

## Pre-Release Verification

### Code Quality
- [ ] All tests green in CI (`main` branch)
- [ ] `flutter analyze --no-fatal-infos` — zero warnings
- [ ] `ruff check src tests` — clean
- [ ] `mypy src` — clean (strict mode)
- [ ] No `STUB:` comments without issue references
- [ ] Coverage thresholds met: ≥80% adaptive, ≥80% auth

### Security
- [ ] `pip-audit` — no HIGH/CRITICAL CVEs in production deps
- [ ] `npm audit` — N/A (no JS in prod)
- [ ] Secrets scan (`git log --all --oneline | head -20` + `gitleaks detect`) — clean
- [ ] All STUB items in SEC-* findings either resolved or documented with risk acceptance
- [ ] JWT secret rotated if deploying to new environment
- [ ] TLS certificates valid (check expiry)

### Privacy & Compliance
- [ ] `docs/pii-inventory.md` reviewed — no new PII fields added without sign-off
- [ ] Parental consent text version bumped if text changed (currently `1.0`)
- [ ] COPPA attestation: no PII collected from children (review all new DB columns)
- [ ] GDPR-K: confirm no new analytics SDKs added to the Flutter app
- [ ] Delete and export stubs (#57, #58) — either implemented or risk-accepted for this version
- [ ] Privacy nutrition label (App Store / Google Play) updated if data practices changed

### Adaptive Engine
- [ ] `tests/adaptive/` all pass with no regressions
- [ ] Bounded step-size policy unchanged (or change reviewed + tested)
- [ ] BKT parameters unchanged or re-validated against simulator
- [ ] `adaptation_changes` audit log writes correctly

### Curriculum Content
- [ ] All 16 level JSON files present in `shared/curriculum/`
- [ ] All items have audio refs in all three languages (en, uz, ru)
- [ ] `test_curriculum_roundtrip.py` green
- [ ] New vocabulary reviewed against age-appropriate guidelines

### Localization
- [ ] All new child-facing strings added to en/uz/ru ARB files
- [ ] Mascot copy catalog updated in all three languages
- [ ] No hardcoded strings in widgets

---

## Infrastructure

### Docker
- [ ] `docker build backend/` succeeds with no warnings
- [ ] Container runs as non-root user (`app`, UID 1001)
- [ ] Health check passes: `docker run ... curl /health`
- [ ] Image size is reasonable (< 500 MB)

### Database
- [ ] `alembic upgrade head` runs clean on a fresh DB
- [ ] `alembic downgrade base && alembic upgrade head` round-trip passes
- [ ] All new columns have `nullable=True` or server defaults (zero-downtime migration)
- [ ] `infra/scripts/backup.sh` tested against staging DB

### Monitoring
- [ ] `GET /metrics` returns Prometheus metrics (200 OK)
- [ ] `GET /health` returns `{"status": "ok"}` with DB + Redis up
- [ ] Prometheus scrape config updated if new metrics added
- [ ] Alert rules reviewed (if Grafana / AlertManager used)

---

## Deployment

### Staging Gate
- [ ] Full stack deployed to staging via `docker compose up`
- [ ] `docs/demo.md` walkthrough executed on staging
- [ ] Adaptive engine visibly responds to struggling-child simulation (see demo.md)
- [ ] Parent dashboard shows adaptation change explanations

### Production Deploy
- [ ] Git tag created: `git tag -s v<X.Y.Z> -m "Release v<X.Y.Z>"`
- [ ] Release workflow triggered in GitHub Actions
- [ ] Docker image pushed to GHCR with correct tags
- [ ] Helm/compose values updated with new image tag
- [ ] `alembic upgrade head` run against production DB (zero-downtime)
- [ ] Post-deploy health check: `curl https://api.flexikeys.app/health`
- [ ] Post-deploy smoke test: register + login + create child + start session

### Rollback Plan
- [ ] Previous Docker image tag noted: ___________________
- [ ] `alembic downgrade -1` command verified on staging (for any new migration)
- [ ] Rollback runbook in `docs/ops/rollback.md` up-to-date

---

## App Store Submission (Mobile)

### iOS (Apple App Store)
- [ ] Privacy nutrition label reviewed and updated
- [ ] COPPA: age rating set to 4+ (child-directed)
- [ ] App Tracking Transparency — N/A (no tracking)
- [ ] TestFlight beta testing completed
- [ ] App Review notes prepared (explain adaptive keyboard)

### Android (Google Play)
- [ ] Data safety form updated
- [ ] Content rating: Everyone / Early Childhood
- [ ] Target API level meets current requirement (API 34+)
- [ ] Tested on low-end device (2 GB RAM, Android 10)

---

## Sign-off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Engineering Lead | | | |
| Product | | | |
| Privacy / Legal | | | |
| QA | | | |