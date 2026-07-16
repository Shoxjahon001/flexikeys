from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, field_validator

from flexikeys.core.enums import UserRole


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    role: UserRole = UserRole.parent
    locale: str = "en"
    device_info: str | None = None

    @field_validator("password")
    @classmethod
    def _password_strength(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters")
        return v


class LoginRequest(BaseModel):
    email: EmailStr
    password: str
    device_info: str | None = None


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class RefreshRequest(BaseModel):
    refresh_token: str
    device_info: str | None = None


class LogoutRequest(BaseModel):
    refresh_token: str


class OAuthRequest(BaseModel):
    id_token: str
    role: UserRole = UserRole.parent
    device_info: str | None = None


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    token: str
    new_password: str

    @field_validator("new_password")
    @classmethod
    def _password_strength(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters")
        return v


class VerifyEmailRequest(BaseModel):
    token: str


class UserOut(BaseModel):
    id: uuid.UUID
    email: str | None
    role: UserRole
    locale: str
    timezone: str
    email_verified: bool
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)