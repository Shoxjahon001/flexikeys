from __future__ import annotations

import uuid
from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from flexikeys.core.db import get_db
from flexikeys.core.deps import get_child_claims
from flexikeys.core.redis import get_redis
from flexikeys.modules.rewards.schemas import (
    CatalogItemOut,
    EarnOut,
    EarnRequest,
    RedeemOut,
    RedeemRequest,
    WalletOut,
)
from flexikeys.modules.rewards.service import RewardsService

router = APIRouter(prefix="/rewards", tags=["rewards"])


def _svc(db: AsyncSession, redis: object) -> RewardsService:
    return RewardsService(db, redis)  # type: ignore[arg-type]


@router.get("/wallet", response_model=WalletOut)
async def get_wallet(
    claims: Annotated[dict, Depends(get_child_claims)],
    db: Annotated[AsyncSession, Depends(get_db)],
    redis: Annotated[object, Depends(get_redis)],
) -> WalletOut:
    child_id = uuid.UUID(claims["sub"])
    svc = _svc(db, redis)
    result = await svc.get_wallet(child_id)
    await db.commit()
    return result


@router.get("/catalog", response_model=list[CatalogItemOut])
async def get_catalog(
    claims: Annotated[dict, Depends(get_child_claims)],
    db: Annotated[AsyncSession, Depends(get_db)],
    redis: Annotated[object, Depends(get_redis)],
) -> list[CatalogItemOut]:
    child_id = uuid.UUID(claims["sub"])
    svc = _svc(db, redis)
    return await svc.get_catalog(child_id)


@router.post("/earn", response_model=EarnOut)
async def earn_reward(
    body: EarnRequest,
    claims: Annotated[dict, Depends(get_child_claims)],
    db: Annotated[AsyncSession, Depends(get_db)],
    redis: Annotated[object, Depends(get_redis)],
) -> EarnOut:
    child_id = uuid.UUID(claims["sub"])
    svc = _svc(db, redis)
    result = await svc.earn(child_id, body.coins, body.stars)
    await db.commit()
    return result


@router.post("/{reward_id}/redeem", response_model=RedeemOut, status_code=200)
async def redeem_reward(
    reward_id: uuid.UUID,
    body: RedeemRequest,
    claims: Annotated[dict, Depends(get_child_claims)],
    db: Annotated[AsyncSession, Depends(get_db)],
    redis: Annotated[object, Depends(get_redis)],
) -> RedeemOut:
    child_id = uuid.UUID(claims["sub"])
    svc = _svc(db, redis)
    result = await svc.redeem(reward_id, child_id)
    await db.commit()
    return result
