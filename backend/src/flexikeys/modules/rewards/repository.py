from __future__ import annotations

import uuid
from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from flexikeys.core.enums import RewardKind, RewardSource
from flexikeys.modules.rewards.models import RewardDefinition, RewardGrant, Wallet


class RewardsRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._db = session

    # ── Wallet ────────────────────────────────────────────────────────────────

    async def get_or_create_wallet(self, child_id: uuid.UUID) -> Wallet:
        result = await self._db.execute(
            select(Wallet).where(Wallet.child_id == child_id).with_for_update()
        )
        wallet = result.scalar_one_or_none()
        if wallet is None:
            wallet = Wallet(child_id=child_id, coins=0, stars=0)
            self._db.add(wallet)
            await self._db.flush()
        return wallet

    async def add_coins_and_stars(
        self, child_id: uuid.UUID, coins: int, stars: int
    ) -> Wallet:
        wallet = await self.get_or_create_wallet(child_id)
        wallet.coins += coins
        wallet.stars += stars
        wallet.updated_at = datetime.now(UTC)
        await self._db.flush()
        return wallet

    async def deduct_coins(self, child_id: uuid.UUID, amount: int) -> Wallet:
        """Deduct coins; raises ValueError if insufficient balance."""
        wallet = await self.get_or_create_wallet(child_id)
        if wallet.coins < amount:
            raise ValueError("insufficient_coins")
        wallet.coins -= amount
        wallet.updated_at = datetime.now(UTC)
        await self._db.flush()
        return wallet

    # ── Catalog ───────────────────────────────────────────────────────────────

    async def get_catalog(self) -> list[RewardDefinition]:
        result = await self._db.execute(select(RewardDefinition))
        return list(result.scalars().all())

    async def get_definition(self, reward_id: uuid.UUID) -> RewardDefinition | None:
        result = await self._db.execute(
            select(RewardDefinition).where(RewardDefinition.id == reward_id)
        )
        return result.scalar_one_or_none()

    async def get_owned_ids(self, child_id: uuid.UUID) -> set[uuid.UUID]:
        result = await self._db.execute(
            select(RewardGrant.reward_definition_id).where(
                RewardGrant.child_id == child_id
            )
        )
        return {row[0] for row in result.all()}

    # ── Grants ────────────────────────────────────────────────────────────────

    async def has_grant(
        self, child_id: uuid.UUID, reward_definition_id: uuid.UUID
    ) -> bool:
        result = await self._db.execute(
            select(RewardGrant.id)
            .where(
                RewardGrant.child_id == child_id,
                RewardGrant.reward_definition_id == reward_definition_id,
            )
            .with_for_update()
        )
        return result.scalar_one_or_none() is not None

    async def grant_reward(
        self,
        child_id: uuid.UUID,
        reward_definition_id: uuid.UUID,
        source: RewardSource,
    ) -> RewardGrant | None:
        """
        Grant reward if not already owned.
        Returns the grant or None if already owned (double-spend guard).
        Uses SELECT FOR UPDATE to block concurrent attempts.
        """
        if await self.has_grant(child_id, reward_definition_id):
            return None

        grant = RewardGrant(
            id=uuid.uuid4(),
            child_id=child_id,
            reward_definition_id=reward_definition_id,
            source=source,
            granted_at=datetime.now(UTC),
        )
        self._db.add(grant)
        await self._db.flush()
        return grant

    async def find_badge_by_slug(self, slug: str) -> RewardDefinition | None:
        result = await self._db.execute(
            select(RewardDefinition).where(
                RewardDefinition.slug == slug,
                RewardDefinition.kind == RewardKind.badge,
            )
        )
        return result.scalar_one_or_none()
