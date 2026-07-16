from __future__ import annotations

import uuid
from datetime import datetime
from typing import Any

from pydantic import BaseModel


class ChildSummaryOut(BaseModel):
    child_id: uuid.UUID
    display_name: str
    today_minutes: float
    today_items: int
    streak_days: int
    learning_language: str
    ui_language: str


class ReportOut(BaseModel):
    id: uuid.UUID
    scope: str
    period: str
    payload: dict[str, Any]
    created_at: datetime


class ExportDataOut(BaseModel):
    child_id: uuid.UUID
    display_name: str
    learning_language: str
    activity_records: list[dict[str, Any]]
    skill_mastery: list[dict[str, Any]]
    adaptation_changes: list[dict[str, Any]]
    exported_at: datetime
