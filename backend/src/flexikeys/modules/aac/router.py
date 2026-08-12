from __future__ import annotations

import uuid
from datetime import UTC, datetime
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Request, Response
from sqlalchemy.ext.asyncio import AsyncSession

from flexikeys.core.config import get_settings
from flexikeys.core.db import get_db
from flexikeys.core.deps import get_child_claims, get_current_user
from flexikeys.core.rate_limit import get_client_ip, sliding_window_rate_limit
from flexikeys.core.redis import get_redis, get_redis_client
from flexikeys.modules.aac.schemas import (
    AacEventBatchIn,
    AacEventBatchOut,
    AacInsightsResponse,
    AacStatsResponse,
    ComposeSentenceRequest,
    ComposeSentenceResponse,
    TtsRequest,
)
from flexikeys.modules.aac.service import AacService, TtsUnavailableError
from flexikeys.modules.parent.repository import ParentRepository
from flexikeys.modules.users.models import User
from flexikeys.services.ai_service import build_provider
from flexikeys.services.tts_provider import TtsSynthesisError, build_tts_provider

router = APIRouter(prefix="/aac", tags=["aac"])


def _svc(db: AsyncSession, redis: object) -> AacService:
    settings = get_settings()
    provider = build_provider(settings)
    tts_provider = build_tts_provider(settings)
    return AacService(session=db, redis=redis, provider=provider, tts_provider=tts_provider)  # type: ignore[arg-type]


async def _compose_sentence_rate_limit(request: Request) -> None:
    """30 req / 60s per IP — sentence composition hits the LLM."""
    redis = get_redis_client()
    ip = get_client_ip(request)
    await sliding_window_rate_limit(redis, f"ratelimit:aac_compose:{ip}", 30, 60)


async def _insights_rate_limit(request: Request) -> None:
    """10 req / 60s per IP — parent-triggered, far less frequent than composing."""
    redis = get_redis_client()
    ip = get_client_ip(request)
    await sliding_window_rate_limit(redis, f"ratelimit:aac_insights:{ip}", 10, 60)


async def _stats_rate_limit(request: Request) -> None:
    """20 req / 60s per IP — parent dashboard read, no LLM cost involved."""
    redis = get_redis_client()
    ip = get_client_ip(request)
    await sliding_window_rate_limit(redis, f"ratelimit:aac_stats:{ip}", 20, 60)


async def _tts_rate_limit(request: Request) -> None:
    """30 req / 60s per IP — same budget as compose-sentence; a child
    building a Sentence Strip can trigger this on every word tap plus a
    final playback, and it hits a paid external API on a cache miss."""
    redis = get_redis_client()
    ip = get_client_ip(request)
    await sliding_window_rate_limit(redis, f"ratelimit:aac_tts:{ip}", 30, 60)


@router.post("/events", response_model=AacEventBatchOut)
async def ingest_events(
    batch: AacEventBatchIn,
    _claims: Annotated[dict[str, object], Depends(get_child_claims)],
    db: Annotated[AsyncSession, Depends(get_db)],
    redis: Annotated[object, Depends(get_redis)],
) -> AacEventBatchOut:
    svc = _svc(db, redis)
    accepted, deduplicated = await svc.ingest_events(batch)
    if not deduplicated:
        await db.commit()
    return AacEventBatchOut(accepted=accepted, deduplicated=deduplicated)


@router.post(
    "/compose-sentence",
    response_model=ComposeSentenceResponse,
    dependencies=[Depends(_compose_sentence_rate_limit)],
)
async def compose_sentence(
    body: ComposeSentenceRequest,
    _claims: Annotated[dict[str, object], Depends(get_child_claims)],
    db: Annotated[AsyncSession, Depends(get_db)],
    redis: Annotated[object, Depends(get_redis)],
) -> ComposeSentenceResponse:
    svc = _svc(db, redis)
    return await svc.compose_sentence(body)


@router.post("/tts", dependencies=[Depends(_tts_rate_limit)])
async def synthesize_speech(
    body: TtsRequest,
    _claims: Annotated[dict[str, object], Depends(get_child_claims)],
    db: Annotated[AsyncSession, Depends(get_db)],
    redis: Annotated[object, Depends(get_redis)],
) -> Response:
    """Neural TTS for ad-hoc Sentence Strip text — see AacService.
    synthesize_speech's doc comment for why bundled per-card audio can't
    cover this. Raw audio bytes, not a JSON envelope: the Flutter client
    plays this directly, and a 503/502 (rather than a 200 with an error
    field) is what drives its documented on-device-TTS fallback."""
    svc = _svc(db, redis)
    try:
        audio = await svc.synthesize_speech(body.text, body.lang)
    except TtsUnavailableError as e:
        raise HTTPException(status_code=503, detail="tts_unavailable") from e
    except TtsSynthesisError as e:
        raise HTTPException(status_code=502, detail="tts_synthesis_failed") from e
    return Response(content=audio, media_type="audio/mpeg")


@router.get(
    "/insights",
    response_model=AacInsightsResponse,
    dependencies=[Depends(_insights_rate_limit)],
)
async def get_insights(
    child_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
    redis: Annotated[object, Depends(get_redis)],
) -> AacInsightsResponse:
    child = await ParentRepository(db).get_child(child_id, current_user.id)
    if child is None:
        raise HTTPException(status_code=404, detail="child_not_found")

    svc = _svc(db, redis)
    insights = await svc.generate_insights(child_id)
    return AacInsightsResponse(
        insights=insights,
        disclaimer=svc.insights_disclaimer(insights),
        generated_at=datetime.now(UTC),
    )


@router.get(
    "/stats",
    response_model=AacStatsResponse,
    dependencies=[Depends(_stats_rate_limit)],
)
async def get_stats(
    child_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
    redis: Annotated[object, Depends(get_redis)],
) -> AacStatsResponse:
    child = await ParentRepository(db).get_child(child_id, current_user.id)
    if child is None:
        raise HTTPException(status_code=404, detail="child_not_found")

    svc = _svc(db, redis)
    return await svc.get_stats(child_id)
