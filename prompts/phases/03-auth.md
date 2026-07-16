# Phase 03 — Authentication, Accounts & Roles

## Prerequisites
Phases 01–02.

## Goal
Production-grade auth for parent, teacher, admin users and device-bound child profiles. Security is not optional anywhere in this phase.

## Build

**Core auth**
- Email/password signup & login (Argon2id, constant-time verify), email verification token flow (email sending behind `NotificationService` interface; console/dev transport for now, marked `# STUB:`).
- JWT access tokens (15 min, includes role + user id) and rotating refresh tokens (30 days, hashed at rest in `refresh_tokens`, reuse detection revokes the family).
- OAuth2: Google and Apple sign-in — full authorization-code flow implementation with id_token verification (JWKS fetch + cache in Redis); provider credentials from env; account linking when email matches a verified account.
- Password reset flow with single-use tokens.
- Rate limiting on auth endpoints via Redis (sliding window), lockout with exponential backoff on repeated failures.

**Child profiles (not logins)**
- Children never authenticate with credentials. A parent session selects a child profile → backend issues a **child-scoped token** (short-lived, claims: child_id, parent_id, learning_language, no email). All child-app endpoints accept only child-scoped tokens.
- Parental consent recorded (`parental_consents`) before a child profile becomes active; expose consent text endpoint (localized).

**Authorization layer**
- Dependency-injected `require_role(...)` and `require_child_access(...)` guards. Parents access only their own children; teachers only children enrolled in their classes (and only progress data — never parent contact info); admin has separated router with audit logging of every admin action.

**Endpoints** (`/api/v1`)
```
POST /auth/register            POST /auth/login              POST /auth/refresh
POST /auth/logout              POST /auth/oauth/{provider}   POST /auth/password/forgot|reset
GET  /me                       PATCH /me
POST /children                 GET /children                 PATCH /children/{id}
POST /children/{id}/session    → child-scoped token
POST /children/{id}/consent    GET /consent-text?lang=
```

**Flutter side**
- `features/auth/`: welcome → parent sign-in/up (email + Google/Apple buttons) → child profile picker ("Who is playing today?" — large avatar cards, no text input needed by the child) → child home.
- Secure token storage (flutter_secure_storage), dio interceptor for refresh, auth state in Riverpod with route guards in go_router (child routes vs parent routes vs teacher routes).
- Child profile picker is a **child-facing screen**: pastel, large targets, voice prompt on open. Sign-out and parent areas gated behind a parental gate (e.g., "hold 3 seconds + solve 7×4" pattern) so children can't wander into settings.

## Acceptance Criteria
- [ ] Full pytest suite: registration, login, refresh rotation + reuse detection, OAuth token verification (mock JWKS), role guards, parent/teacher data isolation (attempt cross-access → 403), rate limiting
- [ ] Child-scoped tokens cannot call parent/teacher/admin endpoints (tested)
- [ ] Flutter: auth flow works end-to-end against local backend; tokens survive app restart; parental gate blocks child access to settings
- [ ] Security review pass: no tokens in logs, argon2 params documented, OWASP ASVS L2 checklist for auth section noted in docs
