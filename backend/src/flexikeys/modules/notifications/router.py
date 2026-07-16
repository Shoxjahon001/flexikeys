from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from flexikeys.core.db import get_db
from flexikeys.core.deps import get_current_user
from flexikeys.modules.notifications.repository import NotificationRepository
from flexikeys.modules.notifications.schemas import (
    NotificationOut,
    NotificationPreferenceOut,
    UpdatePreferenceIn,
)
from flexikeys.modules.notifications.service import NotificationService
from flexikeys.modules.users.models import User

router = APIRouter(prefix="/notifications", tags=["notifications"])


def _svc(db: AsyncSession) -> NotificationService:
    return NotificationService(NotificationRepository(db))


@router.get("", response_model=list[NotificationOut])
async def list_notifications(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
    limit: int = 20,
) -> list[NotificationOut]:
    repo = NotificationRepository(db)
    notifs = await repo.list_unread(current_user.id, limit)
    return [NotificationOut.model_validate(n) for n in notifs]


@router.put("/preferences", response_model=NotificationPreferenceOut, status_code=200)
async def update_preference(
    body: UpdatePreferenceIn,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> NotificationPreferenceOut:
    from datetime import UTC, datetime

    repo = NotificationRepository(db)
    pref = await repo.upsert_preference(
        user_id=current_user.id,
        kind=body.kind,
        push_enabled=body.push_enabled,
        email_enabled=body.email_enabled,
        in_app_enabled=body.in_app_enabled,
        updated_at=datetime.now(UTC),
    )
    await db.commit()
    return NotificationPreferenceOut(
        kind=pref.kind,
        push_enabled=pref.push_enabled,
        email_enabled=pref.email_enabled,
        in_app_enabled=pref.in_app_enabled,
    )
