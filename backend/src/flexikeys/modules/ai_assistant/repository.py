from __future__ import annotations

import uuid
from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from flexikeys.modules.ai_assistant.models import AiConversation, AiMessage


class AiAssistantRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._s = session

    async def get_or_create_conversation(
        self,
        parent_user_id: uuid.UUID,
        conversation_id: uuid.UUID | None,
    ) -> AiConversation:
        if conversation_id is not None:
            result = await self._s.execute(
                select(AiConversation).where(
                    AiConversation.id == conversation_id,
                    AiConversation.parent_user_id == parent_user_id,
                )
            )
            conv = result.scalar_one_or_none()
            if conv is not None:
                return conv

        now = datetime.now(UTC)
        conv = AiConversation(
            id=uuid.uuid4(),
            parent_user_id=parent_user_id,
            title=None,
            created_at=now,
            updated_at=now,
        )
        self._s.add(conv)
        await self._s.flush()
        return conv

    async def list_conversations(
        self, parent_user_id: uuid.UUID
    ) -> list[AiConversation]:
        result = await self._s.execute(
            select(AiConversation)
            .where(AiConversation.parent_user_id == parent_user_id)
            .order_by(AiConversation.updated_at.desc())
        )
        return list(result.scalars().all())

    async def get_conversation_with_messages(
        self, conversation_id: uuid.UUID, parent_user_id: uuid.UUID
    ) -> AiConversation | None:
        result = await self._s.execute(
            select(AiConversation).where(
                AiConversation.id == conversation_id,
                AiConversation.parent_user_id == parent_user_id,
            )
        )
        return result.scalar_one_or_none()

    async def get_messages(self, conversation_id: uuid.UUID) -> list[AiMessage]:
        result = await self._s.execute(
            select(AiMessage)
            .where(AiMessage.conversation_id == conversation_id)
            .order_by(AiMessage.created_at)
        )
        return list(result.scalars().all())

    async def save_message(
        self, conversation_id: uuid.UUID, role: str, content: str
    ) -> AiMessage:
        msg = AiMessage(
            id=uuid.uuid4(),
            conversation_id=conversation_id,
            role=role,
            content=content,
            created_at=datetime.now(UTC),
        )
        self._s.add(msg)
        await self._s.flush()
        return msg

    async def update_conversation_timestamp(
        self, conversation_id: uuid.UUID
    ) -> None:
        result = await self._s.execute(
            select(AiConversation).where(AiConversation.id == conversation_id)
        )
        conv = result.scalar_one_or_none()
        if conv is not None:
            conv.updated_at = datetime.now(UTC)
            await self._s.flush()
