# Running FlexiKeys Backend Locally

## Prerequisites

- Docker Desktop (or compatible) running locally
- Optionally: Python 3.12 + the `backend/.venv` if you want to run scripts on the host

## Start everything

```bash
cd infra
docker compose up -d --build
```

This starts four containers:

| Service    | Container         | Port(s)          |
|------------|--------------------|-------------------|
| `postgres` | `infra-postgres-1` | `5432`            |
| `redis`    | `infra-redis-1`    | `6379`            |
| `minio`    | `infra-minio-1`    | `9000` (API), `9001` (console) |
| `backend`  | `infra-backend-1`  | `8000`            |

The `backend` container runs `alembic upgrade head` automatically on every
start (via `backend/docker-entrypoint.sh`) before launching `uvicorn --reload`,
so migrations are always applied before the API accepts traffic.

Check it's up:

```bash
curl http://localhost:8000/health
# {"status":"ok","checks":{"db":"ok","redis":"ok"}}
```

Interactive API docs: http://localhost:8000/docs

## Env files

- `infra/.env` — used by `docker compose` for all four services (already created for local dev; gitignored). Copy from `infra/.env.example` if you need to recreate it.
- `backend/.env` — used when running Python directly on the host (e.g. `scripts/seed.py`, `pytest`, or `uvicorn` outside Docker). Points at `localhost` instead of the Docker service names. Gitignored; copy from `backend/.env.example` to recreate.

CORS is pre-configured to allow Flutter dev origins: `localhost` (web/desktop), `10.0.2.2` (Android emulator loopback to host), and common dev ports.

## Migrations

Run automatically on container start. To run manually (e.g. after adding a new migration):

```bash
docker compose exec backend python -m alembic upgrade head
docker compose exec backend python -m alembic downgrade -1   # roll back one step
```

To generate a new migration from model changes:

```bash
docker compose exec backend python -m alembic revision --autogenerate -m "description"
```

## Reset the database

```bash
cd infra
docker compose down -v   # drops all volumes: postgres, redis, minio data
docker compose up -d --build
```

## Seed dev data

The seed script is idempotent (safe to re-run) and creates:
- 1 admin, 1 parent, 1 teacher account
- 2 children (Aisha — English, Bobur — Uzbek) under the parent
- Parental consents, wallets, one adaptation profile (Bobur)
- A demo class + enrollment, curriculum v1.0.0 with a Letters level and 26 letter items

Run it from the host (uses `backend/.env`, which points at `localhost:5432`):

```bash
cd backend
source .venv/bin/activate   # or: pip install -e ".[dev]"
python scripts/seed.py
```

### Test credentials (after seeding)

| Role    | Email                | Password    |
|---------|-----------------------|-------------|
| Parent  | `parent@demo.app`     | `demo1234`  |
| Teacher | `teacher@demo.app`    | `demo1234`  |
| Admin   | `admin@flexikeys.app` | `admin-secret-change-me` |

Seeded child IDs (for testing `child_id` query params):
- Aisha: `00000000-0000-0000-0000-000000000010`
- Bobur: `00000000-0000-0000-0000-000000000011`

## Example auth flow

```bash
BASE=http://localhost:8000/api/v1

# Register a new parent
curl -X POST $BASE/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"newparent@test.com","password":"testpass123","role":"parent"}'

# Login as the seeded parent
curl -X POST $BASE/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"parent@demo.app","password":"demo1234"}'
# => {"access_token": "...", "refresh_token": "...", "token_type": "bearer"}

# Refresh
curl -X POST $BASE/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refresh_token":"<refresh_token>"}'

# Read progress for a child (requires Authorization header)
curl "$BASE/progress/skills?child_id=00000000-0000-0000-0000-000000000010&language=en" \
  -H "Authorization: Bearer <access_token>"

curl "$BASE/progress/timeseries?child_id=00000000-0000-0000-0000-000000000010&metric=accuracy&range_days=30" \
  -H "Authorization: Bearer <access_token>"

# Logout (revokes the refresh token)
curl -X POST $BASE/auth/logout \
  -H "Content-Type: application/json" \
  -d '{"refresh_token":"<refresh_token>"}'
```

## Parent AI assistant

The parent dashboard's "Ask AI" tab talks to a real, grounded pipeline
(`/ai-assistant/chat` → tool-use loop → real progress/mastery data) — but by
default `AI_PROVIDER=stub`, so every reply is the canned "AI assistant is
currently unavailable" message. To get live replies:

1. Get an Anthropic API key.
2. In `backend/.env` (host runs) and/or `infra/.env` (Docker Compose), set:
   ```
   AI_PROVIDER=anthropic
   AI_API_KEY=sk-ant-...
   AI_MODEL=claude-sonnet-4-6   # optional, this is already the default
   ```
3. Restart the backend (`docker compose restart backend`, or re-run
   `uvicorn` if running on the host).

No key is committed anywhere in this repo — `AI_API_KEY` is read from env
only (see `core/config.py`). Leaving it unset is safe; the assistant just
shows the disabled-state message instead of erroring.

## Running tests

The pytest suite needs a separate `flexikeys_test` database (kept apart from
the `flexikeys` dev database migrations use above):

```bash
docker compose exec postgres psql -U flexikeys -d flexikeys -c "CREATE DATABASE flexikeys_test;"

cd backend && source .venv/bin/activate
APP_SECRET_KEY=test-secret-key-for-ci-only \
DATABASE_URL="postgresql+asyncpg://flexikeys:flexikeys_dev_pw@localhost:5432/flexikeys_test" \
REDIS_URL="redis://localhost:6379/1" \
python -m pytest -q
```

Most tests are pure unit tests with no DB dependency and run instantly. A
subset (`test_models.py`, `test_health.py`, `test_authz_matrix.py`, etc.)
spin up a real Postgres via the `run_migrations`/`db_session`/`client`
fixtures in `tests/conftest.py`.

**Known pre-existing gaps** (not touched — out of scope for the Docker/auth/progress work):
- A number of DB-backed tests share one event loop/engine across
  session-scoped fixtures and fail with asyncio loop-mismatch errors when run
  as part of the full suite. They were written but, per the project history,
  never exercised against a real database until now.
- `test_auth.py` shares one real Redis instance across ~50 sequential auth
  requests in a single test session; the sliding-window rate limiter (20
  req/min) can trip on later tests in the file, producing `429` where a test
  expects a different status code. Not a rate-limiter bug — a test-isolation
  gap (no Redis flush between tests).
- `modules/admin` (`AuditLog`, `FeatureFlag`) has models but no Alembic
  migration — `alembic/env.py` never imports `modules.admin.models`. Admin
  endpoints will fail against the DB if exercised; out of scope here since
  the brief was auth + progress.

## Bugs fixed while wiring this up

These were present before this session and blocked the backend from ever
starting against a real database:

1. **`alembic/versions/0003_curriculum_tables.py`** duplicated tables already
   created in `0001_initial_schema.py` (with an inconsistent `asset_kind`
   enum) — migrations failed on a fresh DB. Deleted; `0004`'s `down_revision`
   now points directly at `0002`.
2. **`0001_initial_schema.py`** used `sa.Enum(name=..., create_type=False)`
   for 13 columns. `create_type` is a `postgresql.ENUM`-only kwarg; the
   generic `sa.Enum` silently ignores it and tries to create an *empty* enum
   type on every table, colliding with the type already created by the raw
   `CREATE TYPE` statement earlier in the same migration. Switched all 13 to
   `postgresql.ENUM(name=..., create_type=False)`.
3. **`backend/Dockerfile`**: `COPY alembic.ini alembic/ ./alembic/` placed
   `alembic.ini` at `/app/alembic/alembic.ini` instead of `/app/alembic.ini`,
   breaking `script_location = alembic` (relative to CWD). Split into two
   `COPY` lines.
4. **`backend/Dockerfile` / `infra/docker-compose.yml`**: both invoked
   `uvicorn`/`alembic` as bare commands, but `pip install --target /deps`
   doesn't install console-script wrappers onto `PATH` in the runtime image —
   only `site-packages` was copied. Switched to `python -m alembic` /
   `python -m uvicorn` everywhere.
5. **`core/config.py`**: `cors_origins: list[str]` with a comma-separated env
   value crashed at startup — `pydantic-settings` tries to `json.loads()` env
   values for complex/list types *before* running field validators, so a
   plain CSV string like `http://localhost,http://10.0.2.2` raised a
   `SettingsError`. Fixed by annotating the field
   `Annotated[list[str], NoDecode]` so pydantic-settings passes the raw
   string through to the existing comma-split validator.
6. **`alembic/versions/0004_seed_reward_definitions.py`** and
   **`scripts/seed.py`**: raw SQL used `:param::jsonb` (bind param
   immediately followed by a Postgres cast) — SQLAlchemy's `text()` bind
   parameter parser doesn't recognize `:name` when followed directly by `::`,
   so the literal `:param::jsonb` was sent to asyncpg unresolved, causing a
   syntax error. Changed to `CAST(:param AS jsonb)` in all four occurrences.
   `0004` also passed `sa.null()` as a bound parameter value instead of
   Python `None`; fixed alongside.
7. **`scripts/seed.py`** passed `datetime.isoformat()` strings for two
   `DateTime` columns via raw `text()` — asyncpg's driver requires actual
   `datetime` objects for timestamp columns, not ISO strings (unlike
   psycopg2, which coerces them). Fixed to pass the `datetime` object
   directly.
8. Added `backend/docker-entrypoint.sh` so the `backend` container runs
   `alembic upgrade head` before starting `uvicorn` — there was previously no
   migrate-on-boot step at all.