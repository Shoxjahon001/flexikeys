# Phase 09 — Teacher Dashboard, Admin, PDF Export, Notifications

## Prerequisites
Phases 01–08.

## 1. Teacher Backend (`modules/teacher`)
- Classes CRUD with join codes; parents enroll a child by entering the code (consent-gated: parent approves what the teacher can see — progress only, defined scope).
- Assignments: teacher assigns level/lesson to class or subset, due date, optional note; `assignment_status` auto-updates from lesson completions (worker).
- Class analytics endpoints: per-class aggregates (avg accuracy, time, mastery distribution), per-student drill-down (same data shape as parent progress, minus family info), "needs attention" list computed from mastery stagnation — framed supportively in UI copy ("could use extra practice"), never ranked leaderboards.

## 2. Teacher UI (`features/teacher/`)
Adult design-system variant: class list → class detail (roster grid with soft mastery heat cells, no red), student detail, assignment composer, class report screen. Bulk actions kept simple; everything reachable in ≤ 3 taps.

## 3. PDF Export Service (`modules/reports` + worker)
- Server-side PDF generation (WeasyPrint) from HTML templates styled with the FK identity (pastel headers, charts rendered server-side, localized). Templates: parent weekly report, teacher class report, student report.
- Async job: request → Celery/Arq task → PDF to object storage → signed URL + notification. `GET /reports/{id}/pdf` endpoint; export buttons in parent and teacher UIs.

## 4. Admin (`modules/admin` + minimal web view)
- FastAPI-served admin (server-rendered or SQLAdmin): users, children (PII-minimized view), curriculum versions (publish/rollback), assets, reward definitions, feature flags, audit log viewer. Every admin mutation → audit log. Admin auth = admin role + TOTP 2FA.
- Platform analytics endpoints: DAU/WAU, retention cohorts, level funnel, adaptation-distribution stats (how many children run adapted profiles — aggregate only, anonymized).

## 5. Notifications (`modules/notifications`)
- `NotificationService` with channel adapters: push (FCM/APNs via firebase_messaging; config-gated), email (provider adapter). Templates localized (3 languages).
- Events: weekly report ready, streak encouragement (opt-in, max 1/day, parent-facing only — never nag the child), assignment created/completed, consent requests. Full preference matrix in parent settings honored server-side.

## Acceptance Criteria
- [ ] Teacher can: create class → parent joins child via code → assign lesson → child completes → status + class stats update (full e2e test with seeded data)
- [ ] Teacher cannot access unenrolled children or any parent contact data (authz tests)
- [ ] PDFs generate correctly in all 3 languages with real chart data; render check for Cyrillic and Uzbek Latin glyphs
- [ ] Admin: curriculum rollback works; every mutation audited; 2FA enforced
- [ ] Notification preferences respected (opt-out tested); no notification path targets the child experience
