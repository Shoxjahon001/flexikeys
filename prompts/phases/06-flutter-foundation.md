# Phase 06 — Flutter Foundation: Design System, Mascot, Adaptive Keyboard

## Prerequisites
Phases 01–05. This phase defines how FlexiKeys *feels*. Apple-HIG calm + Duolingo polish + Headspace softness — without copying any of them.

## 1. Design System (`app/lib/design_system/`)
**Tokens** (`fk_tokens.dart`):
- Colors: sky `#A8D8EA`, cloud `#FDFDFB`, mint `#B8E6C9`, warmYellow `#FFE7A0`, lavender `#D9D2F0`, peach `#FFD9C7`, ink `#4A5568`, inkSoft `#718096`. Semantic mapping (background, surface, primary, success, attention — attention is warm yellow, never red).
- Radii: sm 16, md 24, lg 32, pill. Spacing scale: 8/16/24/32/48. Elevation: soft diffuse shadows only (low opacity, large blur).
- Typography: Nunito; child styles (display 40/32, label 24) vs adult styles (parent/teacher dashboards, denser but still rounded).
- Motion tokens: durations 200/300/400ms, curves easeOutCubic; global `reducedMotion` flag honored by every animation.

**Atoms/molecules** (each with widget test + golden test):
`FkButton` (min 64dp child / 44dp adult, press = gentle scale 0.97 + soft haptic), `FkCard`, `FkProgressPath` (level map), `FkCoinCounter`, `FkStarBurst` (calm particle celebration), `FkAudioButton` (replay pronunciation), `FkAvatar`, `FkParentGate`.

**Theme:** single `FkTheme` ThemeExtension consumed everywhere. No raw `Color(...)` or `TextStyle(...)` in feature code — enforce with a custom lint rule or a CI grep check.

## 2. Mascot (`design_system/mascot/`)
- Rive file `mascot.riv` with a state machine: inputs `expression` (happy, thinking, sleeping, celebrating, encouraging, surprised, waving) + continuous idle float (2–3px vertical sine drift, always on).
- If Rive asset authoring isn't possible in this environment, implement `MascotRenderer` as a CustomPainter cloud (soft blob, eyes, blush) with the same state machine API, and keep the Rive adapter behind the same interface — swappable later without touching features. Document as ADR.
- `MascotController` (Riverpod): `setExpression(FkExpression)`, `say(String l10nKey)` → speech bubble + queued audio. Copy only from the curated catalog (Phase 05). Mascot reacts to lesson events via a domain event bus, never hardcoded in screens.

## 3. Navigation & Shell
go_router route tree: child shell (home world-map → level → lesson player; drawing studio; rewards room) / parent shell (dashboard, reports, AI chat, settings) / teacher shell — role-gated by auth state (Phase 03). Child home = horizontal scrolling world path with level nodes (locked = sleeping cloud, active = waving, mastered = celebrating). Transitions: soft fade+slide, no hard cuts.

## 4. The Adaptive Keyboard (`features/keyboard/`) — flagship component
- `FkKeyboard` renders entirely from `AdaptationProfile` + current language layout (en QWERTY-lite, uz Latin incl. o' g' sh ch, ru ЙЦУКЕН-lite; lesson mode can show a reduced key set: only introduced letters + the target neighborhood).
- Per-key size from `key_scale` (global × per-key), spacing from `key_spacing`; layout recomputes smoothly (animated, ≤ 400ms) when profile updates between lessons — **never mid-word**.
- Input pipeline: raw pointer events → dwell filter (`dwell_time_ms`: press must be held this long; visual feedback = key fills softly while dwelling) → debounce filter → keystroke event. Rejected taps logged as accidental (telemetry) but show no negative feedback.
- Hint levels: 0 none · 1 target key gently pulses · 2 pulse + dimmed non-targets · 3 pulse + ghost hand + audio prompt.
- Every keystroke emits a full telemetry record (target, actual, latency, time-to-first-touch, touch offset from key center) to the local event queue.
- Golden tests at profile extremes (default vs max-adapted) + widget tests for dwell/debounce logic with fake clocks.

## 5. Telemetry & Sync services
`services/telemetry/`: drift-backed append-only queue, batch flush (500 or 15s) with `batch_id` idempotency, offline-tolerant, exponential backoff. `services/sync/`: profile pull on session start + after flush; applies Dart-side fallback policy (Phase 04) when offline.

## Acceptance Criteria
- [ ] Golden tests pass for all atoms + keyboard at 2 profile extremes
- [ ] Dwell/debounce unit tests with fake clocks (accidental tap rejected, no negative feedback shown)
- [ ] Keyboard resize animates between lessons, never mid-word (test)
- [ ] Mascot idle float runs at 60fps on a mid-range device profile; reducedMotion disables float and particles
- [ ] No raw colors/text styles outside design_system (CI check passes)
- [ ] Full flow on emulator: pick child → world map → open lesson shell (player logic lands in Phase 07)
