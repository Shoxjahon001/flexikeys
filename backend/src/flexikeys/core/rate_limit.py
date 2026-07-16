from __future__ import annotations

import time
import uuid as _uuid

from fastapi import HTTPException, Request
from redis.asyncio import Redis

from flexikeys.core.redis import get_redis_client


async def sliding_window_rate_limit(
    redis: Redis,  # type: ignore[type-arg]
    key: str,
    limit: int,
    window_seconds: int,
) -> None:
    """Increment a sliding-window counter in Redis; raise 429 when limit exceeded."""
    now = time.time()
    window_start = now - window_seconds

    pipe = redis.pipeline()
    pipe.zremrangebyscore(key, "-inf", str(window_start))
    pipe.zadd(key, {str(_uuid.uuid4()): now})
    pipe.zcard(key)
    pipe.expire(key, window_seconds + 1)
    results = await pipe.execute()

    count = int(results[2])
    if count > limit:
        raise HTTPException(
            status_code=429,
            headers={"Retry-After": str(window_seconds)},
            detail="Too many requests. Please try again later.",
        )


def get_client_ip(request: Request) -> str:
    forwarded = request.headers.get("X-Forwarded-For")
    if forwarded:
        return forwarded.split(",")[0].strip()
    if request.client:
        return request.client.host
    return "unknown"


async def auth_rate_limit(request: Request) -> None:
    """FastAPI dependency: 20 requests / 60 s per IP on auth endpoints."""
    redis = get_redis_client()
    ip = get_client_ip(request)
    await sliding_window_rate_limit(redis, f"ratelimit:auth:{ip}", 20, 60)
