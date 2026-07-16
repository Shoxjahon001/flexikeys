#!/bin/sh
set -e

echo "Running database migrations..."
python -m alembic upgrade head

exec "$@"