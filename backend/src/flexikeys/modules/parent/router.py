from __future__ import annotations

import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from flexikeys.core.db import get_db
from flexikeys.core.deps import get_current_user
from flexikeys.core.enums import UserRole
from flexikeys.modules.parent.repository import ParentRepository
from flexikeys.modules.parent.schemas import ChildSummaryOut, ExportDataOut, ReportOut
from flexikeys.modules.parent.service import ParentService
from flexikeys.modules.users.models import User

router = APIRouter(prefix="/parent", tags=["parent"])


def _svc(db: AsyncSession) -> ParentService:
    return ParentService(ParentRepository(db))


def _require_parent() -> Annotated[User, Depends(get_current_user)]:  # type: ignore[return-value]
    from flexikeys.core.deps import require_role

    return Depends(require_role(UserRole.parent))  # type: ignore[return-value]


@router.get("/children/{child_id}/summary", response_model=ChildSummaryOut)
async def get_child_summary(
    child_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> ChildSummaryOut:
    return await _svc(db).get_summary(child_id, current_user.id)


@router.get("/reports", response_model=list[ReportOut])
async def list_reports(
    child_id: uuid.UUID,
    scope: str | None = Query(default=None),
    current_user: Annotated[User, Depends(get_current_user)] = None,  # type: ignore[assignment]
    db: Annotated[AsyncSession, Depends(get_db)] = None,  # type: ignore[assignment]
) -> list[ReportOut]:
    return await _svc(db).list_reports(child_id, current_user.id, scope)


@router.get("/children/{child_id}/export", response_model=ExportDataOut)
async def export_child_data(
    child_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> ExportDataOut:
    return await _svc(db).export_child_data(child_id, current_user.id)


@router.delete("/children/{child_id}", status_code=204)
async def delete_child(
    child_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> None:
    await _svc(db).delete_child(child_id, current_user.id)
    await db.commit()
