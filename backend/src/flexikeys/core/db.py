from __future__ import annotations

from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.orm import DeclarativeBase

from flexikeys.core.config import get_settings


class Base(DeclarativeBase):
    pass


def _build_engine() -> AsyncEngine:
    settings = get_settings()
    return create_async_engine(
        settings.database_url,
        pool_pre_ping=True,
        pool_size=10,
        max_overflow=20,
        echo=settings.is_development,
    )


_engine: AsyncEngine | None = None
_session_factory: async_sessionmaker[AsyncSession] | None = None


def get_engine() -> AsyncEngine:
    global _engine
    if _engine is None:
        _engine = _build_engine()
    return _engine


def get_session_factory() -> async_sessionmaker[AsyncSession]:
    global _session_factory
    if _session_factory is None:
        _session_factory = async_sessionmaker(
            get_engine(),
            expire_on_commit=False,
            class_=AsyncSession,
        )
    return _session_factory


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """FastAPI dependency — yields an async session per request."""
    async with get_session_factory()() as session:
        yield session


def AsyncSessionFactory() -> AsyncSession:  # type: ignore[return]
    """Return a new async session context manager. Usage: async with AsyncSessionFactory() as s:"""
    return get_session_factory()()


async def check_db() -> bool:
    """Returns True if the database is reachable."""
    try:
        from sqlalchemy import text

        async with get_session_factory()() as session:
            await session.execute(text("SELECT 1"))
        return True
    except Exception:
        return False