from __future__ import annotations

import importlib.metadata
from collections.abc import AsyncGenerator
from contextlib import asynccontextmanager
from typing import Any

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from flexikeys.core.config import get_settings
from flexikeys.core.db import check_db
from flexikeys.core.logging import RequestLoggingMiddleware, configure_logging
from flexikeys.core.redis import check_redis


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    settings = get_settings()
    configure_logging(settings.log_level)
    yield


def create_app() -> FastAPI:
    settings = get_settings()

    app = FastAPI(
        title="FlexiKeys API",
        description="Adaptive EdTech backend for the FlexiKeys platform.",
        version="0.1.0",
        docs_url="/docs" if not settings.is_production else None,
        redoc_url="/redoc" if not settings.is_production else None,
        lifespan=lifespan,
    )

    # CORS
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.add_middleware(RequestLoggingMiddleware)

    # ── RFC 7807 global exception handlers ────────────────────────────────────

    @app.exception_handler(Exception)
    async def _unhandled(request: Request, exc: Exception) -> JSONResponse:
        return JSONResponse(
            status_code=500,
            content={
                "type": "about:blank",
                "title": "Internal Server Error",
                "status": 500,
                "detail": "An unexpected error occurred.",
                "instance": str(request.url),
            },
        )

    from fastapi import HTTPException

    @app.exception_handler(HTTPException)
    async def _http(request: Request, exc: HTTPException) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content={
                "type": "about:blank",
                "title": exc.detail,
                "status": exc.status_code,
                "instance": str(request.url),
            },
        )

    # ── Built-in routes ───────────────────────────────────────────────────────

    @app.get("/health", tags=["ops"])
    async def health() -> dict[str, Any]:
        db_ok = await check_db()
        redis_ok = await check_redis()
        status = "ok" if (db_ok and redis_ok) else "degraded"
        return {
            "status": status,
            "checks": {
                "db": "ok" if db_ok else "error",
                "redis": "ok" if redis_ok else "error",
            },
        }

    @app.get("/version", tags=["ops"])
    async def version() -> dict[str, str]:
        try:
            ver = importlib.metadata.version("flexikeys-backend")
        except importlib.metadata.PackageNotFoundError:
            ver = "dev"
        return {"version": ver}

    # ── Module routers ────────────────────────────────────────────────────────

    from flexikeys.modules.aac.router import router as aac_router
    from flexikeys.modules.adaptive.router import router as adaptive_router
    from flexikeys.modules.admin.router import router as admin_router
    from flexikeys.modules.ai_assistant.router import router as ai_assistant_router
    from flexikeys.modules.auth.router import router as auth_router
    from flexikeys.modules.children.router import router as children_router
    from flexikeys.modules.curriculum.router import router as curriculum_router
    from flexikeys.modules.media.router import router as media_router
    from flexikeys.modules.notifications.router import router as notifications_router
    from flexikeys.modules.parent.router import router as parent_router
    from flexikeys.modules.progress.router import router as progress_router
    from flexikeys.modules.rewards.router import router as rewards_router
    from flexikeys.modules.sessions.router import router as sessions_router
    from flexikeys.modules.teacher.router import router as teacher_router
    from flexikeys.modules.users.router import router as users_router

    prefix = "/api/v1"
    app.include_router(aac_router, prefix=prefix)
    app.include_router(auth_router, prefix=prefix)
    app.include_router(users_router, prefix=prefix)
    app.include_router(children_router, prefix=prefix)
    app.include_router(curriculum_router, prefix=prefix)
    app.include_router(sessions_router, prefix=prefix)
    app.include_router(adaptive_router, prefix=prefix)
    app.include_router(progress_router, prefix=prefix)
    app.include_router(rewards_router, prefix=prefix)
    app.include_router(parent_router, prefix=prefix)
    app.include_router(teacher_router, prefix=prefix)
    app.include_router(admin_router, prefix=prefix)
    app.include_router(ai_assistant_router, prefix=prefix)
    app.include_router(notifications_router, prefix=prefix)
    app.include_router(media_router, prefix=prefix)

    # ── Prometheus /metrics ───────────────────────────────────────────────────
    # Exposed on /metrics (not under /api/v1) so Prometheus can scrape it.
    # Protect this path at the network/ingress layer in production.
    try:
        from prometheus_fastapi_instrumentator import (
            Instrumentator,  # type: ignore[import-untyped,unused-ignore]
        )

        Instrumentator().instrument(app).expose(
            app, endpoint="/metrics", include_in_schema=False
        )
    except ImportError:
        pass  # prometheus-fastapi-instrumentator not installed

    return app


app = create_app()
