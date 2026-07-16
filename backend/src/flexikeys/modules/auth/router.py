from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from flexikeys.core.db import get_db
from flexikeys.core.enums import OAuthProvider
from flexikeys.core.rate_limit import auth_rate_limit
from flexikeys.core.redis import get_redis
from flexikeys.modules.auth.repository import AuthRepository
from flexikeys.modules.auth.schemas import (
    ForgotPasswordRequest,
    LogoutRequest,
    OAuthRequest,
    RefreshRequest,
    RegisterRequest,
    LoginRequest,
    ResetPasswordRequest,
    TokenResponse,
    VerifyEmailRequest,
)
from flexikeys.modules.auth.service import AuthService
from flexikeys.services.notifications import get_notification_service

router = APIRouter(prefix="/auth", tags=["auth"])


def _build_service(db: AsyncSession, redis: object) -> AuthService:
    return AuthService(
        repo=AuthRepository(db),
        redis=redis,  # type: ignore[arg-type]
        notifications=get_notification_service(),
    )


@router.post(
    "/register",
    response_model=TokenResponse,
    status_code=201,
    dependencies=[Depends(auth_rate_limit)],
)
async def register(
    body: RegisterRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    redis: Annotated[object, Depends(get_redis)],
) -> TokenResponse:
    svc = _build_service(db, redis)
    access, refresh = await svc.register(body.email, body.password, body.role, body.locale)
    await db.commit()
    return TokenResponse(access_token=access, refresh_token=refresh)


@router.post(
    "/login",
    response_model=TokenResponse,
    dependencies=[Depends(auth_rate_limit)],
)
async def login(
    body: LoginRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    redis: Annotated[object, Depends(get_redis)],
) -> TokenResponse:
    svc = _build_service(db, redis)
    access, refresh = await svc.login(body.email, body.password, body.device_info)
    await db.commit()
    return TokenResponse(access_token=access, refresh_token=refresh)


@router.post(
    "/refresh",
    response_model=TokenResponse,
    dependencies=[Depends(auth_rate_limit)],
)
async def refresh(
    body: RefreshRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    redis: Annotated[object, Depends(get_redis)],
) -> TokenResponse:
    svc = _build_service(db, redis)
    access, new_refresh = await svc.refresh(body.refresh_token, body.device_info)
    await db.commit()
    return TokenResponse(access_token=access, refresh_token=new_refresh)


@router.post("/logout", status_code=204, dependencies=[Depends(auth_rate_limit)])
async def logout(
    body: LogoutRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    redis: Annotated[object, Depends(get_redis)],
) -> None:
    svc = _build_service(db, redis)
    await svc.logout(body.refresh_token)
    await db.commit()


@router.post(
    "/oauth/{provider}",
    response_model=TokenResponse,
    dependencies=[Depends(auth_rate_limit)],
)
async def oauth(
    provider: OAuthProvider,
    body: OAuthRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    redis: Annotated[object, Depends(get_redis)],
) -> TokenResponse:
    svc = _build_service(db, redis)
    access, refresh_raw = await svc.oauth_authenticate(
        provider, body.id_token, body.role, body.device_info
    )
    await db.commit()
    return TokenResponse(access_token=access, refresh_token=refresh_raw)


@router.post(
    "/password/forgot",
    status_code=202,
    dependencies=[Depends(auth_rate_limit)],
)
async def forgot_password(
    body: ForgotPasswordRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    redis: Annotated[object, Depends(get_redis)],
) -> None:
    svc = _build_service(db, redis)
    await svc.forgot_password(body.email)


@router.post(
    "/password/reset",
    status_code=204,
    dependencies=[Depends(auth_rate_limit)],
)
async def reset_password(
    body: ResetPasswordRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    redis: Annotated[object, Depends(get_redis)],
) -> None:
    svc = _build_service(db, redis)
    await svc.reset_password(body.token, body.new_password)
    await db.commit()


@router.post("/verify-email", status_code=204, dependencies=[Depends(auth_rate_limit)])
async def verify_email(
    body: VerifyEmailRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    redis: Annotated[object, Depends(get_redis)],
) -> None:
    svc = _build_service(db, redis)
    await svc.verify_email(body.token)
    await db.commit()