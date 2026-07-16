from __future__ import annotations

import uuid
from datetime import datetime
from typing import Any

from pydantic import BaseModel, Field


class AuditLogOut(BaseModel):
    id: uuid.UUID
    actor_id: uuid.UUID | None
    action: str
    resource_type: str
    resource_id: str | None
    payload: dict[str, Any] | None
    created_at: datetime

    model_config = {"from_attributes": True}


class FeatureFlagOut(BaseModel):
    id: uuid.UUID
    key: str
    enabled: bool
    description: str | None
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class SetFeatureFlagIn(BaseModel):
    key: str = Field(..., min_length=1, max_length=128)
    enabled: bool
    description: str | None = Field(default=None, max_length=512)


class PlatformAnalyticsOut(BaseModel):
    dau: int
    wau: int
    total_children: int
    total_sessions_today: int
    avg_mastery_global: float
    needs_attention_count: int
