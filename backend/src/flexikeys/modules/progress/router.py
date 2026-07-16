from __future__ import annotations

import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from flexikeys.core.db import get_db
from flexikeys.core.deps import get_child_claims, get_current_user
from flexikeys.modules.progress.repository import ProgressRepository
from flexikeys.modules.progress.schemas import (
    AdaptationFeedItemOut,
    GameProgressIn,
    GameProgressOut,
    SkillSummaryOut,
    TimeseriesPointOut,
)
from flexikeys.modules.progress.service import ProgressService
from flexikeys.modules.users.models import User

router = APIRouter(prefix="/progress", tags=["progress"])


def _svc(db: AsyncSession) -> ProgressService:
    return ProgressService(ProgressRepository(db))


@router.get("/skills", response_model=list[SkillSummaryOut])
async def get_skills(
    child_id: uuid.UUID,
    language: str = Query(default="en"),
    _user: Annotated[User, Depends(get_current_user)] = None,  # type: ignore[assignment]
    db: Annotated[AsyncSession, Depends(get_db)] = None,  # type: ignore[assignment]
) -> list[SkillSummaryOut]:
    return await _svc(db).get_skills(child_id, language)


@router.get("/timeseries", response_model=list[TimeseriesPointOut])
async def get_timeseries(
    child_id: uuid.UUID,
    metric: str = Query(default="accuracy", pattern="^(accuracy|speed|time)$"),
    range_days: int = Query(default=30, ge=1, le=365),
    _user: Annotated[User, Depends(get_current_user)] = None,  # type: ignore[assignment]
    db: Annotated[AsyncSession, Depends(get_db)] = None,  # type: ignore[assignment]
) -> list[TimeseriesPointOut]:
    return await _svc(db).get_timeseries(child_id, metric, range_days)


@router.get("/adaptations", response_model=list[AdaptationFeedItemOut])
async def get_adaptations(
    child_id: uuid.UUID,
    ui_language: str = Query(default="en"),
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    _user: Annotated[User, Depends(get_current_user)] = None,  # type: ignore[assignment]
    db: Annotated[AsyncSession, Depends(get_db)] = None,  # type: ignore[assignment]
) -> list[AdaptationFeedItemOut]:
    return await _svc(db).get_adaptations(child_id, ui_language, limit, offset)


@router.get("/sync", response_model=list[GameProgressOut])
async def get_game_progress(
    claims: Annotated[dict[str, object], Depends(get_child_claims)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> list[GameProgressOut]:
    """Pull the authenticated child's backed-up offline game progress."""
    child_id = uuid.UUID(str(claims["sub"]))
    return await _svc(db).get_game_progress(child_id)


@router.put("/sync", response_model=list[GameProgressOut])
async def sync_game_progress(
    body: list[GameProgressIn],
    claims: Annotated[dict[str, object], Depends(get_child_claims)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> list[GameProgressOut]:
    """Push queued local level-progress changes. Last-write-wins per level;
    returns the full current state so the client can reconcile any rows
    that lost to a newer server-side write.
    """
    child_id = uuid.UUID(str(claims["sub"]))
    result = await _svc(db).sync_game_progress(child_id, body)
    await db.commit()
    return result
