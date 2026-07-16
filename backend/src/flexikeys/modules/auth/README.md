# auth

JWT issue/refresh, OAuth (Google/Apple), argon2id password hashing, parental consent recording.

## Endpoints (Phase 02)

| Method | Path | Description |
|--------|------|-------------|
| POST | `/auth/register` | Create parent/teacher account |
| POST | `/auth/login` | Issue access + refresh token pair |
| POST | `/auth/refresh` | Rotate refresh token |
| POST | `/auth/logout` | Revoke refresh token |
| POST | `/auth/oauth/google` | OAuth exchange |
| POST | `/auth/oauth/apple` | OAuth exchange |

## Security notes

- Passwords hashed with argon2id (passlib)
- Refresh tokens stored hashed (SHA-256) in DB; rotated on every use
- Access tokens: 15 min lifetime; refresh tokens: 30 days
- Auth endpoints rate-limited to 20 req/min per IP
- Consent timestamp + IP recorded at registration (COPPA/GDPR-K)