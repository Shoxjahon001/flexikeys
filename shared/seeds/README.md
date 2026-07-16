# seeds

Seed data for local development and CI.

## Structure

```
seeds/
├── curriculum.json    # Full curriculum definition (conforms to ../curriculum/schema.json)
├── users.json         # Test parent/teacher accounts (hashed with argon2id)
└── children.json      # Sample child profiles linked to test users
```

## Usage

Seeds are applied via the `seed` Makefile target in `backend/`:

```bash
cd backend
make seed          # apply seeds to local DB
make seed-reset    # drop seed data and reapply
```

The seed runner is a standalone Python script (`backend/scripts/seed.py`) that:
1. Validates `curriculum.json` against `../curriculum/schema.json`
2. Upserts records (idempotent — safe to re-run)
3. Skips production environments (`APP_ENV=production`)

## Adding seeds

Add entries to the relevant JSON files and run `make seed`. Do not commit real personal data — use fictional names and generated UUIDs.