"""
Phase 10: Authorization matrix test.

Two layers:
  1. Route introspection — every non-public APIRoute must declare
     get_current_user or get_child_claims somewhere in its dependency tree.
     No DB required; FastAPI builds the dep graph at import time.

     NOTE: FastAPI ≥ 0.115 stores included routes inside _IncludedRouter
     wrappers in app.routes; we traverse those recursively to collect
     all APIRoute objects with their full paths.

  2. HTTP-level spot checks (uses `client` fixture with real DB) — a sample
     of protected routes must reject unauthenticated requests with 401.
"""
from __future__ import annotations

from fastapi.routing import APIRoute

from flexikeys.core.deps import get_child_claims, get_current_user

# Routes where unauthenticated or non-user-auth access is intentional.
_PUBLIC_PATHS: frozenset[str] = frozenset(
    [
        # Ops
        "/health",
        "/version",
        # Auth endpoints — rate-limited but no user auth (they ARE the login flow)
        "/api/v1/auth/register",
        "/api/v1/auth/login",
        "/api/v1/auth/refresh",
        "/api/v1/auth/logout",
        "/api/v1/auth/oauth/{provider}",
        "/api/v1/auth/password/forgot",
        "/api/v1/auth/password/reset",
        "/api/v1/auth/verify-email",
        # Consent text is shown before login — intentionally public
        "/api/v1/children/consent-text",
    ]
)

_AUTH_GUARDS: frozenset[object] = frozenset([get_current_user, get_child_claims])


def _collect_all_routes(router_or_app: object, parent_prefix: str = ""):  # type: ignore[type-arg]
    """Yield (full_path, APIRoute) tuples by recursively walking _IncludedRouter wrappers.

    FastAPI >= 0.115 wraps included routers in _IncludedRouter objects at the
    top level of app.routes; the actual APIRoute objects live inside them.
    """
    for r in getattr(router_or_app, "routes", []):
        if isinstance(r, APIRoute):
            yield parent_prefix + r.path, r
        elif type(r).__name__ == "_IncludedRouter":
            ctx_prefix: str = getattr(r.include_context, "prefix", "") or ""  # type: ignore[union-attr]
            yield from _collect_all_routes(r.original_router, parent_prefix + ctx_prefix)  # type: ignore[union-attr]


def _collect_dep_calls(dependant: object, seen: set[int] | None = None):  # type: ignore[type-arg]
    """Recursively yield all dependency callables in the Dependant tree."""
    if seen is None:
        seen = set()
    for sub in getattr(dependant, "dependencies", []):
        key = id(sub.call)  # type: ignore[union-attr]
        if key in seen:
            continue
        seen.add(key)
        if sub.call is not None:  # type: ignore[union-attr]
            yield sub.call  # type: ignore[union-attr]
        yield from _collect_dep_calls(sub, seen)


# ── Introspection tests (no DB required) ──────────────────────────────────────


def test_every_protected_route_has_auth_guard() -> None:
    """All non-public API routes must declare an auth guard in their dep tree."""
    from flexikeys.main import app

    violations: list[str] = []
    for path, route in _collect_all_routes(app):
        if path in _PUBLIC_PATHS:
            continue
        dep_calls = set(_collect_dep_calls(route.dependant))
        if not (dep_calls & _AUTH_GUARDS):
            for method in sorted(route.methods or []):
                violations.append(f"{method} {path}")

    assert not violations, (
        "Routes missing auth guard (get_current_user or get_child_claims):\n"
        + "\n".join(violations)
    )


def test_all_routes_are_accounted_for() -> None:
    """Routes without auth guards are in _PUBLIC_PATHS (no forgotten routes)."""
    from flexikeys.main import app

    unaccounted: list[str] = []
    for path, route in _collect_all_routes(app):
        dep_calls = set(_collect_dep_calls(route.dependant))
        has_auth = bool(dep_calls & _AUTH_GUARDS)
        if not has_auth and path not in _PUBLIC_PATHS:
            unaccounted.append(path)

    assert not unaccounted, (
        "Paths without auth guards that are NOT in _PUBLIC_PATHS "
        "(add them intentionally or add an auth guard):\n"
        + "\n".join(unaccounted)
    )


def test_auth_router_has_no_user_auth_guard() -> None:
    """Auth endpoints must NOT require get_current_user — they are the login flow."""
    from flexikeys.main import app

    violations: list[str] = []
    for path, route in _collect_all_routes(app):
        if not path.startswith("/api/v1/auth/"):
            continue
        dep_calls = set(_collect_dep_calls(route.dependant))
        if get_current_user in dep_calls:
            violations.append(path)

    assert not violations, (
        "Auth routes must not require get_current_user:\n" + "\n".join(violations)
    )


def test_child_endpoints_use_get_child_claims() -> None:
    """Child-facing endpoints (sessions, adaptive, rewards) must use child tokens."""
    from flexikeys.main import app

    child_prefixes = ("/api/v1/sessions", "/api/v1/adaptive", "/api/v1/rewards")
    for path, route in _collect_all_routes(app):
        if not any(path.startswith(p) for p in child_prefixes):
            continue
        dep_calls = set(_collect_dep_calls(route.dependant))
        assert get_child_claims in dep_calls, (
            f"{path} should use get_child_claims (not get_current_user)"
        )


def test_admin_routes_require_current_user() -> None:
    """Admin routes must have get_current_user (via require_role) in dep tree."""
    from flexikeys.main import app

    violations: list[str] = []
    for path, route in _collect_all_routes(app):
        if not path.startswith("/api/v1/admin/"):
            continue
        dep_calls = set(_collect_dep_calls(route.dependant))
        if get_current_user not in dep_calls:
            violations.append(path)

    assert not violations, "Admin routes missing get_current_user:\n" + "\n".join(violations)


def test_route_count_sanity() -> None:
    """Sanity check that the traversal finds the expected number of routes."""
    from flexikeys.main import app

    routes = list(_collect_all_routes(app))
    # We have 14 routers with multiple endpoints each — expect at least 40 routes
    assert len(routes) >= 40, (
        f"Expected at least 40 routes but found {len(routes)}. "
        "Router traversal may be broken."
    )


# ── HTTP-level spot checks (use `client` fixture — requires DB) ───────────────


async def test_unauthenticated_user_endpoints_return_401(client) -> None:  # type: ignore[no-untyped-def]
    """Sample of user-facing endpoints must reject no-token requests with 401."""
    protected = [
        ("GET", "/api/v1/me"),
        ("GET", "/api/v1/children"),
        ("GET", "/api/v1/teacher/classes"),
        ("GET", "/api/v1/admin/feature-flags"),
        ("GET", "/api/v1/notifications"),
        ("GET", "/api/v1/parent/reports"),
    ]
    for method, path in protected:
        resp = await client.request(method, path)
        assert resp.status_code == 401, (
            f"Expected 401 for unauthenticated {method} {path}, got {resp.status_code}"
        )


async def test_invalid_bearer_token_returns_401(client) -> None:  # type: ignore[no-untyped-def]
    """An invalid JWT must return 401, not 500."""
    headers = {"Authorization": "Bearer not.a.valid.jwt.token"}
    resp = await client.get("/api/v1/me", headers=headers)
    assert resp.status_code == 401


async def test_parent_role_cannot_reach_admin(client) -> None:  # type: ignore[no-untyped-def]
    """A parent-role user must receive 403 on admin routes."""
    reg = await client.post(
        "/api/v1/auth/register",
        json={"email": "authz_parent@example.com", "password": "password123", "role": "parent"},
    )
    assert reg.status_code == 201
    token = reg.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    resp = await client.get("/api/v1/admin/feature-flags", headers=headers)
    assert resp.status_code == 403


async def test_teacher_role_cannot_reach_admin(client) -> None:  # type: ignore[no-untyped-def]
    """A teacher-role user must receive 403 on admin routes."""
    reg = await client.post(
        "/api/v1/auth/register",
        json={"email": "authz_teacher@example.com", "password": "password123", "role": "teacher"},
    )
    token = reg.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    resp = await client.get("/api/v1/admin/audit-logs", headers=headers)
    assert resp.status_code == 403


async def test_public_health_requires_no_auth(client) -> None:  # type: ignore[no-untyped-def]
    """Health and version endpoints must not require auth."""
    resp_h = await client.get("/health")
    resp_v = await client.get("/version")
    assert resp_h.status_code == 200
    assert resp_v.status_code == 200


async def test_consent_text_requires_no_auth(client) -> None:  # type: ignore[no-untyped-def]
    """/children/consent-text is intentionally public."""
    resp = await client.get("/api/v1/children/consent-text")
    assert resp.status_code == 200
