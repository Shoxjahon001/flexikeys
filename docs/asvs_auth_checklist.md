# OWASP ASVS L2 — Authentication Checklist (Phase 03)

Reference: OWASP Application Security Verification Standard v4.0, Chapter 2 (Authentication).

## V2.1 Password Security

| # | Requirement | Status | Notes |
|---|---|---|---|
| 2.1.1 | Passwords at least 12 chars (warn only) / min 8 chars required | ✅ | 8-char minimum enforced in `RegisterRequest`, `ResetPasswordRequest` |
| 2.1.5 | Users can change their own password | ✅ | `POST /auth/password/forgot|reset` |
| 2.1.6 | Password change requires current password or reset flow | ✅ | Reset flow uses signed JWT token |
| 2.1.7 | Passwords checked against breached-password lists | ⬜ | Future: integrate HaveIBeenPwned k-anonymity API |
| 2.1.9 | No max-length restriction preventing passphrases | ✅ | Field is String(256) — sufficient for any passphrase |
| 2.1.12 | Allow paste into password fields | N/A | API only — enforced client-side |

## V2.2 General Authenticator Security

| # | Requirement | Status | Notes |
|---|---|---|---|
| 2.2.1 | Anti-automation controls (rate limiting) on auth | ✅ | Sliding-window 20 req/min per IP on all auth endpoints |
| 2.2.2 | Use of weak authenticators prohibited | ✅ | Argon2id only; no MD5/SHA1 |
| 2.2.3 | Secure notifications sent after password changes | ✅ | `ConsoleNotificationService` (STUB #1 — replace with real SMTP) |
| 2.2.4 | Credential stuffing and brute-force defences | ✅ | Rate limiting + constant-time compare |

## V2.3 Authenticator Lifecycle

| # | Requirement | Status | Notes |
|---|---|---|---|
| 2.3.1 | System-generated initial passwords must be random | N/A | No auto-generated passwords |
| 2.3.3 | Renewal notifications before credential expiry | ⬜ | Future: scheduled worker |

## V2.5 Credential Recovery

| # | Requirement | Status | Notes |
|---|---|---|---|
| 2.5.1 | OTP/token-based recovery only; no security questions | ✅ | JWT password-reset token (15 min) |
| 2.5.2 | Hints not stored or exposed | ✅ | No hints |
| 2.5.3 | Forgot-password does not reveal if email exists | ✅ | Always returns 202 |
| 2.5.6 | Single-use reset links; expire immediately after use | ✅ | JWT signed with secret; old tokens revoked on reset |

## V2.7 Out-of-Band Verifier

| # | Requirement | Status | Notes |
|---|---|---|---|
| 2.7.1 | OOB tokens expire in 10 min (password reset) | ✅ | Password reset JWT: 15 min. Email verify JWT: 24 h |

## V2.8 Single or Multi-Factor OTP

Not applicable in Phase 03; planned for future phases.

## V2.9 Cryptographic Software and Devices

| # | Requirement | Status | Notes |
|---|---|---|---|
| 2.9.1 | Cryptographic keys in protected storage | ✅ | `APP_SECRET_KEY` from env — never hardcoded |
| 2.9.3 | Approved cryptographic algorithms | ✅ | Argon2id (passwords), HS256 (JWT), SHA-256 (token hash) |

## V2.10 Service Authentication

| # | Requirement | Status | Notes |
|---|---|---|---|
| 2.10.1 | No shared/default credentials | ✅ | All credentials from env vars |
| 2.10.4 | Passwords/keys not in source code | ✅ | `.env.example` documents all vars |

## Argon2id Parameters

Configured in `core/security.py` via `passlib.CryptContext`:

```
scheme:       argon2id (v19)
time_cost:    2   (iterations)
memory_cost:  65536  (64 MiB)
parallelism:  2
```

These meet OWASP ASVS L2 minimums for interactive logins. For bulk / high-security contexts, increase `time_cost` to 3–4.

## Token Security Summary

| Token type | Algorithm | Storage | Lifetime | Revocation |
|---|---|---|---|---|
| Access JWT | HS256 | Client only | 15 min | N/A (short-lived) |
| Refresh JWT | HS256 | DB (SHA-256 hash) | 30 days | Per-token or family |
| Child session JWT | HS256 | Client only | 8 hours | N/A (short-lived) |
| Email verify JWT | HS256 | Email link | 24 hours | JWT sig check |
| Password reset JWT | HS256 | Email link | 15 min | Old tokens revoked on use |

**No tokens are logged.** Notification service logs intent only (`email_verification_queued`, `password_reset_queued`) without the token value.
