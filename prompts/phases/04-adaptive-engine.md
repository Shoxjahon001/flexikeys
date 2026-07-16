# Phase 04 — The Adaptive Engine (heart of the product)

## Prerequisites
Phases 01–03. This is the most important phase in the project. Take maximum care. Real algorithms, real tests, zero placeholder math.

## Goal
Signals in → metrics → mastery → bounded adaptation out, fully explainable. A child who struggles with the letter B gets: B repeated sooner, more guidance on B, a slightly larger B key, and no new letters until B mastery recovers — all automatically, gradually, and invisibly.

## 1. Event Ingest (`modules/sessions`)
- `POST /sessions` start, `PATCH /sessions/{id}` end.
- `POST /sessions/{id}/events` — batch ingest (up to 500 events), idempotent via client-generated `batch_id` (Redis dedup + unique constraint). Validate payload shape per event_type with Pydantic discriminated unions. Enqueue metric processing job on accept; never block ingest on computation.

## 2. Metrics Pipeline (`modules/adaptive/metrics.py`, worker)
Per (child, language, skill_key), maintain in `skill_mastery`:
- **EWMA accuracy** (α = 0.15) and **EWMA latency**
- **Hesitation**: EWMA of time_to_first_touch
- **Confusion pairs**: counted matrix of target→actual errors (Redis hash, flushed to rollup)
- **Accidental-tap rate**: taps rejected by dwell/debounce ÷ total taps
- **Fatigue index** per session: linear-regression slope of accuracy over the session's item sequence, negative slope beyond threshold ⇒ fatigued
- **Touch precision**: mean |offset from key center| — feeds key sizing

## 3. Mastery Model (`modules/adaptive/mastery.py`)
Bayesian Knowledge Tracing per skill: parameters `p_init=0.2, p_learn=0.15, p_slip=0.1, p_guess=0.2` (constants in config, documented). Update `p_known` on every graded attempt. **Mastered** when `p_known ≥ 0.95` over ≥ 8 attempts. Level unlock = mastery of the level's required skill set (threshold on `levels.unlock_mastery_threshold`). Write unit tests against hand-computed BKT sequences.

## 4. Spaced Repetition (`modules/adaptive/repetition.py`)
SM-2-derived scheduler over `repetition_queue`: correct → interval grows by ease; incorrect → lapse, interval resets short, ease decreases (floor 1.3). Lesson item selection = interleave due repetitions with new items, respecting the progression gate.

## 5. Adaptation Policy (`modules/adaptive/policy.py`)
Pure, deterministic, unit-testable function: `(current_profile, metrics, mastery) → new_profile + list[AdaptationChange]`.

Rules (all bounded and gradual — max step per update shown):
| Signal | Adaptation | Step | Bounds |
|---|---|---|---|
| skill accuracy < 0.6 | per-key `key_scale[skill]` up | +0.05 | 1.0–1.5 |
| accuracy recovered ≥ 0.85 | per-key scale decays back | −0.05 | → 1.0 |
| accidental-tap rate > 8% | `dwell_time_ms` up, `key_spacing` up | +20ms / +0.05 | 0–300ms / 1.0–1.6 |
| touch precision poor (offset > 30% of key) | global `key_scale` up | +0.05 | 1.0–1.4 |
| hesitation high on skill | `hint_level` up for that skill | +1 | 0–3 |
| fatigue index triggered | `session_pacing` → suggest break; shorten remaining lesson | — | — |
| mastery gained | progression gate opens next items; hints decay | — | — |

Every change is persisted to `adaptation_changes` with `reason_code` and `explanation_key` mapping to localized parent-facing sentences ("We made the B key a little bigger because it was tricky this week.").

**Hysteresis:** minimum 1 session between opposite-direction changes on the same param. Children must never perceive oscillation.

## 6. Profile Delivery & Offline Fallback
- `GET /adaptive/profile` (child token) returns versioned profile; client caches it.
- Publish the policy's core thresholds as a JSON spec in `shared/adaptive_policy.json`; implement the same bounded rules in Dart (`app/lib/features/adaptive/`) operating on locally queued events so offline play still adapts. On sync, server state wins; client-side changes are advisory.
- Contract tests: feed identical event streams to the Python policy and Dart policy → identical profile outputs (golden JSON fixtures in `shared/`).

## 7. Simulation Harness (`backend/tests/adaptive/simulator.py`)
Build a child simulator with configurable motor profiles (accuracy, latency distribution, tremor/offset noise, fatigue curve). Simulate: (a) struggling child → assert keys grow, hints rise, progression gates hold, and mastery eventually improves; (b) fast learner → assert quick progression, hints decay, profile stays near defaults; (c) fatiguing child → assert break suggestion fires. These are the phase's proof of correctness.

## Acceptance Criteria
- [ ] ≥ 90% test coverage on `modules/adaptive`
- [ ] BKT, SM-2, EWMA verified against hand-computed fixtures
- [ ] All three simulator scenarios pass with documented output
- [ ] Python and Dart policies produce identical outputs on shared golden fixtures
- [ ] Every adaptation writes an auditable, localizable explanation
- [ ] Ingest of 500-event batch: p95 < 150ms (processing async)
- [ ] ADR documenting algorithm choices and how future ML models slot in behind the same policy interface
