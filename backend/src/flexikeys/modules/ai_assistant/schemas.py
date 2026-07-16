from __future__ import annotations

import uuid
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field


class MessageIn(BaseModel):
    role: Literal["user"] = "user"
    content: str = Field(max_length=4000)


class ChatRequest(BaseModel):
    child_id: uuid.UUID
    message: str = Field(max_length=4000)
    conversation_id: uuid.UUID | None = None
    ui_language: str = "en"


class MessageOut(BaseModel):
    id: uuid.UUID
    role: str
    content: str
    created_at: datetime


class ConversationOut(BaseModel):
    id: uuid.UUID
    title: str | None
    created_at: datetime
    messages: list[MessageOut]


class ChatResponseOut(BaseModel):
    conversation_id: uuid.UUID
    message: MessageOut
