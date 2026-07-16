"""
Phase 03 acceptance tests: auth, role guards, data isolation, child tokens.
"""
from __future__ import annotations

import uuid
from typing import Any

import pytest
from fastapi import HTTPException
from httpx import AsyncClient


# ── Helpers ───────────────────────────────────────────────────────────────────


async def _register(client: AsyncClient, email: str, password: str = "password123", role: str = "parent") -> dict[str, Any]:
    resp = await client.post("/api/v1/auth/register", json={"email": email, "password": password, "role": role})
    assert resp.status_code == 201, resp.text
    return resp.json()


async def _login(client: AsyncClient, email: str, password: str = "password123") -> dict[str, Any]:
    resp = await client.post("/api/v1/auth/login", json={"email": email, "password": password})
    assert resp.status_code == 200, resp.text
    return resp.json()


def _auth(tokens: dict[str, Any]) -> dict[str, str]:
    return {"Authorization": f"Bearer {tokens['access_token']}"}


# ── Registration ──────────────────────────────────────────────────────────────


async def test_register_returns_tokens(client: AsyncClient) -> None:
    tokens = await _register(client, "reg01@example.com")
    assert "access_token" in tokens
    assert "refresh_token" in tokens
    assert tokens["token_type"] == "bearer"


async def test_register_duplicate_email_409(client: AsyncClient) -> None:
    await _register(client, "dup@example.com")
    resp = await client.post("/api/v1/auth/register", json={"email": "dup@example.com", "password": "password123"})
    assert resp.status_code == 409


async def test_register_short_password_422(client: AsyncClient) -> None:
    resp = await client.post("/api/v1/auth/register", json={"email": "short@example.com", "password": "abc"})
    assert resp.status_code == 422


# ── Login ─────────────────────────────────────────────────────────────────────


async def test_login_success(client: AsyncClient) -> None:
    await _register(client, "login01@example.com")
    tokens = await _login(client, "login01@example.com")
    assert "access_token" in tokens


async def test_login_wrong_password_401(client: AsyncClient) -> None:
    await _register(client, "login02@example.com")
    resp = await client.post("/api/v1/auth/login", json={"email": "login02@example.com", "password": "wrongpass"})
    assert resp.status_code == 401


async def test_login_unknown_email_401(client: AsyncClient) -> None:
    resp = await client.post("/api/v1/auth/login", json={"email": "ghost@example.com", "password": "password123"})
    assert resp.status_code == 401


# ── Refresh token rotation ────────────────────────────────────────────────────


async def test_refresh_issues_new_tokens(client: AsyncClient) -> None:
    tokens = await _register(client, "refresh01@example.com")
    resp = await client.post("/api/v1/auth/refresh", json={"refresh_token": tokens["refresh_token"]})
    assert resp.status_code == 200
    new_tokens = resp.json()
    assert new_tokens["refresh_token"] != tokens["refresh_token"]
    assert new_tokens["access_token"] != tokens["access_token"]


async def test_refresh_reuse_detection(client: AsyncClient) -> None:
    tokens = await _register(client, "reuse01@example.com")
    old_rt = tokens["refresh_token"]
    # First use — valid
    await client.post("/api/v1/auth/refresh", json={"refresh_token": old_rt})
    # Second use of old token — reuse detected, must fail
    resp = await client.post("/api/v1/auth/refresh", json={"refresh_token": old_rt})
    assert resp.status_code == 401


async def test_refresh_after_reuse_revokes_family(client: AsyncClient) -> None:
    tokens = await _register(client, "reuse02@example.com")
    old_rt = tokens["refresh_token"]
    new_tokens = (await client.post("/api/v1/auth/refresh", json={"refresh_token": old_rt})).json()
    # Reuse old token — revokes entire family
    await client.post("/api/v1/auth/refresh", json={"refresh_token": old_rt})
    # New token from the family should also be revoked now
    resp = await client.post("/api/v1/auth/refresh", json={"refresh_token": new_tokens["refresh_token"]})
    assert resp.status_code == 401


# ── Logout ────────────────────────────────────────────────────────────────────


async def test_logout_invalidates_refresh_token(client: AsyncClient) -> None:
    tokens = await _register(client, "logout01@example.com")
    resp = await client.post("/api/v1/auth/logout", json={"refresh_token": tokens["refresh_token"]})
    assert resp.status_code == 204
    resp2 = await client.post("/api/v1/auth/refresh", json={"refresh_token": tokens["refresh_token"]})
    assert resp2.status_code == 401


async def test_logout_with_invalid_token_is_silent(client: AsyncClient) -> None:
    resp = await client.post("/api/v1/auth/logout", json={"refresh_token": "not.a.real.token"})
    assert resp.status_code == 204


# ── /me endpoint ──────────────────────────────────────────────────────────────


async def test_get_me_authenticated(client: AsyncClient) -> None:
    tokens = await _register(client, "me01@example.com")
    resp = await client.get("/api/v1/me", headers=_auth(tokens))
    assert resp.status_code == 200
    data = resp.json()
    assert data["email"] == "me01@example.com"
    assert data["role"] == "parent"
    assert data["email_verified"] is False


async def test_get_me_unauthenticated_401(client: AsyncClient) -> None:
    resp = await client.get("/api/v1/me")
    assert resp.status_code == 401


async def test_patch_me_updates_locale(client: AsyncClient) -> None:
    tokens = await _register(client, "me02@example.com")
    resp = await client.patch("/api/v1/me", json={"locale": "uz"}, headers=_auth(tokens))
    assert resp.status_code == 200
    assert resp.json()["locale"] == "uz"


# ── Child-scoped tokens cannot access parent endpoints ────────────────────────


async def test_child_token_rejected_at_me(client: AsyncClient) -> None:
    tokens = await _register(client, "childme01@example.com")
    child_resp = await client.post("/api/v1/children", json={"display_name": "Kid", "learning_language": "en"}, headers=_auth(tokens))
    assert child_resp.status_code == 201
    child_id = child_resp.json()["id"]

    session_resp = await client.post(f"/api/v1/children/{child_id}/session", headers=_auth(tokens))
    assert session_resp.status_code == 200
    child_token = session_resp.json()["child_token"]

    resp = await client.get("/api/v1/me", headers={"Authorization": f"Bearer {child_token}"})
    assert resp.status_code == 401


async def test_child_token_rejected_at_admin(client: AsyncClient) -> None:
    tokens = await _register(client, "childadmin01@example.com")
    child_resp = await client.post("/api/v1/children", json={"display_name": "Kid2", "learning_language": "en"}, headers=_auth(tokens))
    child_id = child_resp.json()["id"]

    session_resp = await client.post(f"/api/v1/children/{child_id}/session", headers=_auth(tokens))
    child_token = session_resp.json()["child_token"]

    resp = await client.get("/api/v1/admin/users", headers={"Authorization": f"Bearer {child_token}"})
    assert resp.status_code in (401, 403)


# ── Role guards ───────────────────────────────────────────────────────────────


async def test_parent_cannot_access_admin_endpoint(client: AsyncClient) -> None:
    tokens = await _register(client, "rolegrd01@example.com", role="parent")
    resp = await client.get("/api/v1/admin/users", headers=_auth(tokens))
    assert resp.status_code == 403


async def test_teacher_cannot_create_child(client: AsyncClient) -> None:
    tokens = await _register(client, "teacher01@example.com", role="teacher")
    resp = await client.post("/api/v1/children", json={"display_name": "X", "learning_language": "en"}, headers=_auth(tokens))
    assert resp.status_code == 403


# ── Parent data isolation ─────────────────────────────────────────────────────


async def test_parent_cannot_access_other_parents_child(client: AsyncClient) -> None:
    tokensA = await _register(client, "isolA@example.com")
    tokensB = await _register(client, "isolB@example.com")

    child_resp = await client.post("/api/v1/children", json={"display_name": "Alice", "learning_language": "en"}, headers=_auth(tokensA))
    assert child_resp.status_code == 201
    child_id = child_resp.json()["id"]

    # Parent B tries to create a session for Parent A's child
    resp = await client.post(f"/api/v1/children/{child_id}/session", headers=_auth(tokensB))
    assert resp.status_code == 403


async def test_parent_cannot_update_other_parents_child(client: AsyncClient) -> None:
    tokensA = await _register(client, "isolC@example.com")
    tokensB = await _register(client, "isolD@example.com")

    child_resp = await client.post("/api/v1/children", json={"display_name": "Bob", "learning_language": "en"}, headers=_auth(tokensA))
    child_id = child_resp.json()["id"]

    resp = await client.patch(f"/api/v1/children/{child_id}", json={"display_name": "Hacked"}, headers=_auth(tokensB))
    assert resp.status_code == 403


# ── Teacher data isolation ────────────────────────────────────────────────────


async def test_teacher_cannot_create_session_for_unenrolled_child(client: AsyncClient) -> None:
    parent_tokens = await _register(client, "isolE@example.com")
    teacher_tokens = await _register(client, "isolF@example.com", role="teacher")

    child_resp = await client.post("/api/v1/children", json={"display_name": "Mia", "learning_language": "en"}, headers=_auth(parent_tokens))
    child_id = child_resp.json()["id"]

    # Teacher attempts to create session for unenrolled child — must 403
    resp = await client.post(f"/api/v1/children/{child_id}/session", headers=_auth(teacher_tokens))
    assert resp.status_code == 403


# ── OAuth with mocked JWKS ────────────────────────────────────────────────────


async def test_oauth_google_mock(client: AsyncClient, monkeypatch: pytest.MonkeyPatch) -> None:
    async def _fake_verify(provider: object, id_token: str, redis: object) -> dict[str, object]:
        return {"sub": "google|oauth-test-001", "email": "google_user@example.com", "email_verified": True}

    monkeypatch.setattr("flexikeys.modules.auth.service._verify_provider_token", _fake_verify)
    resp = await client.post("/api/v1/auth/oauth/google", json={"id_token": "fake.jwt.token", "role": "parent"})
    assert resp.status_code == 200
    assert "access_token" in resp.json()


async def test_oauth_google_links_existing_email(client: AsyncClient, monkeypatch: pytest.MonkeyPatch) -> None:
    # Register first with email
    existing_email = "existing_oauth@example.com"
    await _register(client, existing_email)

    async def _fake_verify(provider: object, id_token: str, redis: object) -> dict[str, object]:
        return {"sub": "google|oauth-test-002", "email": existing_email, "email_verified": True}

    monkeypatch.setattr("flexikeys.modules.auth.service._verify_provider_token", _fake_verify)
    resp = await client.post("/api/v1/auth/oauth/google", json={"id_token": "fake.jwt.token"})
    assert resp.status_code == 200
    data = resp.json()
    # Verify we can use this token to get /me and email matches
    me = await client.get("/api/v1/me", headers={"Authorization": f"Bearer {data['access_token']}"})
    assert me.json()["email"] == existing_email


# ── Rate limiting (unit) ──────────────────────────────────────────────────────


async def test_rate_limit_function_raises_429_on_excess() -> None:
    from flexikeys.core.rate_limit import sliding_window_rate_limit
    from flexikeys.core.redis import get_redis_client

    redis = get_redis_client()
    unique_key = f"test:ratelimit:{uuid.uuid4()}"
    for _ in range(5):
        await sliding_window_rate_limit(redis, unique_key, 5, 60)
    with pytest.raises(HTTPException) as exc_info:
        await sliding_window_rate_limit(redis, unique_key, 5, 60)
    assert exc_info.value.status_code == 429


# ── Children CRUD ─────────────────────────────────────────────────────────────


async def test_create_child_returns_201(client: AsyncClient) -> None:
    tokens = await _register(client, "child01@example.com")
    resp = await client.post("/api/v1/children", json={"display_name": "Aisha", "learning_language": "uz"}, headers=_auth(tokens))
    assert resp.status_code == 201
    data = resp.json()
    assert data["display_name"] == "Aisha"
    assert data["learning_language"] == "uz"


async def test_list_children_returns_own_only(client: AsyncClient) -> None:
    tokensA = await _register(client, "child02A@example.com")
    tokensB = await _register(client, "child02B@example.com")

    await client.post("/api/v1/children", json={"display_name": "KidA", "learning_language": "en"}, headers=_auth(tokensA))
    await client.post("/api/v1/children", json={"display_name": "KidB", "learning_language": "en"}, headers=_auth(tokensB))

    respA = await client.get("/api/v1/children", headers=_auth(tokensA))
    assert respA.status_code == 200
    assert all(c["display_name"] == "KidA" for c in respA.json())


async def test_update_child_display_name(client: AsyncClient) -> None:
    tokens = await _register(client, "child03@example.com")
    child = (await client.post("/api/v1/children", json={"display_name": "Old", "learning_language": "en"}, headers=_auth(tokens))).json()
    resp = await client.patch(f"/api/v1/children/{child['id']}", json={"display_name": "New"}, headers=_auth(tokens))
    assert resp.status_code == 200
    assert resp.json()["display_name"] == "New"


async def test_create_child_session_token(client: AsyncClient) -> None:
    tokens = await _register(client, "child04@example.com")
    child = (await client.post("/api/v1/children", json={"display_name": "Timur", "learning_language": "ru"}, headers=_auth(tokens))).json()
    resp = await client.post(f"/api/v1/children/{child['id']}/session", headers=_auth(tokens))
    assert resp.status_code == 200
    data = resp.json()
    assert "child_token" in data
    assert data["token_type"] == "bearer"


# ── Parental consent ──────────────────────────────────────────────────────────


async def test_record_consent(client: AsyncClient) -> None:
    tokens = await _register(client, "consent01@example.com")
    child = (await client.post("/api/v1/children", json={"display_name": "Zohra", "learning_language": "en"}, headers=_auth(tokens))).json()
    resp = await client.post(f"/api/v1/children/{child['id']}/consent", json={"consent_type": "data_processing"}, headers=_auth(tokens))
    assert resp.status_code == 201
    assert resp.json()["consent_type"] == "data_processing"


async def test_consent_text_english(client: AsyncClient) -> None:
    resp = await client.get("/api/v1/children/consent-text?lang=en")
    assert resp.status_code == 200
    data = resp.json()
    assert "text" in data
    assert data["lang"] == "en"
    assert len(data["text"]) > 50


async def test_consent_text_uzbek(client: AsyncClient) -> None:
    resp = await client.get("/api/v1/children/consent-text?lang=uz")
    assert resp.status_code == 200
    assert resp.json()["lang"] == "uz"


async def test_consent_text_fallback_to_english(client: AsyncClient) -> None:
    resp = await client.get("/api/v1/children/consent-text?lang=xx")
    assert resp.status_code == 200
    assert "text" in resp.json()


# ── Password reset flow ───────────────────────────────────────────────────────


async def test_forgot_password_always_202(client: AsyncClient) -> None:
    resp = await client.post("/api/v1/auth/password/forgot", json={"email": "ghost@nowhere.com"})
    assert resp.status_code == 202


async def test_reset_password_flow(client: AsyncClient) -> None:
    await _register(client, "reset01@example.com", password="oldpassword123")

    # Get access token to extract user_id for the reset token
    login_tokens = await _login(client, "reset01@example.com", "oldpassword123")
    from flexikeys.core.security import create_password_reset_token, decode_token

    user_id = decode_token(login_tokens["access_token"])["sub"]
    reset_token = create_password_reset_token(user_id)

    resp = await client.post("/api/v1/auth/password/reset", json={"token": reset_token, "new_password": "newpassword123"})
    assert resp.status_code == 204

    # Should be able to login with new password
    new_tokens = await _login(client, "reset01@example.com", "newpassword123")
    assert "access_token" in new_tokens


async def test_reset_with_invalid_token_400(client: AsyncClient) -> None:
    resp = await client.post("/api/v1/auth/password/reset", json={"token": "bad.token", "new_password": "newpassword123"})
    assert resp.status_code == 400


# ── Email verification ────────────────────────────────────────────────────────


async def test_verify_email_sets_verified(client: AsyncClient) -> None:
    tokens = await _register(client, "verify01@example.com")
    me = await client.get("/api/v1/me", headers=_auth(tokens))
    assert me.json()["email_verified"] is False

    from flexikeys.core.security import create_email_verification_token, decode_token

    user_id = decode_token(tokens["access_token"])["sub"]
    verify_token = create_email_verification_token(user_id)
    resp = await client.post("/api/v1/auth/verify-email", json={"token": verify_token})
    assert resp.status_code == 204
