from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from flexikeys.core.db import get_db
from flexikeys.core.deps import get_current_user
from flexikeys.modules.users.models import User
from flexikeys.modules.users.schemas import UserOut, UserUpdate
from flexikeys.modules.users.service import UserService

router = APIRouter(tags=["users"])


@router.get("/me", response_model=UserOut)
async def get_me(user: Annotated[User, Depends(get_current_user)]) -> User:
    return user


@router.patch("/me", response_model=UserOut)
async def update_me(
    body: UserUpdate,
    user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> User:
    svc = UserService(db)
    user = await svc.update_me(user, body.locale, body.timezone)
    await db.commit()
    return user