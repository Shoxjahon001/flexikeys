from __future__ import annotations

import uuid
from datetime import UTC, datetime
from typing import Any

from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession

from flexikeys.modules.users.models import User


class UserRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._s = session

    async def get_by_id(self, user_id: uuid.UUID) -> User | None:
        result = await self._s.execute(
            select(User).where(and_(User.id == user_id, User.deleted_at.is_(None)))
        )
        return result.scalar_one_or_none()

    async def get_by_email(self, email: str) -> User | None:
        result = await self._s.execute(
            select(User).where(and_(User.email == email, User.deleted_at.is_(None)))
        )
        return result.scalar_one_or_none()

    async def update(self, user: User, **kwargs: Any) -> User:
        for k, v in kwargs.items():
            setattr(user, k, v)
        user.updated_at = datetime.now(UTC)
        await self._s.flush()
        return user