from __future__ import annotations

import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from flexikeys.modules.admin.models import AuditLog, FeatureFlag


class AdminRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._s = session

    async def write_audit_log(
        self,
        actor_id: uuid.UUID | None,
        action: str,
        resource_type: str,
        resource_id: str | None = None,
        payload: dict[str, Any] | None = None,
    ) -> AuditLog:
        log = AuditLog(
            actor_id=actor_id,
            action=action,
            resource_type=resource_type,
            resource_id=resource_id,
            payload=payload,
        )
        self._s.add(log)
        await self._s.flush()
        return log

    async def list_audit_logs(
        self,
        resource_type: str | None = None,
        limit: int = 50,
        offset: int = 0,
    ) -> list[AuditLog]:
        q = select(AuditLog).order_by(AuditLog.created_at.desc())
        if resource_type:
            q = q.where(AuditLog.resource_type == resource_type)
        q = q.limit(limit).offset(offset)
        result = await self._s.execute(q)
        return list(result.scalars().all())

    async def get_feature_flag(self, key: str) -> FeatureFlag | None:
        result = await self._s.execute(
            select(FeatureFlag).where(FeatureFlag.key == key)
        )
        return result.scalar_one_or_none()

    async def list_feature_flags(self) -> list[FeatureFlag]:
        result = await self._s.execute(
            select(FeatureFlag).order_by(FeatureFlag.key)
        )
        return list(result.scalars().all())

    async def upsert_feature_flag(
        self,
        key: str,
        enabled: bool,
        description: str | None,
        updated_at: datetime,
    ) -> FeatureFlag:
        flag = await self.get_feature_flag(key)
        if flag is None:
            flag = FeatureFlag(key=key, enabled=enabled, description=description)
            self._s.add(flag)
        else:
            flag.enabled = enabled
            flag.description = description
            flag.updated_at = updated_at
        await self._s.flush()
        return flag
