from __future__ import annotations

import uuid
from typing import Annotated

from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError
from sqlalchemy.ext.asyncio import AsyncSession

from flexikeys.core.db import get_db
from flexikeys.core.enums import UserRole
from flexikeys.core.security import decode_token
from flexikeys.modules.users.models import User

_bearer = HTTPBearer(auto_error=False)


async def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(_bearer)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> User:
    if not credentials:
        raise HTTPException(status_code=401, detail="Not authenticated")
    try:
        claims = decode_token(credentials.credentials)
    except JWTError as exc:
        raise HTTPException(status_code=401, detail="Invalid or expired token") from exc
    if claims.get("type") != "access":
        raise HTTPException(status_code=401, detail="Invalid token type")

    from flexikeys.modules.users.repository import UserRepository

    repo = UserRepository(db)
    user = await repo.get_by_id(uuid.UUID(claims["sub"]))
    if user is None or user.deleted_at is not None:
        raise HTTPException(status_code=401, detail="User not found")
    return user


def require_role(*roles: UserRole):  # type: ignore[return]
    """Dependency factory: ensure the current user has one of the given roles."""

    async def _inner(user: Annotated[User, Depends(get_current_user)]) -> User:
        if user.role not in roles:
            raise HTTPException(status_code=403, detail="Insufficient permissions")
        return user

    return _inner


async def get_child_claims(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(_bearer)],
) -> dict[str, object]:
    """Validate a child-session JWT and return its decoded claims."""
    if not credentials:
        raise HTTPException(status_code=401, detail="Not authenticated")
    try:
        claims = decode_token(credentials.credentials)
    except JWTError as exc:
        raise HTTPException(status_code=401, detail="Invalid or expired token") from exc
    if claims.get("type") != "child_session":
        raise HTTPException(status_code=401, detail="Invalid token type")
    return claims
