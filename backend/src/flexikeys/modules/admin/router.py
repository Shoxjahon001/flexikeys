from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, Header, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from flexikeys.core.db import get_db
from flexikeys.core.deps import require_role
from flexikeys.core.enums import UserRole
from flexikeys.modules.admin.repository import AdminRepository
from flexikeys.modules.admin.schemas import (
    AuditLogOut,
    FeatureFlagOut,
    PlatformAnalyticsOut,
    SetFeatureFlagIn,
)
from flexikeys.modules.admin.service import AdminService
from flexikeys.modules.users.models import User

router = APIRouter(prefix="/admin", tags=["admin"])


def _svc(db: AsyncSession) -> AdminService:
    return AdminService(AdminRepository(db))


def _require_totp(x_totp_verified: str | None = Header(default=None)) -> bool:
    """Checks for TOTP verification header. Real impl would validate a short-lived token."""
    # STUB: #47 — replace with real TOTP session validation
    if x_totp_verified != "true":
        raise HTTPException(
            status_code=403, detail="TOTP verification required"
        )
    return True


@router.get("/users")
async def list_users(
    _: Annotated[User, Depends(require_role(UserRole.admin))],
) -> dict[str, str]:
    # STUB: #48 — implement user listing with pagination
    return {"status": "ok"}


@router.get("/audit-logs", response_model=list[AuditLogOut])
async def list_audit_logs(
    current_user: Annotated[User, Depends(require_role(UserRole.admin))],
    db: Annotated[AsyncSession, Depends(get_db)],
    resource_type: str | None = None,
    limit: int = 50,
    offset: int = 0,
) -> list[AuditLogOut]:
    return await _svc(db).list_audit_logs(resource_type, limit, offset)


@router.get("/feature-flags", response_model=list[FeatureFlagOut])
async def list_feature_flags(
    _: Annotated[User, Depends(require_role(UserRole.admin))],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> list[FeatureFlagOut]:
    return await _svc(db).list_feature_flags()


@router.put("/feature-flags", response_model=FeatureFlagOut)
async def set_feature_flag(
    body: SetFeatureFlagIn,
    current_user: Annotated[User, Depends(require_role(UserRole.admin))],
    db: Annotated[AsyncSession, Depends(get_db)],
    totp_verified: Annotated[bool, Depends(_require_totp)],
) -> FeatureFlagOut:
    svc = _svc(db)
    result = await svc.set_feature_flag(
        current_user.id,
        body.key,
        body.enabled,
        body.description,
        totp_verified=totp_verified,
    )
    await db.commit()
    return result


@router.post("/curriculum/rollback")
async def curriculum_rollback(
    target_version: str,
    current_user: Annotated[User, Depends(require_role(UserRole.admin))],
    db: Annotated[AsyncSession, Depends(get_db)],
    totp_verified: Annotated[bool, Depends(_require_totp)],
) -> dict[str, str]:
    svc = _svc(db)
    result = await svc.curriculum_rollback(
        current_user.id, target_version, totp_verified=totp_verified
    )
    await db.commit()
    return result


@router.get("/analytics", response_model=PlatformAnalyticsOut)
async def get_platform_analytics(
    _: Annotated[User, Depends(require_role(UserRole.admin))],
) -> PlatformAnalyticsOut:
    return AdminService.get_platform_analytics()
