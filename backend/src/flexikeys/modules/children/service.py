from __future__ import annotations

import uuid
from datetime import UTC, datetime
from typing import Sequence

from fastapi import HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from flexikeys.core.enums import ConsentType, LearningLanguage
from flexikeys.core.security import create_child_session_token
from flexikeys.modules.auth.models import ParentalConsent
from flexikeys.modules.auth.repository import AuthRepository
from flexikeys.modules.children.models import Child
from flexikeys.modules.children.repository import ChildRepository


class ChildrenService:
    def __init__(self, session: AsyncSession) -> None:
        self._repo = ChildRepository(session)
        self._auth_repo = AuthRepository(session)

    async def create_child(
        self,
        parent_id: uuid.UUID,
        display_name: str,
        learning_language: LearningLanguage,
        ui_language: str = "en",
        birth_year: int | None = None,
        avatar_id: str | None = None,
        child_id: uuid.UUID | None = None,
    ) -> Child:
        return await self._repo.create(
            parent_id=parent_id,
            display_name=display_name,
            learning_language=learning_language,
            ui_language=ui_language,
            birth_year=birth_year,
            avatar_id=avatar_id,
            child_id=child_id,
        )

    async def list_children(self, parent_id: uuid.UUID) -> Sequence[Child]:
        return await self._repo.list_by_parent(parent_id)

    async def update_child(
        self, child_id: uuid.UUID, parent_id: uuid.UUID, **kwargs: object
    ) -> Child:
        child = await self._repo.get_by_id(child_id)
        if child is None or child.deleted_at is not None:
            raise HTTPException(status_code=404, detail="Child not found")
        if child.parent_id != parent_id:
            raise HTTPException(status_code=403, detail="Access denied")
        return await self._repo.update(child, **kwargs)

    async def create_session_token(
        self, child_id: uuid.UUID, parent_id: uuid.UUID
    ) -> str:
        child = await self._repo.get_by_id(child_id)
        if child is None or child.deleted_at is not None:
            raise HTTPException(status_code=404, detail="Child not found")
        if child.parent_id != parent_id:
            raise HTTPException(status_code=403, detail="Access denied")
        return create_child_session_token(
            str(child.id), str(parent_id), child.learning_language.value
        )

    async def record_consent(
        self, child_id: uuid.UUID, parent_id: uuid.UUID, consent_type: ConsentType
    ) -> ParentalConsent:
        child = await self._repo.get_by_id(child_id)
        if child is None or child.deleted_at is not None:
            raise HTTPException(status_code=404, detail="Child not found")
        if child.parent_id != parent_id:
            raise HTTPException(status_code=403, detail="Access denied")
        return await self._auth_repo.create_consent(
            child_id=child_id,
            consent_type=consent_type,
            granted_at=datetime.now(UTC),
        )