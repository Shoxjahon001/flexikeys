from __future__ import annotations

from functools import lru_cache
from typing import Annotated, Literal

from pydantic import field_validator
from pydantic_settings import BaseSettings, NoDecode, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # App
    app_env: Literal["development", "staging", "production"] = "development"
    app_secret_key: str
    app_debug: bool = False

    # Database
    database_url: str

    # Redis
    redis_url: str = "redis://localhost:6379/0"

    # JWT
    jwt_algorithm: str = "HS256"
    jwt_access_token_expire_minutes: int = 15
    jwt_refresh_token_expire_days: int = 30
    child_session_token_expire_hours: int = 8

    # Supabase — parent auth is owned by Supabase; this backend only
    # verifies the access token it issues. Value is the project's JWT
    # Secret (Supabase dashboard: Settings -> API -> JWT Settings), not the
    # anon/publishable key.
    supabase_jwt_secret: str = ""

    # CORS
    # NoDecode: pydantic-settings would otherwise try to json.loads() the raw
    # env string before this validator runs, which breaks on a plain CSV value.
    cors_origins: Annotated[list[str], NoDecode] = []

    @field_validator("cors_origins", mode="before")
    @classmethod
    def _split_cors(cls, v: str | list[str]) -> list[str]:
        if isinstance(v, str):
            return [o.strip() for o in v.split(",") if o.strip()]
        return v

    # OAuth providers — credentials from env, never hardcoded
    google_client_id: str = ""
    apple_client_id: str = ""

    # Storage
    storage_endpoint: str = "http://localhost:9000"
    storage_access_key: str = "minioadmin"
    storage_secret_key: str = "minioadmin"
    storage_bucket: str = "flexikeys"
    storage_public_url: str = "http://localhost:9000/flexikeys"

    # AI Assistant
    ai_provider: Literal["stub", "openai", "anthropic"] = "stub"
    ai_api_key: str = ""
    ai_model: str = ""

    # Azure Speech (AAC neural TTS) — empty means the /aac/tts endpoint
    # returns 503 and the Flutter client falls back to on-device TTS.
    azure_speech_key: str = ""
    azure_speech_region: str = ""

    # Observability
    log_level: str = "INFO"
    sentry_dsn: str = ""

    # Rate limiting
    rate_limit_auth: str = "20/minute"
    rate_limit_default: str = "200/minute"

    @property
    def is_production(self) -> bool:
        return self.app_env == "production"

    @property
    def is_development(self) -> bool:
        return self.app_env == "development"


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()  # type: ignore[call-arg]
