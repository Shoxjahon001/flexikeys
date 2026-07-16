from __future__ import annotations

from typing import Protocol, runtime_checkable

import structlog

logger = structlog.get_logger()


@runtime_checkable
class NotificationService(Protocol):
    async def send_email_verification(self, user_email: str, token: str) -> None: ...
    async def send_password_reset(self, user_email: str, token: str) -> None: ...


class ConsoleNotificationService:
    """
    # STUB: #1 — replace with real SMTP/SendGrid email transport.
    # See: https://github.com/flexikeys/flexikeys/issues/1
    Logs intent to console only; tokens are intentionally omitted from logs.
    """

    async def send_email_verification(self, user_email: str, token: str) -> None:
        logger.info("email_verification_queued", email=user_email)
        # token not logged — contains sensitive material

    async def send_password_reset(self, user_email: str, token: str) -> None:
        logger.info("password_reset_queued", email=user_email)
        # token not logged — contains sensitive material


def get_notification_service() -> ConsoleNotificationService:
    return ConsoleNotificationService()
