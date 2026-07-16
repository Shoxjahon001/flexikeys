from __future__ import annotations

import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from flexikeys.modules.notifications.models import Notification, NotificationPreference


class NotificationRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._s = session

    async def create(
        self,
        user_id: uuid.UUID,
        kind: str,
        payload: dict[str, Any] | None,
        sent_at: datetime | None = None,
    ) -> Notification:
        notif = Notification(user_id=user_id, kind=kind, payload=payload, sent_at=sent_at)
        self._s.add(notif)
        await self._s.flush()
        return notif

    async def get_preferences(
        self, user_id: uuid.UUID, kind: str
    ) -> NotificationPreference | None:
        result = await self._s.execute(
            select(NotificationPreference).where(
                NotificationPreference.user_id == user_id,
                NotificationPreference.kind == kind,
            )
        )
        return result.scalar_one_or_none()

    async def upsert_preference(
        self,
        user_id: uuid.UUID,
        kind: str,
        push_enabled: bool,
        email_enabled: bool,
        in_app_enabled: bool,
        updated_at: datetime,
    ) -> NotificationPreference:
        pref = await self.get_preferences(user_id, kind)
        if pref is None:
            pref = NotificationPreference(
                user_id=user_id,
                kind=kind,
                push_enabled=push_enabled,
                email_enabled=email_enabled,
                in_app_enabled=in_app_enabled,
            )
            self._s.add(pref)
        else:
            pref.push_enabled = push_enabled
            pref.email_enabled = email_enabled
            pref.in_app_enabled = in_app_enabled
            pref.updated_at = updated_at
        await self._s.flush()
        return pref

    async def list_unread(
        self, user_id: uuid.UUID, limit: int = 20
    ) -> list[Notification]:
        result = await self._s.execute(
            select(Notification)
            .where(
                Notification.user_id == user_id,
                Notification.read_at.is_(None),
            )
            .order_by(Notification.created_at.desc())
            .limit(limit)
        )
        return list(result.scalars().all())
