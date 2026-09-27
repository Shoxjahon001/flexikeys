from __future__ import annotations

import uuid
from datetime import UTC, datetime
from typing import Any

from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession

from flexikeys.core.enums import UserRole
from flexikeys.modules.users.models import User


class UserRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._s = session

    async def get_by_id(self, user_id: uuid.UUID) -> User | None:
        result = await self._s.execute(
            select(User).where(and_(User.id == user_id, User.deleted_at.is_(None)))
        )
        return result.scalar_one_or_none()

    async def create_from_supabase(
        self,
        *,
        user_id: uuid.UUID,
        email: str | None,
        locale: str = "en",
    ) -> User:
        """Lazily mirror a Supabase-authenticated parent into the local
        `users` table on first request — auth itself is verified against
        Supabase's token, this row only carries role/locale metadata that
        other backend modules (children, adaptive, AAC, ...) join against.
        """
        user = User(
            id=user_id,
            email=email,
            password_hash=None,
            role=UserRole.parent,
            locale=locale,
            email_verified=True,
        )
        self._s.add(user)
        await self._s.flush()
        return user

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