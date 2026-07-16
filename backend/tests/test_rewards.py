"""
Rewards service unit tests — no database or Redis required.

These tests exercise the business logic in RewardsService by injecting
mock repositories. The DB-backed integration tests live in tests/integration/
and require a running PostgreSQL instance.
"""
from __future__ import annotations

import uuid
from datetime import UTC, datetime
from typing import Any
from unittest.mock import AsyncMock, MagicMock

import pytest

from flexikeys.core.enums import RewardKind, RewardSource
from flexikeys.modules.rewards.models import RewardDefinition, RewardGrant, Wallet
from flexikeys.modules.rewards.service import COINS_PER_ITEM, RewardsService

# ── Test-object factories ──────────────────────────────────────────────────────


def _wallet(coins: int = 0, stars: int = 0) -> MagicMock:
    w = MagicMock(spec=Wallet)
    w.coins = coins
    w.stars = stars
    w.child_id = uuid.uuid4()
    w.updated_at = datetime.now(UTC)
    return w


def _definition(
    slug: str = "test_hat",
    kind: RewardKind = RewardKind.accessory,
    cost_coins: int | None = 50,
) -> MagicMock:
    d = MagicMock(spec=RewardDefinition)
    d.id = uuid.uuid4()
    d.kind = kind
    d.slug = slug
    d.cost_coins = cost_coins
    d.unlock_rule = None
    return d


def _grant(definition: MagicMock) -> MagicMock:
    g = MagicMock(spec=RewardGrant)
    g.id = uuid.uuid4()
    g.reward_definition_id = definition.id
    g.source = RewardSource.purchased_with_coins
    g.granted_at = datetime.now(UTC)
    return g


# ── Fake Redis ────────────────────────────────────────────────────────────────


def _fake_redis() -> Any:
    """In-memory Redis stub with SET NX and DEL semantics."""
    _store: dict[str, str] = {}

    async def _set(key: str, val: str, ex: int | None = None, nx: bool = False) -> bool | None:
        if nx:
            if key in _store:
                return False  # lock not acquired
            _store[key] = val
            return True
        _store[key] = val
        return None

    async def _delete(key: str) -> None:
        _store.pop(key, None)

    redis = MagicMock()
    redis.set = _set
    redis.delete = _delete
    return redis


# ── Service builder ───────────────────────────────────────────────────────────


def _repo(**overrides: Any) -> MagicMock:
    """Mock RewardsRepository with safe defaults."""
    r = MagicMock()
    r.get_or_create_wallet = AsyncMock(return_value=_wallet())
    r.add_coins_and_stars = AsyncMock(return_value=_wallet())
    r.deduct_coins = AsyncMock(return_value=_wallet())
    r.get_catalog = AsyncMock(return_value=[])
    r.get_definition = AsyncMock(return_value=None)
    r.get_owned_ids = AsyncMock(return_value=set())
    r.has_grant = AsyncMock(return_value=False)
    r.grant_reward = AsyncMock(return_value=None)
    r.find_badge_by_slug = AsyncMock(return_value=None)
    for k, v in overrides.items():
        setattr(r, k, AsyncMock(return_value=v) if not callable(v) else v)
    return r


def _svc(repo: MagicMock, redis: Any | None = None) -> RewardsService:
    """Instantiate RewardsService bypassing __init__ to inject mocks."""
    svc: RewardsService = object.__new__(RewardsService)
    svc._repo = repo  # type: ignore[attr-defined]
    svc._redis = redis or _fake_redis()  # type: ignore[attr-defined]
    return svc


# ── Tests ─────────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_earn_credits_wallet() -> None:
    child_id = uuid.uuid4()
    wallet = _wallet(coins=COINS_PER_ITEM, stars=0)
    repo = _repo()
    repo.add_coins_and_stars = AsyncMock(return_value=wallet)

    result = await _svc(repo).earn(child_id, coins=COINS_PER_ITEM, stars=0)

    assert result.coins_total == COINS_PER_ITEM
    assert result.stars_total == 0
    repo.add_coins_and_stars.assert_awaited_once_with(child_id, COINS_PER_ITEM, 0)


@pytest.mark.asyncio
async def test_earn_accumulates_across_calls() -> None:
    child_id = uuid.uuid4()
    repo = _repo()

    # Simulate wallet growing with each call
    repo.add_coins_and_stars = AsyncMock(
        side_effect=[
            _wallet(coins=10, stars=1),
            _wallet(coins=20, stars=3),
        ]
    )

    svc = _svc(repo)
    await svc.earn(child_id, coins=10, stars=1)
    result = await svc.earn(child_id, coins=10, stars=2)

    assert result.coins_total == 20
    assert result.stars_total == 3


@pytest.mark.asyncio
async def test_earn_flat_regardless_of_accuracy() -> None:
    """Coins must be flat per item — never accuracy-scaled."""
    child_id = uuid.uuid4()
    repo = _repo()
    repo.add_coins_and_stars = AsyncMock(
        side_effect=[
            _wallet(coins=COINS_PER_ITEM, stars=0),
            _wallet(coins=COINS_PER_ITEM * 2, stars=0),
        ]
    )

    svc = _svc(repo)
    # "First-try" item
    await svc.earn(child_id, coins=COINS_PER_ITEM, stars=0)
    # "Assisted" item — same coins (effort-based, not accuracy-based)
    result = await svc.earn(child_id, coins=COINS_PER_ITEM, stars=0)

    assert result.coins_total == COINS_PER_ITEM * 2


@pytest.mark.asyncio
async def test_redeem_happy_path() -> None:
    child_id = uuid.uuid4()
    defn = _definition(slug="cloud_hat", cost_coins=50)
    grant = _grant(defn)

    repo = _repo()
    repo.get_definition = AsyncMock(return_value=defn)
    repo.has_grant = AsyncMock(return_value=False)
    repo.deduct_coins = AsyncMock(return_value=_wallet(coins=50))
    repo.grant_reward = AsyncMock(return_value=grant)

    result = await _svc(repo).redeem(defn.id, child_id)

    assert result.slug == "cloud_hat"
    assert result.kind == RewardKind.accessory
    repo.deduct_coins.assert_awaited_once_with(child_id, 50)


@pytest.mark.asyncio
async def test_redeem_double_spend_rejected() -> None:
    """Second redeem of the same reward must raise 409 already_owned."""
    from fastapi import HTTPException

    child_id = uuid.uuid4()
    defn = _definition(slug="unique_hat", cost_coins=10)

    # has_grant returns True — item is already owned
    repo = _repo()
    repo.get_definition = AsyncMock(return_value=defn)
    repo.has_grant = AsyncMock(return_value=True)

    with pytest.raises(HTTPException) as exc_info:
        await _svc(repo).redeem(defn.id, child_id)

    assert exc_info.value.status_code == 409
    assert "already_owned" in exc_info.value.detail


@pytest.mark.asyncio
async def test_redeem_concurrent_request_blocked_by_redis() -> None:
    """When Redis NX lock is already held, raise 409 redeem_in_progress."""
    from fastapi import HTTPException

    child_id = uuid.uuid4()
    defn = _definition(cost_coins=10)
    repo = _repo()
    repo.get_definition = AsyncMock(return_value=defn)
    repo.has_grant = AsyncMock(return_value=False)

    # Pre-fill the lock so NX fails
    redis_store: dict[str, str] = {}

    async def _locked_set(
        key: str, val: str, ex: int | None = None, nx: bool = False
    ) -> bool | None:
        if nx:
            if key in redis_store:
                return False
            redis_store[key] = val
            return True
        redis_store[key] = val
        return None

    async def _delete(key: str) -> None:
        redis_store.pop(key, None)

    lock_key = f"redeem:{child_id}:{defn.id}"
    redis_store[lock_key] = "1"  # lock already held

    redis = MagicMock()
    redis.set = _locked_set
    redis.delete = _delete

    with pytest.raises(HTTPException) as exc_info:
        await _svc(repo, redis).redeem(defn.id, child_id)

    assert exc_info.value.status_code == 409
    assert "redeem_in_progress" in exc_info.value.detail


@pytest.mark.asyncio
async def test_redeem_insufficient_coins() -> None:
    from fastapi import HTTPException

    child_id = uuid.uuid4()
    defn = _definition(slug="expensive_item", cost_coins=100)

    repo = _repo()
    repo.get_definition = AsyncMock(return_value=defn)
    repo.has_grant = AsyncMock(return_value=False)
    repo.deduct_coins = AsyncMock(side_effect=ValueError("insufficient_coins"))

    with pytest.raises(HTTPException) as exc_info:
        await _svc(repo).redeem(defn.id, child_id)

    assert exc_info.value.status_code == 402
    assert "insufficient_coins" in exc_info.value.detail


@pytest.mark.asyncio
async def test_redeem_reward_not_found() -> None:
    from fastapi import HTTPException

    child_id = uuid.uuid4()
    repo = _repo()
    repo.get_definition = AsyncMock(return_value=None)

    with pytest.raises(HTTPException) as exc_info:
        await _svc(repo).redeem(uuid.uuid4(), child_id)

    assert exc_info.value.status_code == 404
    assert "reward_not_found" in exc_info.value.detail


@pytest.mark.asyncio
async def test_catalog_shows_owned_flag() -> None:
    child_id = uuid.uuid4()
    defn = _definition(slug="catalog_item", cost_coins=30)
    owned_id = defn.id

    repo = _repo()
    repo.get_catalog = AsyncMock(return_value=[defn])
    repo.get_owned_ids = AsyncMock(return_value={owned_id})

    catalog = await _svc(repo).get_catalog(child_id)

    assert len(catalog) == 1
    assert catalog[0].slug == "catalog_item"
    assert catalog[0].owned is True


@pytest.mark.asyncio
async def test_catalog_not_owned_shows_false() -> None:
    child_id = uuid.uuid4()
    defn = _definition(slug="unowned_item", cost_coins=50)

    repo = _repo()
    repo.get_catalog = AsyncMock(return_value=[defn])
    repo.get_owned_ids = AsyncMock(return_value=set())  # empty — nothing owned

    catalog = await _svc(repo).get_catalog(child_id)

    assert catalog[0].owned is False


@pytest.mark.asyncio
async def test_badge_grant_idempotent() -> None:
    child_id = uuid.uuid4()
    defn = _definition(slug="practiced_3_days", kind=RewardKind.badge, cost_coins=None)
    grant = _grant(defn)

    repo = _repo()
    repo.find_badge_by_slug = AsyncMock(return_value=defn)
    # First call: grant succeeds; second call: already owned → None
    repo.grant_reward = AsyncMock(side_effect=[grant, None])

    svc = _svc(repo)
    assert await svc.try_grant_badge(child_id, "practiced_3_days") is True
    assert await svc.try_grant_badge(child_id, "practiced_3_days") is False


@pytest.mark.asyncio
async def test_badge_missing_definition_returns_false() -> None:
    child_id = uuid.uuid4()
    repo = _repo()
    repo.find_badge_by_slug = AsyncMock(return_value=None)

    result = await _svc(repo).try_grant_badge(child_id, "nonexistent_badge_xyz")

    assert result is False
    repo.grant_reward.assert_not_called()
