from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr

from flexikeys.core.enums import UserRole


class UserOut(BaseModel):
    id: uuid.UUID
    email: str | None
    role: UserRole
    locale: str
    timezone: str
    email_verified: bool
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class UserUpdate(BaseModel):
    locale: str | None = None
    timezone: str | None = None