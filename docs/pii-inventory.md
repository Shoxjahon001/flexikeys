# FlexiKeys PII Inventory

**COPPA / GDPR-K posture:** Children are identified by a UUID pseudonym only.
No real name, email, or date of birth is collected from the child.
Parents hold their own account PII. All child telemetry is pseudonymized at ingest.

**Date:** 2026-07-14

---

## Data Categories

### 1. Parent / Teacher / Admin Accounts (`users` table)

| Field | Type | Classification | Retention | Notes |
|-------|------|----------------|-----------|-------|
| `id` | UUID | Pseudonym | Until account deletion | Primary key; used in logs |
| `email` | String | PII (contact) | Until account deletion | Hashed index; never logged |
| `password_hash` | String | Credential | Until account deletion | Argon2id; never returned in API |
| `role` | Enum | Non-PII | Until deletion | parent / teacher / admin |
| `locale` | String | Preference | Until deletion | en / uz / ru |
| `email_verified` | Boolean | Non-PII | Until deletion | |
| `deleted_at` | Timestamp | Non-PII | 90 days after deletion | Soft-delete |
| `created_at` | Timestamp | Metadata | Until deletion | |

**Access controls:** Never returned to other users. Parent can view/delete own record via `/api/v1/me` (DELETE not yet implemented — STUB #57).

---

### 2. Child Profiles (`children` table)

| Field | Type | Classification | Retention | Notes |
|-------|------|----------------|-----------|-------|
| `id` | UUID | Pseudonym | Until parent deletes | Used in all child telemetry |
| `parent_id` | UUID | Reference | Until deletion | Links to `users` — parent only |
| `display_name` | String | Near-PII | Until deletion | Chosen by parent; typically a first name or nickname |
| `learning_language` | String | Preference | Until deletion | en / uz / ru |
| `birth_year` | Integer | Near-PII (age proxy) | Until deletion | Optional; used for age-appropriate content; year only, not DOB |
| `avatar_id` | String | Preference | Until deletion | Refers to a bundled asset, not an uploaded image |
| `deleted_at` | Timestamp | Metadata | 90 days | Soft-delete |

**No PII collected from the child directly.** The child never enters their name, email, or any identifying information into the app. All fields are set by the parent.

**Data minimization:** `birth_year` is the coarsest usable age signal (year only, not full DOB). This is sufficient for COPPA age verification without collecting a full birthdate.

---

### 3. Parental Consent (`child_consents` table)

| Field | Type | Classification | Retention | Notes |
|-------|------|----------------|-----------|-------|
| `id` | UUID | Pseudonym | Permanent (legal record) | |
| `child_id` | UUID | Reference | Permanent | |
| `parent_id` | UUID | Reference | Permanent | |
| `consent_type` | String | Non-PII | Permanent | `data_processing` |
| `consent_version` | String | Non-PII | Permanent | e.g., `1.0` |
| `consented_at` | Timestamp | Metadata | Permanent | |
| `ip_hash` | String | Pseudonym | Permanent | SHA-256 of IP; not reversible |

**Retention:** Consent records are permanent legal records and are NOT deleted when the child profile is deleted. The child_id and parent_id remain as UUID references (no PII).

---

### 4. Interaction Events (`interaction_events` table)

| Field | Type | Classification | Retention | Notes |
|-------|------|----------------|-----------|-------|
| `id` | UUID | Pseudonym | 12 months rolling | |
| `session_id` | UUID | Reference | 12 months | |
| `child_id` | UUID | Pseudonym | 12 months | No name, email, or DOB |
| `target_key` | String | Behavioral | 12 months | e.g., `"a"` |
| `actual_key` | String | Behavioral | 12 months | |
| `latency_ms` | Integer | Behavioral | 12 months | |
| `touch_x/y` | Float | Behavioral | 12 months | Normalized [0,1], not pixels |
| `accidental_tap` | Boolean | Behavioral | 12 months | |
| `occurred_at` | Timestamp | Metadata | 12 months | Client-reported |

**No PII in events.** Events identify the child only by UUID pseudonym (`child_id`). The link from UUID to parent account lives in the `children` table, which is the single join point for de-anonymization — access to that table is restricted by role (parent only sees own children).

---

### 5. Adaptation Profiles (`adaptation_profiles` table)

| Field | Type | Classification | Retention | Notes |
|-------|------|----------------|-----------|-------|
| `child_id` | UUID | Pseudonym | Until child deletion | |
| `params` | JSONB | Behavioral (derived) | Until deletion | key_scale, dwell_time, etc. |
| `version` | Integer | Metadata | Until deletion | |
| `updated_at` | Timestamp | Metadata | Until deletion | |

**De-identified from source events.** The profile is a derived aggregate — knowing the params alone does not re-identify the child.

---

### 6. Notifications (`notifications` table)

| Field | Type | Classification | Retention | Notes |
|-------|------|----------------|-----------|-------|
| `user_id` | UUID | Reference | 90 days after read | Parent / teacher only |
| `kind` | String | Non-PII | 90 days | |
| `payload` | JSONB | May contain child display name | 90 days | |
| `sent_at` | Timestamp | Metadata | 90 days | |
| `read_at` | Timestamp | Metadata | 90 days | |

**Children are never targeted by notifications.** `NotificationService.send()` raises `ValueError` if `is_child=True`.

---

### 7. Audit Logs (`audit_logs` table)

| Field | Type | Classification | Retention | Notes |
|-------|------|----------------|-----------|-------|
| `actor_id` | UUID | Reference (admin) | 7 years (compliance) | Admin accounts only |
| `action` | String | Non-PII | 7 years | e.g., `set_feature_flag` |
| `resource_type` | String | Non-PII | 7 years | |
| `payload` | JSONB | May contain flag keys | 7 years | |

---

## Data Flows

```
[Child Device]
     │
     │ child_session JWT (contains child_id UUID only)
     ▼
[API: /sessions/events]
     │
     │ stores interaction_events(child_id UUID, behavioral data)
     ▼
[Adaptive Engine Worker]
     │
     │ reads events by child_id → computes metrics
     ▼
[adaptation_profiles table] ── parent can view via /parent/reports
```

No PII crosses the child→API boundary. The child device only ever sends the `child_session` JWT (containing UUID) plus behavioral keystroke data.

---

## Export / Deletion

| Right | Endpoint | Status |
|-------|----------|--------|
| Access (parent) | `GET /api/v1/parent/reports` | ✅ Implemented |
| Delete child profile | `DELETE /api/v1/children/{id}` | ⚠️ Stub #57 |
| Delete parent account | `DELETE /api/v1/me` | ⚠️ Stub #57 |
| Export (GDPR Article 20) | `POST /api/v1/parent/export` | ⚠️ Stub #58 |

All deletion stubs are tracked and must be implemented before GDPR-applicable markets (EU) launch.

---

## Third-Party Data Sharing

| Recipient | Data Shared | Legal Basis |
|-----------|------------|-------------|
| No analytics SDKs | — | COPPA: no third-party analytics in child experience |
| Push provider (STUB #49) | Device token + notification content | Contractual; DPA required |
| Email provider (STUB #50) | Parent email + notification content | Contractual; DPA required |
| Storage (S3/MinIO) | Audio files, report PDFs | Contractual; data-at-rest encrypted |

All third-party integrations require a Data Processing Agreement (DPA) before GA.

---

## Telemetry Pseudonymization

All server-side logs use `structlog` with the following sanitization rules:
- `email` field → never logged
- `password`, `token`, `access_token`, `refresh_token` → never logged
- `child_id`, `user_id` → logged as UUID (pseudonym, not PII)
- Request body → not logged (only method + path + status + duration)