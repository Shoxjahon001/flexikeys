from __future__ import annotations

import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from flexikeys.core.db import get_db
from flexikeys.core.deps import get_current_user, require_role
from flexikeys.core.enums import UserRole
from flexikeys.modules.children.schemas import (
    ChildCreate,
    ChildOut,
    ChildSessionResponse,
    ChildUpdate,
    ConsentOut,
    ConsentRequest,
    ConsentTextResponse,
)
from flexikeys.modules.children.service import ChildrenService
from flexikeys.modules.users.models import User

router = APIRouter(prefix="/children", tags=["children"])

_CONSENT_TEXT: dict[str, str] = {
    "en": (
        "By adding a child profile, you confirm that you are the parent or legal guardian "
        "of the child, and you consent to the collection and processing of limited, "
        "pseudonymized activity data to personalize the learning experience. "
        "No personally identifiable information about the child is shared with third parties. "
        "You may withdraw consent at any time by deleting the child's profile."
    ),
    "uz": (
        "Bola profilini qo'shish orqali siz ushbu bolaning ota-onasi yoki qonuniy "
        "vasiysi ekanligingizni va o'quv tajribasini shaxsiylashtirish uchun cheklangan, "
        "psevdonimli faoliyat ma'lumotlarini to'plash va qayta ishlashga roziligingizni "
        "tasdiqlaysiz. Bola haqida shaxsan aniqlanadigan hech qanday ma'lumot uchinchi "
        "taraflarga berilmaydi. Bolaning profilini o'chirib tashlash orqali istalgan vaqtda "
        "rozilikni bekor qilishingiz mumkin."
    ),
    "ru": (
        "Добавляя профиль ребёнка, вы подтверждаете, что являетесь родителем или "
        "законным представителем ребёнка, и соглашаетесь на сбор и обработку "
        "ограниченных, псевдонимизированных данных об активности для персонализации "
        "обучения. Персонально идентифицируемая информация о ребёнке третьим лицам "
        "не передаётся. Вы можете отозвать согласие в любое время, удалив профиль ребёнка."
    ),
}
_CONSENT_VERSION = "1.0"


@router.get("/consent-text", response_model=ConsentTextResponse)
async def get_consent_text(lang: str = Query(default="en")) -> ConsentTextResponse:
    text = _CONSENT_TEXT.get(lang, _CONSENT_TEXT["en"])
    return ConsentTextResponse(lang=lang, text=text, version=_CONSENT_VERSION)


@router.post("", response_model=ChildOut, status_code=201)
async def create_child(
    body: ChildCreate,
    user: Annotated[User, Depends(require_role(UserRole.parent))],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> ChildOut:
    svc = ChildrenService(db)
    child = await svc.create_child(
        parent_id=user.id,
        display_name=body.display_name,
        learning_language=body.learning_language,
        ui_language=body.ui_language,
        birth_year=body.birth_year,
        avatar_id=body.avatar_id,
    )
    await db.commit()
    return ChildOut.model_validate(child)


@router.get("", response_model=list[ChildOut])
async def list_children(
    user: Annotated[User, Depends(require_role(UserRole.parent))],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> list[ChildOut]:
    svc = ChildrenService(db)
    children = await svc.list_children(user.id)
    return [ChildOut.model_validate(c) for c in children]


@router.patch("/{child_id}", response_model=ChildOut)
async def update_child(
    child_id: uuid.UUID,
    body: ChildUpdate,
    user: Annotated[User, Depends(require_role(UserRole.parent))],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> ChildOut:
    updates = body.model_dump(exclude_none=True)
    svc = ChildrenService(db)
    child = await svc.update_child(child_id, user.id, **updates)
    await db.commit()
    return ChildOut.model_validate(child)


@router.post("/{child_id}/session", response_model=ChildSessionResponse)
async def create_child_session(
    child_id: uuid.UUID,
    user: Annotated[User, Depends(require_role(UserRole.parent))],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> ChildSessionResponse:
    svc = ChildrenService(db)
    token = await svc.create_session_token(child_id, user.id)
    return ChildSessionResponse(child_token=token)


@router.post("/{child_id}/consent", response_model=ConsentOut, status_code=201)
async def record_consent(
    child_id: uuid.UUID,
    body: ConsentRequest,
    user: Annotated[User, Depends(require_role(UserRole.parent))],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> ConsentOut:
    svc = ChildrenService(db)
    consent = await svc.record_consent(child_id, user.id, body.consent_type)
    await db.commit()
    return ConsentOut.model_validate(consent)