from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from flexikeys.core.enums import RewardKind, RewardSource


class WalletOut(BaseModel):
    child_id: uuid.UUID
    coins: int
    stars: int
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class CatalogItemOut(BaseModel):
    id: uuid.UUID
    kind: RewardKind
    slug: str
    cost_coins: int | None
    unlock_rule: dict | None
    owned: bool = False

    model_config = ConfigDict(from_attributes=True)


class EarnRequest(BaseModel):
    child_id: uuid.UUID
    coins: int = Field(ge=0)
    stars: int = Field(ge=0, le=3)
    reason: str  # e.g. "item_completed", "lesson_stars"


class EarnOut(BaseModel):
    coins_total: int
    stars_total: int


class RedeemRequest(BaseModel):
    child_id: uuid.UUID


class RedeemOut(BaseModel):
    reward_id: uuid.UUID
    slug: str
    kind: RewardKind
    source: RewardSource
    granted_at: datetime


class BadgeGrantOut(BaseModel):
    badge_slug: str
    granted_at: datetime
