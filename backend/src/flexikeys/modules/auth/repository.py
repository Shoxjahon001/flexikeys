from __future__ import annotations

import uuid
from datetime import UTC, datetime
from typing import Any

from sqlalchemy import and_, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from flexikeys.core.enums import OAuthProvider, UserRole
from flexikeys.modules.auth.models import ParentalConsent, RefreshToken
from flexikeys.modules.users.models import OAuthIdentity, User


class AuthRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._s = session

    # ── Users ─────────────────────────────────────────────────────────────────

    async def get_user_by_email(self, email: str) -> User | None:
        result = await self._s.execute(
            select(User).where(and_(User.email == email, User.deleted_at.is_(None)))
        )
        return result.scalar_one_or_none()

    async def get_user_by_id(self, user_id: uuid.UUID) -> User | None:
        result = await self._s.execute(
            select(User).where(and_(User.id == user_id, User.deleted_at.is_(None)))
        )
        return result.scalar_one_or_none()

    async def create_user(
        self,
        email: str,
        password_hash: str | None,
        role: UserRole,
        locale: str = "en",
    ) -> User:
        user = User(
            id=uuid.uuid4(),
            email=email,
            password_hash=password_hash,
            role=role,
            locale=locale,
            email_verified=False,
        )
        self._s.add(user)
        await self._s.flush()
        return user

    async def mark_email_verified(self, user_id: uuid.UUID) -> None:
        await self._s.execute(
            update(User)
            .where(User.id == user_id)
            .values(email_verified=True, email_verified_at=datetime.now(UTC))
        )

    async def update_password(self, user_id: uuid.UUID, password_hash: str) -> None:
        await self._s.execute(
            update(User)
            .where(User.id == user_id)
            .values(password_hash=password_hash, updated_at=datetime.now(UTC))
        )

    async def update_user(self, user: User, **kwargs: Any) -> User:
        for k, v in kwargs.items():
            setattr(user, k, v)
        user.updated_at = datetime.now(UTC)
        await self._s.flush()
        return user

    # ── OAuth identities ──────────────────────────────────────────────────────

    async def get_oauth_identity(
        self, provider: OAuthProvider, provider_subject: str
    ) -> OAuthIdentity | None:
        result = await self._s.execute(
            select(OAuthIdentity).where(
                and_(
                    OAuthIdentity.provider == provider,
                    OAuthIdentity.provider_subject == provider_subject,
                )
            )
        )
        return result.scalar_one_or_none()

    async def create_oauth_identity(
        self, user_id: uuid.UUID, provider: OAuthProvider, provider_subject: str
    ) -> OAuthIdentity:
        identity = OAuthIdentity(
            id=uuid.uuid4(),
            user_id=user_id,
            provider=provider,
            provider_subject=provider_subject,
        )
        self._s.add(identity)
        await self._s.flush()
        return identity

    # ── Refresh tokens ────────────────────────────────────────────────────────

    async def create_refresh_token(
        self,
        user_id: uuid.UUID,
        token_hash: str,
        device_info: str | None,
        expires_at: datetime,
    ) -> RefreshToken:
        token = RefreshToken(
            id=uuid.uuid4(),
            user_id=user_id,
            token_hash=token_hash,
            device_info=device_info,
            expires_at=expires_at,
        )
        self._s.add(token)
        await self._s.flush()
        return token

    async def get_token_by_hash(self, token_hash: str) -> RefreshToken | None:
        result = await self._s.execute(
            select(RefreshToken).where(RefreshToken.token_hash == token_hash)
        )
        return result.scalar_one_or_none()

    async def revoke_token(self, token: RefreshToken) -> None:
        token.revoked_at = datetime.now(UTC)
        await self._s.flush()

    async def revoke_all_user_tokens(self, user_id: uuid.UUID) -> None:
        await self._s.execute(
            update(RefreshToken)
            .where(
                and_(
                    RefreshToken.user_id == user_id,
                    RefreshToken.revoked_at.is_(None),
                )
            )
            .values(revoked_at=datetime.now(UTC))
        )

    # ── Parental consent ──────────────────────────────────────────────────────

    async def create_consent(
        self,
        child_id: uuid.UUID,
        consent_type: Any,
        granted_at: datetime,
    ) -> ParentalConsent:
        consent = ParentalConsent(
            id=uuid.uuid4(),
            child_id=child_id,
            consent_type=consent_type,
            granted_at=granted_at,
        )
        self._s.add(consent)
        await self._s.flush()
        return consent