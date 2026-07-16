from __future__ import annotations

import json
import uuid
from datetime import UTC, datetime, timedelta
from typing import Any

import httpx
from fastapi import HTTPException
from jose import JWTError
from jose import jwt as jose_jwt
from redis.asyncio import Redis

from flexikeys.core.config import get_settings
from flexikeys.core.enums import OAuthProvider, UserRole
from flexikeys.core.security import (
    create_access_token,
    create_email_verification_token,
    create_password_reset_token,
    create_refresh_token,
    decode_token,
    hash_password,
    hash_token,
    verify_password,
)
from flexikeys.modules.auth.repository import AuthRepository
from flexikeys.services.notifications import ConsoleNotificationService

_JWKS_CACHE_TTL = 3600

_PROVIDER_CONFIG: dict[OAuthProvider, dict[str, str]] = {
    OAuthProvider.google: {
        "jwks_url": "https://www.googleapis.com/oauth2/v3/certs",
        "issuer": "accounts.google.com",
    },
    OAuthProvider.apple: {
        "jwks_url": "https://appleid.apple.com/auth/keys",
        "issuer": "https://appleid.apple.com",
    },
}

# Argon2 dummy hash for constant-time comparison when user is not found.
# Prevents timing-based user enumeration.
_DUMMY_HASH = "$argon2id$v=19$m=65536,t=2,p=2$c29tZXNhbHQ$AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"


async def _fetch_jwks(jwks_url: str, redis: Redis) -> dict[str, Any]:  # type: ignore[type-arg]
    """Fetch provider JWKS with Redis cache (1-hour TTL)."""
    cache_key = f"jwks:{jwks_url}"
    cached = await redis.get(cache_key)
    if cached:
        return json.loads(cached)  # type: ignore[return-value]
    async with httpx.AsyncClient(timeout=10.0) as client:
        resp = await client.get(jwks_url)
        resp.raise_for_status()
        data: dict[str, Any] = resp.json()
    await redis.setex(cache_key, _JWKS_CACHE_TTL, json.dumps(data))
    return data


async def _verify_provider_token(
    provider: OAuthProvider,
    id_token: str,
    redis: Redis,  # type: ignore[type-arg]
) -> dict[str, Any]:
    """Verify an OAuth provider id_token against cached JWKS. Returns decoded claims."""
    settings = get_settings()
    config = _PROVIDER_CONFIG[provider]
    client_id = (
        settings.google_client_id
        if provider == OAuthProvider.google
        else settings.apple_client_id
    )
    if not client_id:
        raise HTTPException(
            status_code=400, detail=f"{provider.value} OAuth is not configured"
        )

    jwks_data = await _fetch_jwks(config["jwks_url"], redis)

    try:
        header = jose_jwt.get_unverified_header(id_token)
    except JWTError as exc:
        raise HTTPException(status_code=401, detail="Invalid provider token") from exc

    kid = header.get("kid")
    alg = header.get("alg", "RS256")
    matching_key: dict[str, Any] | None = None
    for k in jwks_data.get("keys", []):
        if k.get("kid") == kid:
            matching_key = k
            break
    if matching_key is None and jwks_data.get("keys"):
        matching_key = jwks_data["keys"][0]
    if matching_key is None:
        raise HTTPException(status_code=401, detail="Invalid provider token")

    try:
        claims: dict[str, Any] = jose_jwt.decode(
            id_token, matching_key, algorithms=[alg], audience=client_id
        )
    except JWTError as exc:
        raise HTTPException(status_code=401, detail="Invalid provider token") from exc

    return claims


class AuthService:
    def __init__(
        self,
        repo: AuthRepository,
        redis: Redis,  # type: ignore[type-arg]
        notifications: ConsoleNotificationService,
    ) -> None:
        self._repo = repo
        self._redis = redis
        self._notifications = notifications

    def _issue_tokens(
        self, user_id: uuid.UUID, role: UserRole
    ) -> tuple[str, str, datetime]:
        settings = get_settings()
        access = create_access_token(str(user_id), role.value)
        refresh_raw = create_refresh_token(str(user_id))
        expires_at = datetime.now(UTC) + timedelta(days=settings.jwt_refresh_token_expire_days)
        return access, refresh_raw, expires_at

    async def register(
        self, email: str, password: str, role: UserRole, locale: str
    ) -> tuple[str, str]:
        existing = await self._repo.get_user_by_email(email)
        if existing is not None:
            raise HTTPException(status_code=409, detail="Email already registered")
        pw_hash = hash_password(password)
        user = await self._repo.create_user(email, pw_hash, role, locale)
        access, refresh_raw, expires_at = self._issue_tokens(user.id, role)
        await self._repo.create_refresh_token(
            user.id, hash_token(refresh_raw), None, expires_at
        )
        try:
            token = create_email_verification_token(str(user.id))
            await self._notifications.send_email_verification(email, token)
        except Exception:  # noqa: BLE001
            pass
        return access, refresh_raw

    async def login(
        self, email: str, password: str, device_info: str | None
    ) -> tuple[str, str]:
        user = await self._repo.get_user_by_email(email)
        stored_hash = user.password_hash if (user and user.password_hash) else _DUMMY_HASH
        valid = verify_password(password, stored_hash)
        if not valid or user is None:
            raise HTTPException(status_code=401, detail="Invalid credentials")
        access, refresh_raw, expires_at = self._issue_tokens(user.id, user.role)
        await self._repo.create_refresh_token(
            user.id, hash_token(refresh_raw), device_info, expires_at
        )
        return access, refresh_raw

    async def refresh(
        self, refresh_token_raw: str, device_info: str | None
    ) -> tuple[str, str]:
        try:
            claims = decode_token(refresh_token_raw)
        except JWTError as exc:
            raise HTTPException(status_code=401, detail="Invalid refresh token") from exc
        if claims.get("type") != "refresh":
            raise HTTPException(status_code=401, detail="Invalid token type")

        token_hash = hash_token(refresh_token_raw)
        stored = await self._repo.get_token_by_hash(token_hash)
        if stored is None:
            raise HTTPException(status_code=401, detail="Token not found")
        if stored.revoked_at is not None:
            # Refresh token reuse detected — revoke the entire family
            await self._repo.revoke_all_user_tokens(stored.user_id)
            raise HTTPException(status_code=401, detail="Refresh token reuse detected")

        await self._repo.revoke_token(stored)
        user = await self._repo.get_user_by_id(stored.user_id)
        if user is None:
            raise HTTPException(status_code=401, detail="User not found")

        access, new_refresh_raw, expires_at = self._issue_tokens(user.id, user.role)
        await self._repo.create_refresh_token(
            user.id, hash_token(new_refresh_raw), device_info, expires_at
        )
        return access, new_refresh_raw

    async def logout(self, refresh_token_raw: str) -> None:
        try:
            claims = decode_token(refresh_token_raw)
        except JWTError:
            return
        if claims.get("type") != "refresh":
            return
        token_hash = hash_token(refresh_token_raw)
        stored = await self._repo.get_token_by_hash(token_hash)
        if stored and stored.revoked_at is None:
            await self._repo.revoke_token(stored)

    async def oauth_authenticate(
        self,
        provider: OAuthProvider,
        id_token_raw: str,
        role: UserRole,
        device_info: str | None,
    ) -> tuple[str, str]:
        claims = await _verify_provider_token(provider, id_token_raw, self._redis)
        email: str = claims.get("email", "")
        sub: str = claims.get("sub", "")
        email_verified_claim: bool = bool(claims.get("email_verified", False))

        identity = await self._repo.get_oauth_identity(provider, sub)
        if identity is not None:
            user = await self._repo.get_user_by_id(identity.user_id)
            if user is None:
                raise HTTPException(status_code=401, detail="Account not found")
        else:
            user = await self._repo.get_user_by_email(email) if email else None
            if user is None:
                if not email:
                    raise HTTPException(
                        status_code=400, detail="Provider did not return email"
                    )
                user = await self._repo.create_user(email, None, role)
                if email_verified_claim:
                    await self._repo.mark_email_verified(user.id)
            await self._repo.create_oauth_identity(user.id, provider, sub)

        access, refresh_raw, expires_at = self._issue_tokens(user.id, user.role)
        await self._repo.create_refresh_token(
            user.id, hash_token(refresh_raw), device_info, expires_at
        )
        return access, refresh_raw

    async def forgot_password(self, email: str) -> None:
        user = await self._repo.get_user_by_email(email)
        if user is None:
            return  # don't reveal whether the email exists
        token = create_password_reset_token(str(user.id))
        await self._notifications.send_password_reset(email, token)

    async def reset_password(self, token: str, new_password: str) -> None:
        try:
            claims = decode_token(token)
        except JWTError as exc:
            raise HTTPException(
                status_code=400, detail="Invalid or expired reset token"
            ) from exc
        if claims.get("type") != "password_reset":
            raise HTTPException(status_code=400, detail="Invalid token type")
        user_id = uuid.UUID(claims["sub"])
        pw_hash = hash_password(new_password)
        await self._repo.update_password(user_id, pw_hash)
        await self._repo.revoke_all_user_tokens(user_id)

    async def verify_email(self, token: str) -> None:
        try:
            claims = decode_token(token)
        except JWTError as exc:
            raise HTTPException(
                status_code=400, detail="Invalid or expired verification token"
            ) from exc
        if claims.get("type") != "email_verify":
            raise HTTPException(status_code=400, detail="Invalid token type")
        await self._repo.mark_email_verified(uuid.UUID(claims["sub"]))