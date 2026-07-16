# Phase 07 — Gameplay: Lesson Player, Rewards, Drawing Module

## Prerequisites
Phases 01–06.

## 1. Lesson Player (`features/lesson/`)
State machine (typed, unit-tested): `loadPlan → presentItem → awaitInput → evaluate → feedback → (repeat | nextItem) → celebrate → summary`.

**Typing item flow:** image appears (soft scale-in) → audio: object sound if any ("Moooo") → word audio ("Cow") → target text shown as large ghost letters → child types on FkKeyboard → each correct letter fills in with a soft pop + letter pronunciation → word complete: mascot encouraging expression + coins.

**No-failure rules:** wrong key = the pressed key gently sinks back, target hint escalates per adaptation `hint_level`, mascot says "Take your time" variants after repeated misses. Never a red flash, never an error sound, never a score penalty. After N assisted attempts the item completes *with* help and is silently queued for repetition (Phase 04) — the child always finishes.

**Session pacing:** honor `session_pacing` — after the profile's threshold, mascot suggests a break ("Let's rest our hands. Ready when you are.") with a calm breathing animation; child can continue or stop. Sessions target 5–10 minutes.

**Story lessons (Level 16):** page-by-page illustrated micro-stories; narration audio per page; one typed word completes each page.

## 2. Reward System (`features/rewards/` + `modules/rewards`)
- Server-authoritative earning rules: coins per completed item (flat, effort-based — not accuracy-scaled, to avoid punishing struggling children), stars per lesson (1–3 by *personal* improvement vs own baseline, never vs other children), badges for streaks/mastery/effort milestones ("Practiced 3 days", "Mastered 5 letters").
- Unlockables: worlds (background themes for the world map), mascot emotions/accessories (hat, scarf), backgrounds. Spend coins in a simple "Cloud Shop" — everything earnable, nothing purchasable with money. API: `GET /rewards/catalog`, `POST /rewards/{id}/redeem` (transactional, tested for double-spend).
- Celebrations are calm: FkStarBurst, mascot celebrating, one soft chime. No screen-filling explosions.

## 3. Drawing Module (`features/drawing/`)
Canvas engine (CustomPainter + gesture pipeline sharing the dwell/debounce filters from the keyboard):
- **Tracing:** letter/number/shape/animal/flower/cloud paths from curriculum payloads (normalized point sequences). Guide dot leads the way; stroke evaluated by average distance to path + direction; tolerance comes from `AdaptationProfile` (wider for children with lower touch precision). Completion is generous — effort completes the trace.
- **Coloring:** flood-fill regions from SVG-derived region masks; large color palette chips (pastel), fat brush.
- **Connect-the-dots:** numbered dots (reinforces Level 2), rubber-band line, order enforced gently (wrong dot just doesn't connect).
- **Mazes:** finger-drag path, walls are soft (crossing = gentle bounce back, no reset).
- **Free finger painting:** brush size options, calm color palette, save to gallery (local + optional upload to parent-visible gallery via media module).
- Every drawing interaction emits `trace_point` telemetry (path deviation, speed, tremor proxy) feeding the same adaptive metrics — fine-motor progress becomes visible in the parent dashboard.

## 4. Offline Play
Lesson plans + assets prefetch (next 2 lessons); full lesson and drawing play offline; events queue and sync; rewards granted optimistically client-side, reconciled server-side on sync (server wins; never claw back visibly — reconcile silently).

## Acceptance Criteria
- [ ] Lesson state machine fully unit-tested including no-failure paths and assisted completion
- [ ] E2E on emulator: complete a Level 1 lesson → coins awarded → shop redeem → mascot accessory visible
- [ ] Trace evaluation tested with synthetic strokes (accurate, wobbly, offset) — wobbly passes with adapted tolerance
- [ ] Airplane-mode test: full lesson + drawing offline, sync on reconnect, no duplicate events (idempotency verified)
- [ ] Double-spend redeem test passes
- [ ] Audio sequencing correct: sound → word → typing prompts, no overlaps
