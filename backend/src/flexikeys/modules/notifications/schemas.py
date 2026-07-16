from __future__ import annotations

import uuid
from datetime import datetime
from typing import Any

from pydantic import BaseModel


class NotificationOut(BaseModel):
    id: uuid.UUID
    kind: str
    payload: dict[str, Any] | None
    sent_at: datetime | None
    read_at: datetime | None
    created_at: datetime

    model_config = {"from_attributes": True}


class NotificationPreferenceOut(BaseModel):
    kind: str
    push_enabled: bool
    email_enabled: bool
    in_app_enabled: bool


class UpdatePreferenceIn(BaseModel):
    kind: str
    push_enabled: bool = True
    email_enabled: bool = True
    in_app_enabled: bool = True
