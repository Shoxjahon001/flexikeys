from __future__ import annotations

import uuid
from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from flexikeys.core.config import get_settings
from flexikeys.core.db import get_db
from flexikeys.core.deps import get_current_user
from flexikeys.modules.ai_assistant.llm_provider import build_provider
from flexikeys.modules.ai_assistant.schemas import (
    ChatRequest,
    ChatResponseOut,
    ConversationOut,
    MessageOut,
)
from flexikeys.modules.ai_assistant.service import AiAssistantService
from flexikeys.modules.parent.repository import ParentRepository
from flexikeys.modules.users.models import User

router = APIRouter(prefix="/ai-assistant", tags=["ai_assistant"])


def _svc(db: AsyncSession) -> AiAssistantService:
    settings = get_settings()
    provider = build_provider(settings)
    return AiAssistantService(
        session=db,
        progress_repo=None,  # lazily resolved inside service
        parent_repo=ParentRepository(db),
        provider=provider,
    )


@router.post("/chat", response_model=ChatResponseOut)
async def chat(
    body: ChatRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> ChatResponseOut:
    return await _svc(db).chat(body, current_user.id)


@router.get("/conversations", response_model=list[ConversationOut])
async def list_conversations(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> list[ConversationOut]:
    raw = await _svc(db).list_conversations(current_user.id)
    return [
        ConversationOut(
            id=c["id"],
            title=c["title"],
            created_at=c["created_at"],
            messages=[
                MessageOut(
                    id=m["id"],
                    role=m["role"],
                    content=m["content"],
                    created_at=m["created_at"],
                )
                for m in c["messages"]
            ],
        )
        for c in raw
    ]


@router.get("/conversations/{conversation_id}", response_model=ConversationOut)
async def get_conversation(
    conversation_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> ConversationOut:
    raw = await _svc(db).get_conversation(conversation_id, current_user.id)
    return ConversationOut(
        id=raw["id"],
        title=raw["title"],
        created_at=raw["created_at"],
        messages=[
            MessageOut(
                id=m["id"],
                role=m["role"],
                content=m["content"],
                created_at=m["created_at"],
            )
            for m in raw["messages"]
        ],
    )
