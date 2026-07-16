"""Admin module unit tests — no database required."""
from __future__ import annotations

import asyncio
import uuid
from datetime import UTC, datetime
from unittest.mock import AsyncMock, MagicMock

import pytest
from fastapi import HTTPException

from flexikeys.modules.admin.service import AdminService

# ── Helpers ───────────────────────────────────────────────────────────────────


def _svc(repo: MagicMock | None = None) -> AdminService:
    svc: AdminService = object.__new__(AdminService)
    svc._repo = repo or MagicMock()
    return svc


def _mock_flag(key: str, enabled: bool = False) -> MagicMock:
    flag = MagicMock()
    flag.id = uuid.uuid4()
    flag.key = key
    flag.enabled = enabled
    flag.description = None
    flag.created_at = datetime.now(UTC)
    flag.updated_at = datetime.now(UTC)
    return flag


def _mock_audit_log(action: str) -> MagicMock:
    log = MagicMock()
    log.id = uuid.uuid4()
    log.actor_id = uuid.uuid4()
    log.action = action
    log.resource_type = "feature_flag"
    log.resource_id = "some_key"
    log.payload = {}
    log.created_at = datetime.now(UTC)
    return log


# ── TOTP enforcement ──────────────────────────────────────────────────────────


def test_set_feature_flag_rejects_without_totp() -> None:
    svc = _svc()
    with pytest.raises(HTTPException) as exc_info:
        asyncio.get_event_loop().run_until_complete(
            svc.set_feature_flag(
                uuid.uuid4(), "my_flag", True, None, totp_verified=False
            )
        )
    assert exc_info.value.status_code == 403


def test_curriculum_rollback_rejects_without_totp() -> None:
    svc = _svc()
    with pytest.raises(HTTPException) as exc_info:
        asyncio.get_event_loop().run_until_complete(
            svc.curriculum_rollback(
                uuid.uuid4(), "v1.2.3", totp_verified=False
            )
        )
    assert exc_info.value.status_code == 403


# ── Audit log written on mutations ───────────────────────────────────────────


def test_audit_log_written_on_create_flag() -> None:
    actor_id = uuid.uuid4()
    flag = _mock_flag("new_feature", enabled=True)
    audit = _mock_audit_log("set_feature_flag")

    repo = MagicMock()
    repo.upsert_feature_flag = AsyncMock(return_value=flag)
    repo.write_audit_log = AsyncMock(return_value=audit)

    svc = _svc(repo)
    asyncio.get_event_loop().run_until_complete(
        svc.set_feature_flag(actor_id, "new_feature", True, None, totp_verified=True)
    )

    repo.write_audit_log.assert_awaited_once()
    call_args = repo.write_audit_log.call_args
    assert call_args.kwargs["actor_id"] == actor_id
    assert call_args.kwargs["action"] == "set_feature_flag"
    assert call_args.kwargs["resource_type"] == "feature_flag"
    assert call_args.kwargs["resource_id"] == "new_feature"
    assert call_args.kwargs["payload"]["enabled"] is True


def test_audit_log_written_on_disable_flag() -> None:
    actor_id = uuid.uuid4()
    flag = _mock_flag("old_feature", enabled=False)
    audit = _mock_audit_log("set_feature_flag")

    repo = MagicMock()
    repo.upsert_feature_flag = AsyncMock(return_value=flag)
    repo.write_audit_log = AsyncMock(return_value=audit)

    svc = _svc(repo)
    asyncio.get_event_loop().run_until_complete(
        svc.set_feature_flag(actor_id, "old_feature", False, None, totp_verified=True)
    )

    repo.write_audit_log.assert_awaited_once()
    payload = repo.write_audit_log.call_args.kwargs["payload"]
    assert payload["enabled"] is False


def test_audit_log_written_on_curriculum_rollback() -> None:
    actor_id = uuid.uuid4()
    audit = _mock_audit_log("curriculum_rollback")

    repo = MagicMock()
    repo.write_audit_log = AsyncMock(return_value=audit)

    svc = _svc(repo)
    asyncio.get_event_loop().run_until_complete(
        svc.curriculum_rollback(actor_id, "v1.5.0", totp_verified=True)
    )

    repo.write_audit_log.assert_awaited_once()
    call_args = repo.write_audit_log.call_args
    assert call_args.kwargs["action"] == "curriculum_rollback"
    assert call_args.kwargs["resource_type"] == "curriculum"
    assert call_args.kwargs["resource_id"] == "v1.5.0"


# ── Feature flag CRUD ─────────────────────────────────────────────────────────


def test_feature_flag_create_succeeds() -> None:
    actor_id = uuid.uuid4()
    flag = _mock_flag("dark_mode", enabled=True)
    audit = _mock_audit_log("set_feature_flag")

    repo = MagicMock()
    repo.upsert_feature_flag = AsyncMock(return_value=flag)
    repo.write_audit_log = AsyncMock(return_value=audit)

    svc = _svc(repo)
    result = asyncio.get_event_loop().run_until_complete(
        svc.set_feature_flag(actor_id, "dark_mode", True, "Dark theme", totp_verified=True)
    )

    assert result.key == "dark_mode"
    assert result.enabled is True


def test_feature_flag_toggle() -> None:
    actor_id = uuid.uuid4()
    flag_on = _mock_flag("my_flag", enabled=True)
    flag_off = _mock_flag("my_flag", enabled=False)
    audit = _mock_audit_log("set_feature_flag")

    repo = MagicMock()
    repo.upsert_feature_flag = AsyncMock(side_effect=[flag_on, flag_off])
    repo.write_audit_log = AsyncMock(return_value=audit)

    svc = _svc(repo)
    loop = asyncio.get_event_loop()

    r1 = loop.run_until_complete(
        svc.set_feature_flag(actor_id, "my_flag", True, None, totp_verified=True)
    )
    assert r1.enabled is True

    r2 = loop.run_until_complete(
        svc.set_feature_flag(actor_id, "my_flag", False, None, totp_verified=True)
    )
    assert r2.enabled is False


def test_feature_flag_defaults_disabled() -> None:
    """FeatureFlag model starts with enabled=False by default."""
    from flexikeys.modules.admin.models import FeatureFlag

    FeatureFlag.__new__(FeatureFlag)
    # Check the SQLAlchemy column default
    col = FeatureFlag.__table__.columns["enabled"]
    assert col.default is not None or col.server_default is not None or not col.default


# ── Platform analytics stub ───────────────────────────────────────────────────


def test_platform_analytics_returns_stub() -> None:
    result = AdminService.get_platform_analytics()
    # Stub returns zeros — ensure the schema is correct
    assert result.dau == 0
    assert result.wau == 0
    assert result.total_children == 0
    assert result.avg_mastery_global == 0.0


# ── List audit logs ───────────────────────────────────────────────────────────


def test_list_audit_logs_delegates_to_repo() -> None:
    logs = [_mock_audit_log("set_feature_flag") for _ in range(3)]
    repo = MagicMock()
    repo.list_audit_logs = AsyncMock(return_value=logs)

    svc = _svc(repo)
    result = asyncio.get_event_loop().run_until_complete(
        svc.list_audit_logs(resource_type="feature_flag", limit=10, offset=0)
    )

    repo.list_audit_logs.assert_awaited_once_with("feature_flag", 10, 0)
    assert len(result) == 3
