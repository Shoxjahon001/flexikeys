from __future__ import annotations

import uuid
from datetime import UTC, datetime
from typing import Any

from fastapi import HTTPException

from flexikeys.modules.admin.repository import AdminRepository
from flexikeys.modules.admin.schemas import (
    AuditLogOut,
    FeatureFlagOut,
    PlatformAnalyticsOut,
)

# TOTP grace window — checked at router level with a dependency.
# The service layer enforces that admin-scoped mutations require a verified
# TOTP session flag present in the request state.
_TOTP_SESSION_KEY = "totp_verified"


class AdminService:
    def __init__(self, repo: AdminRepository) -> None:
        self._repo = repo

    async def set_feature_flag(
        self,
        actor_id: uuid.UUID,
        key: str,
        enabled: bool,
        description: str | None,
        *,
        totp_verified: bool,
    ) -> FeatureFlagOut:
        if not totp_verified:
            raise HTTPException(
                status_code=403,
                detail="TOTP verification required for admin mutations",
            )
        now = datetime.now(UTC)
        flag = await self._repo.upsert_feature_flag(key, enabled, description, now)
        await self._repo.write_audit_log(
            actor_id=actor_id,
            action="set_feature_flag",
            resource_type="feature_flag",
            resource_id=key,
            payload={"enabled": enabled},
        )
        return FeatureFlagOut.model_validate(flag)

    async def list_feature_flags(self) -> list[FeatureFlagOut]:
        flags = await self._repo.list_feature_flags()
        return [FeatureFlagOut.model_validate(f) for f in flags]

    async def list_audit_logs(
        self,
        resource_type: str | None = None,
        limit: int = 50,
        offset: int = 0,
    ) -> list[AuditLogOut]:
        logs = await self._repo.list_audit_logs(resource_type, limit, offset)
        return [AuditLogOut.model_validate(log) for log in logs]

    async def write_audit_log(
        self,
        actor_id: uuid.UUID | None,
        action: str,
        resource_type: str,
        resource_id: str | None = None,
        payload: dict[str, Any] | None = None,
    ) -> AuditLogOut:
        log = await self._repo.write_audit_log(
            actor_id, action, resource_type, resource_id, payload
        )
        return AuditLogOut.model_validate(log)

    async def curriculum_rollback(
        self,
        actor_id: uuid.UUID,
        curriculum_version: str,
        *,
        totp_verified: bool,
    ) -> dict[str, str]:
        """Roll back curriculum to a previous version. Audited."""
        if not totp_verified:
            raise HTTPException(
                status_code=403,
                detail="TOTP verification required for curriculum rollback",
            )
        await self._repo.write_audit_log(
            actor_id=actor_id,
            action="curriculum_rollback",
            resource_type="curriculum",
            resource_id=curriculum_version,
            payload={"target_version": curriculum_version},
        )
        # STUB: #45 — implement actual curriculum version switching
        return {"status": "rollback_queued", "target_version": curriculum_version}

    @staticmethod
    def get_platform_analytics() -> PlatformAnalyticsOut:
        """STUB: #46 — implement real DAU/WAU queries from analytics tables."""
        return PlatformAnalyticsOut(
            dau=0,
            wau=0,
            total_children=0,
            total_sessions_today=0,
            avg_mastery_global=0.0,
            needs_attention_count=0,
        )
