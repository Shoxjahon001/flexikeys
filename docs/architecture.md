# FlexiKeys — System Architecture

## Overview

FlexiKeys is an adaptive EdTech platform. The **adaptive engine** is the core; all other components exist to feed it signals and surface its outputs.

## System Diagram

```mermaid
graph TB
    subgraph "Client (Flutter)"
        APP[Flutter App<br/>Riverpod · go_router · drift]
        AK[Adaptive Keyboard<br/>driven by AdaptationProfile]
        DM[Drawing Module<br/>tracing · coloring · mazes]
        PD[Parent Dashboard<br/>reports · AI assistant]
        TD[Teacher Dashboard<br/>class mgmt · PDF export]
    end

    subgraph "Backend (FastAPI)"
        GW[API Gateway<br/>JWT auth · rate limit · CORS]
        AE[Adaptive Engine<br/>BKT · EWMA · spaced-rep]
        CUR[Curriculum Service<br/>16 levels · 3 languages]
        AI[AI Assistant<br/>provider-agnostic interface]
        NOTIF[Notifications<br/>push · in-app]
        MEDIA[Media Service<br/>audio · images · rive files]
    end

    subgraph "Data"
        PG[(PostgreSQL 16<br/>normalized schema)]
        RD[(Redis 7<br/>session cache · task queue)]
        S3[(S3-compatible<br/>MinIO · audio · images · PDFs)]
    end

    subgraph "Workers (Arq)"
        MW[Metrics Worker<br/>rollups · BKT updates]
        RW[Report Worker<br/>PDF generation]
        NW[Notification Worker]
    end

    APP -->|HTTPS + JWT| GW
    GW --> AE
    GW --> CUR
    GW --> AI
    GW --> NOTIF
    GW --> MEDIA
    AE --> PG
    AE --> RD
    CUR --> PG
    AI --> PG
    MEDIA --> S3
    MW --> PG
    MW --> RD
    RW --> S3
    AE -.->|enqueue signal batch| RD
    RD -.->|dequeue| MW
```

## Key Data Flows

### 1 — Child interaction → adaptation update

```
Child taps key
  → Flutter emits KeystrokeEvent (key, latency, offset, accidental_flag)
  → Queued locally in drift (offline-first)
  → Batch-synced to POST /sessions/{id}/events
  → Metrics Worker computes EWMA accuracy, BKT mastery update
  → AdaptationProfile written to DB + pushed to device
  → Flutter rebuilds AdaptiveKeyboard with new profile
```

### 2 — Parent views report

```
Parent opens dashboard
  → GET /parent/children/{id}/report?period=week
  → Backend aggregates progress + adaptation_changes
  → AI assistant summarises in plain language (3 languages)
  → Parent sees: mastery chart, what changed and why, recommendations
```

### 3 — Offline play

```
No network
  → drift local DB serves lessons from last sync
  → Events queued in drift outbox
  → AdaptationProfile frozen at last known state
  → On reconnect: outbox flushed, full sync, profile updated
```

## Module Responsibilities

| Module | Owns |
|---|---|
| `auth` | JWT issue/refresh, OAuth (Google/Apple), argon2id passwords, consent |
| `users` | Parent/teacher/admin accounts, preferences |
| `children` | Child profiles, per-child settings, avatar |
| `curriculum` | Lesson content, level definitions, localized strings/media |
| `sessions` | Session lifecycle, event ingest (idempotent), raw event store |
| `adaptive` | Signal processing, BKT, EWMA, AdaptationProfile CRUD, audit log |
| `progress` | Mastery summaries, streaks, completion records |
| `rewards` | Stars, badges, unlocks — earned only through play |
| `parent` | Parent-facing reports, AI assistant, adaptive-changes feed |
| `teacher` | Class/student management, assignments, class stats, PDF export |
| `admin` | Platform-level management, feature flags, content publishing |
| `ai_assistant` | Provider-agnostic LLM interface, conversation history |
| `notifications` | Push tokens, in-app notification store, worker trigger |
| `media` | Pre-signed URL generation, upload/download, transcoding jobs |

## Security Posture

- JWT access tokens: 15-minute lifetime. Refresh tokens: 30-day, rotated on use, stored hashed.
- Child PII: minimal — display name, avatar choice, birthdate (year only). No real name required.
- Telemetry: pseudonymized at ingest (child_id is a UUID, never linked to PII in analytics).
- No third-party analytics SDKs in the child experience path.
- All endpoints rate-limited. Auth endpoints: stricter limits + account lockout.
- COPPA/GDPR-K: parental consent recorded with timestamp + IP; child data exportable and deletable.