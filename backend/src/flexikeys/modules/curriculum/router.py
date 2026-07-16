from __future__ import annotations

import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, Query
from redis.asyncio import Redis
from sqlalchemy.ext.asyncio import AsyncSession

from flexikeys.core.db import get_db
from flexikeys.core.deps import get_child_claims
from flexikeys.core.redis import get_redis
from flexikeys.modules.curriculum.schemas import (
    LessonDetailOut,
    LessonOut,
    LevelOut,
    NextLessonPlan,
)
from flexikeys.modules.curriculum.service import CurriculumService

router = APIRouter(prefix="/curriculum", tags=["curriculum"])


def _svc(db: AsyncSession, redis: Redis) -> CurriculumService:  # type: ignore[type-arg]
    return CurriculumService(db, redis)


@router.get("/levels", response_model=list[LevelOut])
async def list_levels(
    lang: str = Query(default="en", pattern="^(en|uz|ru)$"),
    _claims: Annotated[dict, Depends(get_child_claims)] = None,  # type: ignore[assignment]
    db: Annotated[AsyncSession, Depends(get_db)] = None,  # type: ignore[assignment]
    redis: Annotated[Redis, Depends(get_redis)] = None,  # type: ignore[assignment]
) -> list[LevelOut]:
    return await _svc(db, redis).list_levels(lang)


@router.get("/levels/{slug}/lessons", response_model=list[LessonOut])
async def list_lessons(
    slug: str,
    lang: str = Query(default="en", pattern="^(en|uz|ru)$"),
    _claims: Annotated[dict, Depends(get_child_claims)] = None,  # type: ignore[assignment]
    db: Annotated[AsyncSession, Depends(get_db)] = None,  # type: ignore[assignment]
    redis: Annotated[Redis, Depends(get_redis)] = None,  # type: ignore[assignment]
) -> list[LessonOut]:
    return await _svc(db, redis).list_lessons(slug, lang)


@router.get("/lessons/{lesson_id}", response_model=LessonDetailOut)
async def get_lesson(
    lesson_id: uuid.UUID,
    lang: str = Query(default="en", pattern="^(en|uz|ru)$"),
    _claims: Annotated[dict, Depends(get_child_claims)] = None,  # type: ignore[assignment]
    db: Annotated[AsyncSession, Depends(get_db)] = None,  # type: ignore[assignment]
    redis: Annotated[Redis, Depends(get_redis)] = None,  # type: ignore[assignment]
) -> LessonDetailOut:
    return await _svc(db, redis).get_lesson_detail(lesson_id, lang)


@router.get("/next", response_model=NextLessonPlan)
async def next_lesson(
    claims: Annotated[dict, Depends(get_child_claims)] = None,  # type: ignore[assignment]
    lang: str = Query(default="en", pattern="^(en|uz|ru)$"),
    db: Annotated[AsyncSession, Depends(get_db)] = None,  # type: ignore[assignment]
    redis: Annotated[Redis, Depends(get_redis)] = None,  # type: ignore[assignment]
) -> NextLessonPlan:
    child_id = uuid.UUID(claims["sub"])
    return await _svc(db, redis).get_next_lesson_plan(child_id, lang)
