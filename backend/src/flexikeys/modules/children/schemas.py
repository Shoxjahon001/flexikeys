from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict

from flexikeys.core.enums import ConsentType, LearningLanguage


class ChildCreate(BaseModel):
    display_name: str
    learning_language: LearningLanguage = LearningLanguage.en
    ui_language: str = "en"
    birth_year: int | None = None
    avatar_id: str | None = None
    # Optional client-supplied id: the Flutter app creates the canonical
    # child row in Supabase first (RLS-protected parent/child data lives
    # there now) and mirrors it here with the same id, so this backend's
    # own child-session minting, consent records, adaptive engine, AAC and
    # telemetry modules keep a matching local FK target.
    id: uuid.UUID | None = None


class ChildOut(BaseModel):
    id: uuid.UUID
    parent_id: uuid.UUID
    display_name: str
    learning_language: LearningLanguage
    ui_language: str
    birth_year: int | None
    avatar_id: str | None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class ChildUpdate(BaseModel):
    display_name: str | None = None
    learning_language: LearningLanguage | None = None
    ui_language: str | None = None
    avatar_id: str | None = None


class ChildSessionResponse(BaseModel):
    child_token: str
    token_type: str = "bearer"


class ConsentRequest(BaseModel):
    consent_type: ConsentType


class ConsentOut(BaseModel):
    id: uuid.UUID
    child_id: uuid.UUID
    consent_type: ConsentType
    granted_at: datetime

    model_config = ConfigDict(from_attributes=True)


class ConsentTextResponse(BaseModel):
    lang: str
    text: str
    version: str