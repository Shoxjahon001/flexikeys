from __future__ import annotations

import uuid
from datetime import UTC, datetime
from typing import Any

import structlog

from flexikeys.modules.notifications.repository import NotificationRepository

logger = structlog.get_logger()

# ── Localized notification templates ─────────────────────────────────────────
# Templates use {placeholder} format strings. Never target children —
# all recipients must be parents or teachers.

_TEMPLATES: dict[str, dict[str, dict[str, str]]] = {
    "weekly_report_ready": {
        "en": {
            "title": "Weekly Report Ready",
            "body": "{child_name}'s weekly report is ready to view.",
        },
        "uz": {
            "title": "Haftalik Hisobot Tayyor",
            "body": "{child_name}ning haftalik hisoboti ko'rish uchun tayyor.",
        },
        "ru": {
            "title": "Еженедельный отчёт готов",
            "body": "Еженедельный отчёт {child_name} готов к просмотру.",
        },
    },
    "streak_encouragement": {
        "en": {
            "title": "Great effort!",
            "body": "{child_name} has been practising for {streak_days} days in a row.",
        },
        "uz": {
            "title": "Zo'r harakat!",
            "body": "{child_name} {streak_days} kun ketma-ket mashq qildi.",
        },
        "ru": {
            "title": "Отличное усердие!",
            "body": "{child_name} занимается уже {streak_days} дней подряд.",
        },
    },
    "assignment_created": {
        "en": {
            "title": "New Assignment",
            "body": "A new assignment has been set for {child_name}.",
        },
        "uz": {
            "title": "Yangi Topshiriq",
            "body": "{child_name} uchun yangi topshiriq belgilandi.",
        },
        "ru": {
            "title": "Новое задание",
            "body": "Для {child_name} установлено новое задание.",
        },
    },
    "consent_request": {
        "en": {
            "title": "Teacher Access Request",
            "body": (
                "{teacher_name} has invited your child to join '{class_name}'. "
                "Review and respond in the app."
            ),
        },
        "uz": {
            "title": "O'qituvchi Ruxsat So'rovi",
            "body": (
                "{teacher_name} farzandingizni '{class_name}' ga taklif qildi. "
                "Ilovada ko'rib chiqing."
            ),
        },
        "ru": {
            "title": "Запрос доступа учителя",
            "body": (
                "{teacher_name} приглашает вашего ребёнка в '{class_name}'. "
                "Рассмотрите запрос в приложении."
            ),
        },
    },
}

# Child role sentinel — used to prevent child targeting
_CHILD_USER_ROLE_MARKER = "child_session"


def _render(kind: str, language: str, vars: dict[str, Any]) -> dict[str, str]:
    lang = language if language in ("en", "uz", "ru") else "en"
    templates = _TEMPLATES.get(kind, {})
    tmpl = templates.get(lang, templates.get("en", {"title": kind, "body": ""}))
    return {
        "title": tmpl["title"].format(**vars),
        "body": tmpl["body"].format(**vars),
    }


class NotificationService:
    def __init__(self, repo: NotificationRepository) -> None:
        self._repo = repo

    async def send(
        self,
        user_id: uuid.UUID,
        kind: str,
        payload: dict[str, Any],
        language: str = "en",
        *,
        is_child: bool = False,
    ) -> None:
        """Dispatch a notification. Children must NEVER be targeted."""
        if is_child:
            raise ValueError(
                "Notifications must never target the child experience. "
                f"user_id={user_id} kind={kind}"
            )

        prefs = await self._repo.get_preferences(user_id, kind)
        # Default: all channels enabled when no preference row exists.
        push_ok = prefs.push_enabled if prefs else True
        email_ok = prefs.email_enabled if prefs else True
        in_app_ok = prefs.in_app_enabled if prefs else True

        rendered = _render(kind, language, payload.get("vars", {}))
        merged_payload = {**payload, "rendered": rendered}

        if in_app_ok:
            await self._repo.create(
                user_id=user_id,
                kind=kind,
                payload=merged_payload,
                sent_at=datetime.now(UTC),
            )

        if push_ok:
            # STUB: #49 — replace with FCM/APNs push dispatch
            logger.info("push_notification_queued", user_id=str(user_id), kind=kind)

        if email_ok:
            # STUB: #50 — replace with email provider dispatch
            logger.info("email_notification_queued", user_id=str(user_id), kind=kind)

    async def send_weekly_report_ready(
        self,
        parent_id: uuid.UUID,
        child_name: str,
        report_id: uuid.UUID,
        ui_language: str = "en",
    ) -> None:
        await self.send(
            user_id=parent_id,
            kind="weekly_report_ready",
            payload={"report_id": str(report_id), "vars": {"child_name": child_name}},
            language=ui_language,
            is_child=False,
        )

    async def send_streak_encouragement(
        self,
        parent_id: uuid.UUID,
        child_name: str,
        streak_days: int,
        ui_language: str = "en",
    ) -> None:
        await self.send(
            user_id=parent_id,
            kind="streak_encouragement",
            payload={"vars": {"child_name": child_name, "streak_days": str(streak_days)}},
            language=ui_language,
            is_child=False,
        )

    async def send_assignment_event(
        self,
        parent_id: uuid.UUID,
        child_name: str,
        ui_language: str = "en",
    ) -> None:
        await self.send(
            user_id=parent_id,
            kind="assignment_created",
            payload={"vars": {"child_name": child_name}},
            language=ui_language,
            is_child=False,
        )

    async def send_consent_request(
        self,
        parent_id: uuid.UUID,
        teacher_name: str,
        class_name: str,
        ui_language: str = "en",
    ) -> None:
        await self.send(
            user_id=parent_id,
            kind="consent_request",
            payload={"vars": {"teacher_name": teacher_name, "class_name": class_name}},
            language=ui_language,
            is_child=False,
        )
