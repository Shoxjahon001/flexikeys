from __future__ import annotations

import hashlib
import secrets
from datetime import UTC, datetime, timedelta
from typing import Any

from jose import JWTError, jwt
from passlib.context import CryptContext

from flexikeys.core.config import get_settings

# Argon2id params: time_cost=2, memory_cost=64MiB, parallelism=2
# Meets OWASP ASVS L2 minimum for interactive logins.
_pwd_context = CryptContext(
    schemes=["argon2"],
    deprecated="auto",
    argon2__time_cost=2,
    argon2__memory_cost=65536,
    argon2__parallelism=2,
)


def hash_password(plain: str) -> str:
    return _pwd_context.hash(plain)


def verify_password(plain: str, hashed: str) -> bool:
    return _pwd_context.verify(plain, hashed)


def hash_token(token: str) -> str:
    """SHA-256 of a high-entropy random token for at-rest storage."""
    return hashlib.sha256(token.encode()).hexdigest()


def generate_opaque_token() -> str:
    """Cryptographically secure 32-byte hex token (64 chars)."""
    return secrets.token_hex(32)


def _make_token(data: dict[str, Any], expires_delta: timedelta) -> str:
    settings = get_settings()
    payload = data | {"exp": datetime.now(UTC) + expires_delta}
    return jwt.encode(payload, settings.app_secret_key, algorithm=settings.jwt_algorithm)


def create_access_token(subject: str, role: str) -> str:
    settings = get_settings()
    return _make_token(
        {"sub": subject, "type": "access", "role": role},
        timedelta(minutes=settings.jwt_access_token_expire_minutes),
    )


def create_refresh_token(subject: str) -> str:
    settings = get_settings()
    return _make_token(
        {"sub": subject, "type": "refresh", "jti": secrets.token_hex(16)},
        timedelta(days=settings.jwt_refresh_token_expire_days),
    )


def create_child_session_token(child_id: str, parent_id: str, lang: str) -> str:
    settings = get_settings()
    return _make_token(
        {
            "sub": child_id,
            "type": "child_session",
            "parent_id": parent_id,
            "lang": lang,
        },
        timedelta(hours=settings.child_session_token_expire_hours),
    )


def create_email_verification_token(user_id: str) -> str:
    return _make_token({"sub": user_id, "type": "email_verify"}, timedelta(hours=24))


def create_password_reset_token(user_id: str) -> str:
    return _make_token({"sub": user_id, "type": "password_reset"}, timedelta(minutes=15))


def decode_token(token: str) -> dict[str, Any]:
    """Decode and verify a JWT. Raises JWTError on invalid or expired token."""
    settings = get_settings()
    return jwt.decode(token, settings.app_secret_key, algorithms=[settings.jwt_algorithm])


__all__ = [
    "hash_password",
    "verify_password",
    "hash_token",
    "generate_opaque_token",
    "create_access_token",
    "create_refresh_token",
    "create_child_session_token",
    "create_email_verification_token",
    "create_password_reset_token",
    "decode_token",
]