# ADR 004: Adaptive Engine Algorithm Choices

**Date:** 2026-07-13  
**Status:** Accepted  
**Deciders:** Engineering team

---

## Context

FlexiKeys must adapt keyboard layout, timing thresholds, hint levels, and pacing in real time to each child's motor profile. The engine must:

1. Work offline (device-side fallback)
2. Be fully explainable (parent dashboard shows *why* an adaptation changed)
3. Never stigmatize (no "disability mode" — adaptation is invisible to the child)
4. Be ML-model replaceable without changing any surrounding infrastructure

---

## Decisions

### 1. Knowledge Model: Bayesian Knowledge Tracing (BKT)

**Choice:** BKT with parameters `p_init=0.20, p_learn=0.15, p_slip=0.10, p_guess=0.20`.

**Rationale:**
- BKT is the most widely validated model for per-skill mastery estimation in EdTech (Corbett & Anderson, 1994; revalidated in ITS literature through 2020).
- It produces an interpretable probability `p_known ∈ [0,1]` that maps directly to a parent-readable "confidence" percentage with no additional transformation.
- The four fixed parameters are well-characterized for children aged 5–10 on letter/symbol recognition tasks. We set `p_slip=0.10` and `p_guess=0.20` deliberately conservatively so the system does not declare mastery prematurely.
- Mastery gate: `p_known ≥ 0.95` over `≥ 8` attempts prevents lucky-guess promotions.

**Future path to ML:** Replace `bkt_update()` with a call to a trained deep-knowledge-tracing (DKT) model. The `process_session_events` pipeline calls mastery as `{skill_key: float}` — the upstream caller doesn't care how that float is computed.

---

### 2. Smoothing: EWMA (Exponential Weighted Moving Average)

**Choice:** α = 0.15 applied to accuracy, latency, hesitation, and touch precision.

**Rationale:**
- EWMA with small α (0.10–0.20) is robust to individual outlier events (a child sneezing during a keystroke, a parent bumping the tablet) while still tracking genuine trends within 15–20 observations.
- α = 0.15 gives a half-life of approximately 4.3 observations, which balances responsiveness with noise suppression for typical session sizes of 20–50 events.
- Pure mean would weight all history equally and respond too slowly; raw per-event would trigger oscillations in the adaptation policy.

---

### 3. Spaced Repetition: SM-2 (SuperMemo 2)

**Choice:** Binary (correct/incorrect) SM-2 variant with `ease_init=2.50, ease_min=1.30`.

**Rationale:**
- SM-2 is the most studied and deployed spaced-repetition algorithm; its binary variant maps cleanly onto typing accuracy (no partial credit needed at v1).
- The `repetition_queue` drives which items appear in the next session, creating automatic review of items where mastery has plateaued.
- The algorithm is trivially serializable to JSON and runs identically in Python and Dart with no shared state beyond the queue items.

**Future path:** Replace with FSRS (Free Spaced Repetition Scheduler) when enough data accumulates for per-child parameter tuning.

---

### 4. Adaptation Policy: Deterministic Rule Table

**Choice:** Pure function with bounded step sizes and hysteresis.

**Rationale:**
- A rule table is fully auditable: every adaptation maps to an `explanation_key` that localizes to a parent-readable string ("Key size was increased because your child's tap accuracy dropped below 60%.").
- Bounded steps (max Δ per call) prevent jarring layout jumps that would surprise the child.
- Hysteresis (block opposite-direction change from a prior session) prevents oscillation when a metric is near a threshold.
- The function signature `apply(profile, metrics, mastery, last_changes, session_id) → (profile, changes)` is intentionally ML-model-replaceable: swap the rule table for a model call and nothing else changes.

**Rules in priority order:**
1. Per-skill accuracy → per-key scale (targeted: only the struggling key grows)
2. Per-skill hesitation → hint level (targeted hint per key)
3. Mastery → hint decay (reward for mastered skills)
4. Accidental tap rate → dwell time + key spacing (global)
5. Touch offset ratio → global key scale
6. Fatigue index (EWMA slope < −0.05) → session break suggestion

---

### 5. Cross-Platform Contract: Golden JSON Fixtures

**Choice:** `shared/adaptive_policy.json` documents all thresholds and includes five golden test fixtures exercised by both `tests/adaptive/test_golden.py` (Python) and (future) `test/adaptive_policy_test.dart` (Dart).

**Rationale:**
- The Dart client runs the same policy offline when the device is not connected. If the constants drift between implementations, adaptive profiles will diverge between sessions, causing confusing adaptation behavior.
- A versioned JSON spec (not Protobuf/OpenAPI, since the schema is trivially small) is human-readable, checkable in CI, and sufficient for the current scale.

---

### 6. Server-Side Authority; Device-Side Fallback

**Choice:** Policy runs server-side after each event batch; the computed `AdaptationProfile` is pushed to the device. The device-side Dart policy runs only when offline.

**Rationale:**
- Server-side allows richer signals (cross-session trends, cohort statistics) that cannot fit in a single event batch.
- The deterministic fallback means the child experience is never blocked by connectivity: the device uses the last-synced profile and applies the same policy function to session events, producing a locally-computed profile that will be reconciled on next sync.

---

## Consequences

- **Positive:** Fully auditable, parent-explainable, ML-replaceable, offline-capable, cross-platform testable.
- **Negative:** Rule-table policies require manual tuning as the user population grows; BKT fixed parameters will not be optimal for every child. Both are addressed in the ML replacement path.
- **Constraint:** Any change to `policy.py` constants must be accompanied by an update to `shared/adaptive_policy.json` and golden tests.

---

## Related ADRs

- ADR 001: Database design (PostgreSQL, partitioned interaction_events)
- ADR 002: Auth (JWT, refresh rotation, COPPA pseudonymization)
- ADR 003: FastAPI module layout
