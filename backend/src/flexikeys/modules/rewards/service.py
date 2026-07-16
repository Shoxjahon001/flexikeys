from __future__ import annotations

import uuid

from fastapi import HTTPException
from redis.asyncio import Redis
from sqlalchemy.ext.asyncio import AsyncSession

from flexikeys.core.enums import RewardSource
from flexikeys.modules.rewards.repository import RewardsRepository
from flexikeys.modules.rewards.schemas import (
    CatalogItemOut,
    EarnOut,
    RedeemOut,
    WalletOut,
)

# Coins earned per completed item — flat, effort-based, NOT accuracy-scaled.
# Never penalise struggling children by awarding fewer coins.
COINS_PER_ITEM = 10

# Redis key prefix for redeem idempotency (TTL 24 h)
_REDEEM_LOCK_TTL = 86_400


class RewardsService:
    def __init__(self, session: AsyncSession, redis: Redis) -> None:  # type: ignore[type-arg]
        self._repo = RewardsRepository(session)
        self._redis = redis

    # ── Wallet ────────────────────────────────────────────────────────────────

    async def get_wallet(self, child_id: uuid.UUID) -> WalletOut:
        wallet = await self._repo.get_or_create_wallet(child_id)
        return WalletOut.model_validate(wallet)

    # ── Earn ──────────────────────────────────────────────────────────────────

    async def earn(
        self, child_id: uuid.UUID, coins: int, stars: int
    ) -> EarnOut:
        """Credit coins and stars to the child's wallet."""
        wallet = await self._repo.add_coins_and_stars(child_id, coins, stars)
        return EarnOut(coins_total=wallet.coins, stars_total=wallet.stars)

    # ── Catalog ───────────────────────────────────────────────────────────────

    async def get_catalog(self, child_id: uuid.UUID) -> list[CatalogItemOut]:
        definitions = await self._repo.get_catalog()
        owned_ids = await self._repo.get_owned_ids(child_id)
        return [
            CatalogItemOut(
                id=d.id,
                kind=d.kind,
                slug=d.slug,
                cost_coins=d.cost_coins,
                unlock_rule=d.unlock_rule,
                owned=d.id in owned_ids,
            )
            for d in definitions
        ]

    # ── Redeem ────────────────────────────────────────────────────────────────

    async def redeem(
        self, reward_id: uuid.UUID, child_id: uuid.UUID
    ) -> RedeemOut:
        """
        Transactional redeem with double-spend protection.

        Guards:
        1. Redis SET NX lock per (child_id, reward_id) — blocks concurrent
           duplicate requests.
        2. DB INSERT ON CONFLICT DO NOTHING — second guard at storage layer.
        3. Coins deducted atomically (SELECT FOR UPDATE on wallet).
        """
        lock_key = f"redeem:{child_id}:{reward_id}"
        acquired = await self._redis.set(lock_key, "1", ex=30, nx=True)
        if not acquired:
            raise HTTPException(status_code=409, detail="redeem_in_progress")

        try:
            definition = await self._repo.get_definition(reward_id)
            if definition is None:
                raise HTTPException(status_code=404, detail="reward_not_found")

            # Check already owned
            if await self._repo.has_grant(child_id, reward_id):
                raise HTTPException(status_code=409, detail="already_owned")

            # Deduct coins (raises ValueError on insufficient balance)
            if definition.cost_coins is not None:
                try:
                    await self._repo.deduct_coins(child_id, definition.cost_coins)
                except ValueError as exc:
                    raise HTTPException(status_code=402, detail="insufficient_coins") from exc

            grant = await self._repo.grant_reward(
                child_id=child_id,
                reward_definition_id=reward_id,
                source=RewardSource.purchased_with_coins,
            )

            if grant is None:
                # Race condition — second request hit the DB layer guard
                raise HTTPException(status_code=409, detail="already_owned")

            return RedeemOut(
                reward_id=reward_id,
                slug=definition.slug,
                kind=definition.kind,
                source=grant.source,
                granted_at=grant.granted_at,
            )
        finally:
            await self._redis.delete(lock_key)

    # ── Badge granting ────────────────────────────────────────────────────────

    async def try_grant_badge(
        self, child_id: uuid.UUID, badge_slug: str
    ) -> bool:
        """
        Grant a badge to the child if not already held.
        Returns True if newly granted, False if already owned.
        Silently no-ops if the badge definition does not exist yet.
        """
        definition = await self._repo.find_badge_by_slug(badge_slug)
        if definition is None:
            return False

        grant = await self._repo.grant_reward(
            child_id=child_id,
            reward_definition_id=definition.id,
            source=RewardSource.earned,
        )
        return grant is not None
