# FlexiKeys

An adaptive EdTech platform that teaches children typing, literacy, and digital interaction — designed first for children with motor difficulties and equally great for all children.

**The adaptive learning engine is the product.** It adjusts keyboard layout, key sizes, hints, and lesson pacing in real time based on each child's performance — invisibly, without stigma.

---

## Fresh-Clone Setup (5 commands)

```bash
# 1. Clone and enter repo
git clone https://github.com/your-org/flexikeys && cd flexikeys

# 2. Start backend services (PostgreSQL · Redis · MinIO · API)
docker compose -f infra/docker-compose.yml up --build -d

# 3. Run database migrations
docker compose -f infra/docker-compose.yml exec backend \
  python -m alembic upgrade head

# 4. Verify the stack is healthy
curl http://localhost:8000/health

# 5. Run the Flutter app
flutter run
```

The stack is running when `/health` returns `{"status": "ok"}`.

> **Note:** Step 5 requires a connected device or emulator. Run `flutter devices` first to confirm one is available. The Flutter app connects to `http://localhost:8000` by default.

---

## What's Running After Setup

| Service | URL | Notes |
|---------|-----|-------|
| Backend API | http://localhost:8000 | FastAPI |
| API Docs (dev) | http://localhost:8000/docs | Swagger UI |
| Prometheus metrics | http://localhost:8000/metrics | Raw metrics |
| MinIO console | http://localhost:9001 | Object storage UI |
| PostgreSQL | localhost:5432 | DB: `flexikeys` |
| Redis | localhost:6379 | Cache + queues |

---

## Project Structure

```
flexikeys/
├── backend/          FastAPI backend (Python 3.12)
├── lib/              Flutter app (Dart 3)
├── shared/           Curriculum JSON, OpenAPI spec, seed data
├── infra/            Docker Compose, Dockerfiles, load tests, backup scripts
└── docs/             Architecture, ADRs, security review, demo walkthrough
```

See [docs/architecture.md](docs/architecture.md) for the full system diagram.

---

## Development

### Backend

```bash
cd backend
pip install -e ".[dev]"                       # install dependencies + dev tools
alembic upgrade head                          # run migrations (requires running DB)
uvicorn flexikeys.main:app --reload           # hot-reload dev server
pytest                                        # run all tests
ruff check src tests                          # lint
mypy src                                      # type check
```

### Flutter

```bash
flutter pub get               # install dependencies
flutter analyze               # static analysis
flutter test                  # widget tests
flutter run                   # run on connected device/emulator
```

### Full Stack (Docker)

```bash
docker compose -f infra/docker-compose.yml up --build   # start everything
docker compose -f infra/docker-compose.yml down         # stop
```

---

## Testing

```bash
# Backend — all suites (unit + integration, requires running DB)
cd backend && pytest

# Backend — unit tests only (no DB required)
cd backend && pytest tests/test_teacher.py tests/test_admin.py \
  tests/test_notifications.py tests/test_pdf.py tests/test_workers.py \
  tests/test_ai_assistant.py tests/test_parent.py tests/test_rewards.py \
  tests/adaptive/ tests/test_authz_matrix.py::test_every_protected_route_has_auth_guard

# Flutter
flutter test
```

Coverage thresholds are enforced in CI:
- Adaptive module: ≥ 80%
- Auth module: ≥ 80%

---

## Load Testing

```bash
pip install locust
locust -f infra/load/locust_ingest.py \
       --host http://localhost:8000 \
       --users 200 --spawn-rate 20 \
       --run-time 2m --headless \
       --html infra/load/report.html
```

Target: 200 concurrent users, p95 < 150 ms on the event ingest endpoint.

---

## Backup & Restore

```bash
# Backup PostgreSQL to S3/MinIO
POSTGRES_URL=postgresql://flexikeys:flexikeys@localhost:5432/flexikeys \
BACKUP_BUCKET=s3://my-bucket/flexikeys-backups \
AWS_ENDPOINT_URL=http://localhost:9000 \
  ./infra/scripts/backup.sh

# Restore latest backup
./infra/scripts/backup.sh restore
```

---

## Key Docs

- [docs/demo.md](docs/demo.md) — Adaptive engine walkthrough with struggling-child simulation
- [docs/architecture.md](docs/architecture.md) — System design and data flow
- [docs/security-review.md](docs/security-review.md) — OWASP ASVS L2 audit
- [docs/pii-inventory.md](docs/pii-inventory.md) — COPPA/GDPR-K data inventory
- [docs/accessibility-audit.md](docs/accessibility-audit.md) — WCAG 2.1 AA audit
- [docs/release/CHECKLIST.md](docs/release/CHECKLIST.md) — Pre-release checklist
- [CLAUDE.md](CLAUDE.md) — Project conventions for AI-assisted development

---

## Curriculum

16 levels: Letters · Numbers · Shapes · Colors · Family · Animals · Fruits · Vegetables · Toys · Transport · Body Parts · Clothes · Nature · Simple Words · Sentences · Stories

Plus a Drawing module: letter tracing, coloring, connect-the-dots, mazes, finger painting.

Available in: **English**, **Uzbek (Latin)**, **Russian**.

---

## License

Proprietary. See LICENSE file.