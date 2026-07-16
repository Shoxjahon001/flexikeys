from __future__ import annotations

from sqlalchemy.ext.asyncio import AsyncSession

from flexikeys.modules.users.models import User
from flexikeys.modules.users.repository import UserRepository


class UserService:
    def __init__(self, session: AsyncSession) -> None:
        self._repo = UserRepository(session)

    async def update_me(
        self, user: User, locale: str | None, timezone: str | None
    ) -> User:
        updates = {k: v for k, v in {"locale": locale, "timezone": timezone}.items() if v is not None}
        if updates:
            user = await self._repo.update(user, **updates)
        return user