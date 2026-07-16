from __future__ import annotations

import uuid
from datetime import date, datetime

from pydantic import BaseModel


class SkillSummaryOut(BaseModel):
    skill_key: str
    label: str
    p_known: float
    attempts: int
    correct: int


class TimeseriesPointOut(BaseModel):
    date: date
    value: float | None


class AdaptationFeedItemOut(BaseModel):
    id: uuid.UUID
    changed_at: datetime
    param: str
    old_value: str | None
    new_value: str | None
    reason_code: str
    sentence: str


class GameProgressIn(BaseModel):
    level_slug: str
    completed: bool
    stars: int
    completed_activities: list[str] = []
    updated_at: datetime


class GameProgressOut(BaseModel):
    level_slug: str
    completed: bool
    stars: int
    completed_activities: list[str]
    updated_at: datetime
