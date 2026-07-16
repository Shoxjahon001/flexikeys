from __future__ import annotations

from collections.abc import AsyncGenerator

import redis.asyncio as aioredis
from redis.asyncio import Redis

from flexikeys.core.config import get_settings

_client: Redis | None = None  # type: ignore[type-arg]


def get_redis_client() -> Redis:  # type: ignore[type-arg]
    global _client
    if _client is None:
        settings = get_settings()
        _client = aioredis.from_url(
            settings.redis_url,
            encoding="utf-8",
            decode_responses=True,
        )
    return _client


async def get_redis() -> AsyncGenerator[Redis, None]:  # type: ignore[type-arg]
    """FastAPI dependency — yields the shared Redis client."""
    yield get_redis_client()


async def check_redis() -> bool:
    """Returns True if Redis is reachable."""
    try:
        client = get_redis_client()
        await client.ping()
        return True
    except Exception:
        return False


async def build_redis() -> Redis:  # type: ignore[type-arg]
    """Return a fresh Redis client for use outside request context (e.g. background tasks)."""
    settings = get_settings()
    return aioredis.from_url(
        settings.redis_url,
        encoding="utf-8",
        decode_responses=True,
    )