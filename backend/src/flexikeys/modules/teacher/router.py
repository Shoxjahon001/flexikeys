from __future__ import annotations

import uuid
from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from flexikeys.core.db import get_db
from flexikeys.core.deps import get_current_user, require_role
from flexikeys.core.enums import UserRole
from flexikeys.modules.teacher.repository import TeacherRepository
from flexikeys.modules.teacher.schemas import (
    AssignmentOut,
    ClassAnalyticsOut,
    ClassEnrollmentOut,
    ClassOut,
    CreateAssignmentIn,
    CreateClassIn,
    EnrollIn,
)
from flexikeys.modules.teacher.service import TeacherService
from flexikeys.modules.users.models import User

router = APIRouter(prefix="/teacher", tags=["teacher"])


def _svc(db: AsyncSession) -> TeacherService:
    return TeacherService(TeacherRepository(db))


@router.post("/classes", response_model=ClassOut, status_code=201)
async def create_class(
    body: CreateClassIn,
    current_user: Annotated[User, Depends(require_role(UserRole.teacher))],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> ClassOut:
    svc = _svc(db)
    result = await svc.create_class(current_user.id, body.name)
    await db.commit()
    return result


@router.get("/classes", response_model=list[ClassOut])
async def list_classes(
    current_user: Annotated[User, Depends(require_role(UserRole.teacher))],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> list[ClassOut]:
    return await _svc(db).list_classes(current_user.id)


@router.post("/classes/join", response_model=ClassEnrollmentOut, status_code=201)
async def join_class(
    body: EnrollIn,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> ClassEnrollmentOut:
    """Parent uses this to enroll their child via join code."""
    if current_user.role not in (UserRole.parent, UserRole.teacher, UserRole.admin):
        from fastapi import HTTPException

        raise HTTPException(status_code=403, detail="Insufficient permissions")
    svc = _svc(db)
    result = await svc.join_class(body.join_code, body.child_id)
    await db.commit()
    return result


@router.post("/classes/{class_id}/assignments", response_model=AssignmentOut, status_code=201)
async def create_assignment(
    class_id: uuid.UUID,
    body: CreateAssignmentIn,
    current_user: Annotated[User, Depends(require_role(UserRole.teacher))],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> AssignmentOut:
    svc = _svc(db)
    result = await svc.create_assignment(class_id, current_user.id, body)
    await db.commit()
    return result


@router.get("/classes/{class_id}/assignments", response_model=list[AssignmentOut])
async def list_assignments(
    class_id: uuid.UUID,
    current_user: Annotated[User, Depends(require_role(UserRole.teacher))],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> list[AssignmentOut]:
    return await _svc(db).list_assignments(class_id, current_user.id)


@router.get("/classes/{class_id}/analytics", response_model=ClassAnalyticsOut)
async def get_class_analytics(
    class_id: uuid.UUID,
    current_user: Annotated[User, Depends(require_role(UserRole.teacher))],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> ClassAnalyticsOut:
    """Returns class analytics. Student summaries require separate progress lookups."""
    svc = _svc(db)
    # Auth check: teacher must own class
    await svc.assert_teacher_owns_class(class_id, current_user.id)
    # No student progress data available without the children module integration.
    # Router returns an empty roster; UI fetches per-student data separately.
    return await svc.get_class_analytics(class_id, current_user.id, [])
