# FlexiKeys — Database Schema (ERD)

All tables live in the default `public` schema on PostgreSQL 16. `interaction_events` is range-partitioned monthly by `occurred_at`.

## Entity-Relationship Diagram

```mermaid
erDiagram
    users {
        uuid id PK
        citext email UK
        varchar password_hash
        user_role role
        varchar locale
        varchar timezone
        timestamptz created_at
        timestamptz updated_at
        timestamptz deleted_at
    }

    oauth_identities {
        uuid id PK
        uuid user_id FK
        oauth_provider provider
        varchar provider_subject
        timestamptz created_at
    }

    children {
        uuid id PK
        uuid parent_id FK
        varchar display_name
        varchar avatar_id
        int birth_year
        learning_language learning_language
        varchar ui_language
        timestamptz created_at
        timestamptz updated_at
        timestamptz deleted_at
    }

    parental_consents {
        uuid id PK
        uuid child_id FK
        consent_type consent_type
        timestamptz granted_at
        timestamptz revoked_at
    }

    refresh_tokens {
        uuid id PK
        uuid user_id FK
        varchar token_hash UK
        varchar device_info
        timestamptz expires_at
        timestamptz revoked_at
        timestamptz created_at
    }

    assets {
        uuid id PK
        asset_kind kind
        varchar storage_key UK
        varchar mime
        bigint bytes
        varchar checksum
        timestamptz created_at
    }

    curriculum_versions {
        uuid id PK
        varchar version UK
        timestamptz published_at
        varchar checksum
    }

    levels {
        uuid id PK
        uuid version_id FK
        int ordinal
        varchar slug
        numeric unlock_mastery_threshold
    }

    lessons {
        uuid id PK
        uuid level_id FK
        int ordinal
        varchar slug
        lesson_type lesson_type
    }

    items {
        uuid id PK
        uuid lesson_id FK
        int ordinal
        item_type item_type
        varchar skill_key
        jsonb payload
    }

    item_localizations {
        uuid id PK
        uuid item_id FK
        varchar language
        text text
        uuid audio_asset_id FK
        uuid image_asset_id FK
        uuid extra_audio_asset_id FK
    }

    learning_sessions {
        uuid id PK
        uuid child_id FK
        varchar language
        timestamptz started_at
        timestamptz ended_at
        jsonb device_info
        varchar client_version
    }

    interaction_events {
        bigint id "composite PK"
        uuid session_id FK
        timestamptz occurred_at "composite PK + partition key"
        event_type event_type
        uuid item_id FK
        varchar skill_key
        jsonb payload
        uuid ingest_batch_id
    }

    skill_mastery {
        uuid id PK
        uuid child_id FK
        varchar language
        varchar skill_key
        numeric p_known
        int attempts
        int correct
        numeric ewma_accuracy
        numeric ewma_latency_ms
        timestamptz last_seen_at
    }

    adaptation_profiles {
        uuid id PK
        uuid child_id FK_UK
        jsonb params
        int version
        timestamptz updated_at
    }

    adaptation_changes {
        uuid id PK
        uuid child_id FK
        timestamptz changed_at
        varchar param
        text old_value
        text new_value
        adaptation_reason_code reason_code
        varchar explanation_key
    }

    repetition_queue {
        uuid id PK
        uuid child_id FK
        varchar language
        varchar skill_key
        timestamptz due_at
        int interval_days
        numeric ease
        int lapses
    }

    level_progress {
        uuid id PK
        uuid child_id FK
        varchar language
        uuid level_id FK
        level_status status
        timestamptz mastered_at
        timestamptz updated_at
    }

    wallets {
        uuid child_id PK_FK
        int coins
        int stars
        timestamptz updated_at
    }

    reward_definitions {
        uuid id PK
        reward_kind kind
        varchar slug UK
        int cost_coins
        jsonb unlock_rule
    }

    reward_grants {
        uuid id PK
        uuid child_id FK
        uuid reward_definition_id FK
        timestamptz granted_at
        reward_source source
    }

    daily_activity {
        uuid id PK
        uuid child_id FK
        date date
        int seconds_active
        int items_completed
        numeric avg_accuracy
    }

    classes {
        uuid id PK
        uuid teacher_id FK
        varchar name
        varchar join_code UK
        timestamptz created_at
        timestamptz updated_at
    }

    class_enrollments {
        uuid id PK
        uuid class_id FK
        uuid child_id FK
        timestamptz enrolled_at
    }

    assignments {
        uuid id PK
        uuid class_id FK
        uuid level_id FK
        uuid lesson_id FK
        timestamptz due_at
        text instructions
        timestamptz created_at
        timestamptz updated_at
    }

    assignment_status {
        uuid id PK
        uuid assignment_id FK
        uuid child_id FK
        submission_status status
        timestamptz completed_at
    }

    ai_conversations {
        uuid id PK
        uuid parent_user_id FK
        varchar title
        timestamptz created_at
        timestamptz updated_at
    }

    ai_messages {
        uuid id PK
        uuid conversation_id FK
        varchar role
        text content
        timestamptz created_at
    }

    notifications {
        uuid id PK
        uuid user_id FK
        varchar kind
        jsonb payload
        timestamptz sent_at
        timestamptz read_at
        timestamptz created_at
    }

    reports {
        uuid id PK
        report_scope scope
        uuid subject_id
        varchar period
        jsonb payload
        uuid pdf_asset_id FK
        timestamptz created_at
    }

    users ||--o{ oauth_identities : "has"
    users ||--o{ children : "parents"
    users ||--o{ refresh_tokens : "has"
    users ||--o{ classes : "teaches"
    users ||--o{ ai_conversations : "has"
    users ||--o{ notifications : "receives"

    children ||--o{ parental_consents : "covered by"
    children ||--o{ learning_sessions : "has"
    children ||--o{ skill_mastery : "has"
    children ||--|| adaptation_profiles : "has"
    children ||--o{ adaptation_changes : "logged"
    children ||--o{ repetition_queue : "has"
    children ||--o{ level_progress : "has"
    children ||--|| wallets : "has"
    children ||--o{ reward_grants : "earns"
    children ||--o{ daily_activity : "has"
    children ||--o{ class_enrollments : "enrolled in"
    children ||--o{ assignment_status : "has"

    curriculum_versions ||--o{ levels : "contains"
    levels ||--o{ lessons : "contains"
    lessons ||--o{ items : "contains"
    items ||--o{ item_localizations : "localized as"
    assets ||--o{ item_localizations : "used in"
    assets ||--o{ reports : "attached to"

    learning_sessions ||--o{ interaction_events : "generates"
    items ||--o{ interaction_events : "referenced by"

    reward_definitions ||--o{ reward_grants : "granted via"

    classes ||--o{ class_enrollments : "has"
    classes ||--o{ assignments : "has"
    levels ||--o{ assignments : "targets"
    lessons ||--o{ assignments : "targets"
    assignments ||--o{ assignment_status : "has"

    levels ||--o{ level_progress : "tracks"

    ai_conversations ||--o{ ai_messages : "contains"
```

## Partitioning

`interaction_events` is `PARTITION BY RANGE (occurred_at)`. Monthly child partitions are named `interaction_events_YYYY_MM`. New partitions must be created by the DB ops runbook before each month starts; a cron worker (`workers/partition_manager.py`) will automate this in Phase 07.

## Soft Deletes

Only `users` and `children` use soft delete (`deleted_at`). All other deletions are hard deletes, with FK `ondelete="CASCADE"` propagating from children → all child tables.

## Triggers

`set_updated_at()` BEFORE UPDATE trigger is installed on: `users`, `children`, `adaptation_profiles`, `wallets`, `level_progress`, `classes`, `assignments`, `ai_conversations`, `notifications`.

## Enum Types (PostgreSQL native)

| PG type | Values |
|---|---|
| `user_role` | parent, teacher, admin |
| `oauth_provider` | google, apple |
| `learning_language` | en, uz, ru |
| `lesson_type` | typing, drawing, listening, story |
| `item_type` | letter, number, word, sentence, shape, color, trace_path, story_page |
| `event_type` | keystroke, trace_point, item_shown, item_completed, hint_shown, break_taken |
| `adaptation_reason_code` | accuracy_drop, latency_rise, fatigue, mastery_gain, accidental_taps |
| `level_status` | locked, active, mastered |
| `reward_kind` | badge, world, mascot_emotion, background, accessory |
| `reward_source` | earned, purchased_with_coins |
| `submission_status` | pending, in_progress, completed |
| `report_scope` | parent_daily, parent_weekly, teacher_class |
| `asset_kind` | audio, image, rive, font |
| `consent_type` | data_processing, coppa_parent_consent |
