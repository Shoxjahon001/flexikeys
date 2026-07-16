from __future__ import annotations

import uuid
from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict


class AdaptationProfileOut(BaseModel):
    child_id: uuid.UUID
    params: dict[str, Any]
    version: int
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class SkillMasteryOut(BaseModel):
    skill_key: str
    language: str
    p_known: float
    attempts: int
    correct: int
    ewma_accuracy: float | None
    ewma_latency_ms: float | None
    last_seen_at: datetime | None

    model_config = ConfigDict(from_attributes=True)


class ProfileResponse(BaseModel):
    profile: AdaptationProfileOut
    mastery: list[SkillMasteryOut]
