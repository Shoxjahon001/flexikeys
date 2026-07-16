from __future__ import annotations

import os
import pathlib
import subprocess
import sys

import pytest
from httpx import ASGITransport, AsyncClient

os.environ.setdefault("APP_SECRET_KEY", "test-secret-key-for-ci-only")
os.environ.setdefault(
    "DATABASE_URL",
    "postgresql+asyncpg://flexikeys:flexikeys@localhost:5432/flexikeys_test",
)
os.environ.setdefault("REDIS_URL", "redis://localhost:6379/1")
os.environ.setdefault("APP_ENV", "development")

_BACKEND_DIR = pathlib.Path(__file__).parent.parent
_ALEMBIC_ENV = {**os.environ, "PYTHONPATH": str(_BACKEND_DIR / "src")}


@pytest.fixture(scope="session")
def run_migrations() -> None:  # type: ignore[misc]
    """Run alembic upgrade head before the test session; downgrade after.

    This fixture is NOT autouse — only tests that explicitly request
    db_session or client will trigger it, so pure unit tests run without
    a database connection.
    """
    result = subprocess.run(
        [sys.executable, "-m", "alembic", "upgrade", "head"],
        cwd=_BACKEND_DIR,
        env=_ALEMBIC_ENV,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(f"alembic upgrade failed:\n{result.stdout}\n{result.stderr}")

    yield

    subprocess.run(
        [sys.executable, "-m", "alembic", "downgrade", "base"],
        cwd=_BACKEND_DIR,
        env=_ALEMBIC_ENV,
        capture_output=True,
        text=True,
    )


@pytest.fixture()
async def db_session(run_migrations: None):  # type: ignore[misc]
    from flexikeys.core.db import get_session_factory

    factory = get_session_factory()
    async with factory() as session:
        yield session


@pytest.fixture()
async def client(run_migrations: None):  # type: ignore[misc]
    from flexikeys.main import create_app

    app = create_app()
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as c:
        yield c
