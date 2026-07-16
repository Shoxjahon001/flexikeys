# FlexiKeys Accessibility Audit — §5 Checklist Review

**Date:** 2026-07-14
**Scope:** `docs/FLEXIKEYS_DOMAIN_KNOWLEDGE.md` §5 acceptance checklist, applied to the
actual running Flutter app (not the newer, mostly-unused `design_system/`/`features/auth`
stack — see note below).
**Method:** Direct reading of every file in scope, line-cited. No code was changed in
this session.

## Note on the checklist count

§5 of the domain doc contains **12** checkbox items, not 13. I counted twice
(`grep -c "^- \[ \]"` → 12) before writing this. I'm flagging the discrepancy rather than
inventing a 13th item to match the brief. All 12 are audited below.

## Note on which code was actually audited

The repo currently contains **two parallel UI stacks**:

1. The stack a child actually plays in: `lib/screens/*` (`theme/app_theme.dart`,
   `widgets/cloud_mascot.dart`, `services/user_service.dart`) — splash → language →
   (parent signup) → levels dashboard → the four game screens → good job / level
   complete. **This is what's audited below**, because it's what's live in
   `lib/main.dart`'s route table and what a child's thumb actually touches.
2. A newer, more disciplined design system (`design_system/fk_theme.dart`,
   `fk_tokens.dart`, `atoms/fk_button.dart`) that **already encodes several of the §5
   rules correctly** (a real `FkTouchTargets.child = 64` constant, enforced by
   `FkButton`'s `minHeight`) but is only wired into the parent-facing auth screens
   (`ParentSignupScreen`, `LoginScreen`), not into any of the gameplay screens. This
   matters for the audit: **the correct answer to item 1 already exists in the
   codebase — it's just not used where a child's thumb lands.** Called out explicitly
   under Item 1.

---

## Verdict summary

| # | Checklist item | Verdict |
|---|---|---|
| 1 | Large, well-spaced touch targets | **PARTIAL** |
| 2 | No fast/double/long-press-only/timed gestures | **PASS** |
| 3 | Tracing/drawing tolerates wobble, rewards partial progress | **PARTIAL** |
| 4 | No hard time limits by default | **PASS** |
| 5 | Accidental extra touches debounced | **FAIL** |
| 6 | Errors gentle, neutral, instantly retryable | **PARTIAL** |
| 7 | Every skill ≥2 sensory channels | **FAIL** |
| 8 | Reward feedback immediate + describes the action | **PARTIAL** |
| 9 | Child never sees technical/error/auth text | **PASS** |
| 10 | Parent settings surface (size/pace/sound/difficulty/TTS) | **FAIL** |
| 11 | Progress saved locally, resumes exactly where stopped | **PARTIAL** |
| 12 | Skills re-appear across levels (spaced repetition) | **FAIL** |

**3 PASS · 5 PARTIAL · 4 FAIL**

---

## Item 1 — Primary touch targets are large and well-spaced; no critical action needs fine precision

**Verdict: PARTIAL** — the app's *primary* progression buttons are excellent; almost
every *secondary* control (back, undo, color pick, replay-audio, buy) is undersized.

**Evidence — good:**
- `lib/design_system/fk_tokens.dart:82` — `static const double child = 64;` — the
  correct constant exists.
- `lib/design_system/atoms/fk_button.dart:80,115` — `FkButton` correctly enforces
  `BoxConstraints(minHeight: minH)` using that constant. Used in the (mostly unseen)
  auth screens only.
- Primary CTAs across the live flow are consistently generous: splash "Go!" 68dp,
  `welcome_screen.dart:101` "Start" 68dp, `register_screen.dart:200` "Next" 68dp,
  `good_job_screen.dart:83` "continue" 68dp, `level_complete_screen.dart:111` "Okay"
  68dp, `letters_stage1_screen.dart:414-415` choice tiles 90×90, `letters_stage2_screen.dart:391-392`
  choice tiles 88×88, `levels_screen.dart` level-dashboard cards — the whole grid cell
  is tappable, well above 64dp.

**Evidence — bad (all below both Material's 48dp baseline *and* the app's own
64dp child standard):**
- `lib/screens/game/letters_stage1_screen.dart:199-200` — back button `width: 40, height: 40`.
- `lib/screens/game/letters_stage1_screen.dart:351-352` — TTS replay icon `width: 44, height: 44`.
- `lib/screens/game/letters_stage2_screen.dart:161-162` — back button `40×40`.
- `lib/screens/game/letters_stage2_screen.dart:317-318` — TTS replay icon `40×40`.
- `lib/screens/game/shapes_screen.dart:296` — back button `width: 42, height: 42`.
- `lib/screens/game/letter_drawing_screen.dart:456` — back button `40×40`.
- `lib/screens/game/letter_drawing_screen.dart:596` — color swatches `width: 36, height: 36` — the smallest interactive target found anywhere in the app.
- `lib/screens/game/letter_drawing_screen.dart:618,643` — eraser and undo icon buttons, `40×40` each, only `8px` apart (line 627 `SizedBox(width: 8)`).
- `lib/screens/shop_screen.dart:219-223` — buy button: `padding: const EdgeInsets.symmetric(vertical: 10)` around one line of 16px text ≈ 40dp effective tap height.

**Why it matters:** §4 explicitly asks for targets "well above the 48dp baseline,"
and CLAUDE.md independently states "Child touch targets ≥ 64×64dp." A back button or
color swatch is not a "primary game target" in the pedagogical sense, but a child with
imprecise motor control still has to hit it — and a mis-tap on a 36×36 swatch or a
40×40 eraser can have real consequences (see Item 5, the eraser wipes all progress on
the current letter).

**Fix:** Mechanical — raise every listed control to `FkTouchTargets.child` (or a
reasoned 48dp floor for genuinely secondary, low-consequence controls like back/TTS-replay,
64dp for anything that changes committed progress like eraser/undo), and widen gaps
between adjacent small controls. Ideally, route these through `FkButton`/`fk_tokens.dart`
instead of hand-rolled `Container`s, which would also fix Item 6's color problem for free.
**Effort: M** (one clear pattern, ~9 call sites across 5 files).

---

## Item 2 — No task requires fast, double, long-press-only, or timed gestures

**Verdict: PASS**

**Evidence:** Grepped the whole `lib/screens/game/` tree and `levels_screen.dart` for
`Timer(`, `Timer.periodic`, countdown patterns — none found. Every interaction in scope
is a single tap (`onTap`) or a continuous, self-paced drag (`onPanStart/Update/End`).
Nothing requires double-tap, long-press, or beating a clock. `letter_drawing_screen.dart`
even offers `_onDemo()` (an untimed "show me" animated example) before the child has to
act.

No fix needed.

---

## Item 3 — Tracing/drawing tolerates wobble and rewards partial progress

**Verdict: PARTIAL** — scoring is genuinely generous; the underlying gating mechanic is
tight, and much tighter in one of the two tracing screens than the other.

**Evidence — scoring is good:**
- `shapes_screen.dart:191-217` (`_computeAccuracy`) and `letter_drawing_screen.dart:388-412`
  both measure average distance from the drawn stroke to the nearest ideal edge, clamp
  it, and map it onto a 0–10 (→ 1–3 star) scale. Neither requires a pixel-perfect
  stroke; a wobbly but roughly-correct trace still scores well. This is the right idea.

**Evidence — gating is tight, and inconsistent between the two screens:**
- `shapes_screen.dart:65` — `static const double _snapR = 10.0;` — the *only* way to
  register progress on a shape is to bring the finger within **10 logical pixels** of
  each dot, in order (`_trySnap`, lines 159-187). 10px is extremely tight for a hand
  with tremor, and the canvas itself is small (`_inner = min(c.maxWidth - _pad*2, 210.0)`,
  line 423), so dots sit close together, making 10px an even larger fraction of the
  space between them.
- `letter_drawing_screen.dart:237` — `static const double _snapR = 30.0;` — three times
  more forgiving than the shapes screen, for what is a harder task (letter strokes vs.
  simple polygons). There's no evident reason the two screens use different values.
- Neither screen has any fallback for a child who genuinely can't land inside the
  radius — no escalating tolerance after repeated misses, no alternate
  "tap-to-advance-anyway" path. A child who can't hit 10px is stuck on that shape
  indefinitely (no hard timer forces failure, but also nothing rescues them).

**Why it matters:** §4 explicitly asks for "a *wide* corridor around the ideal path"
and mentions dwell-to-select as an alternative to precise tapping. A 10px radius is the
opposite of wide.

**Fix:**
- Widen `shapes_screen.dart`'s `_snapR` from 10 to something closer to
  `letter_drawing_screen.dart`'s 30 (or larger — test on-device with an actual finger,
  not a mouse). **Effort: S** (one constant).
- Add a soft escalation: after N consecutive failed attempts at the same dot, either
  grow the radius or auto-advance with partial credit. **Effort: M.**

---

## Item 4 — No hard time limits by default; any timer is optional and extendable

**Verdict: PASS**

**Evidence:** Same grep as Item 2 — no timers anywhere in the audited scope. All
post-answer transitions (`Future.delayed(600ms)`, `800ms`, `1800ms` etc.) are fixed
*pacing* delays that happen **after** the child has already acted, not deadlines
*before* which they must act. `level_configs.dart` levels have a `questionCount` (10–15)
but no time budget.

No fix needed.

---

## Item 5 — Accidental extra touches are debounced

**Verdict: FAIL**

**Evidence:**
- `letters_stage1_screen.dart:79-96` (`_onTap`) — `if (_answered) return;` blocks a
  *second* tap only after the *first* one has already committed an answer. The first
  touch — accidental or not — registers instantly. There is no dwell/hold-to-confirm
  step anywhere in this screen.
- Same pattern in `letters_stage2_screen.dart:70-93`, `shapes_screen.dart:159-187`
  (`_trySnap` — the instant a drag point crosses the 10px radius, it counts), and
  `letter_drawing_screen.dart:316-328` (`_trySnap` — same, at 30px).
- No screen implements anything resembling the backend's own `dwell_time_ms` /
  `debounce_ms` concept (these exist as fields in the adaptive-profile data model per
  the backend work, but nothing in the client ever reads or applies them to the
  actual tap-registration logic in these four screens).
- **Highest-consequence instance:** `letter_drawing_screen.dart:614-626` — the eraser
  button (40×40, `Icons.edit_off_rounded`) calls `_onReset()`
  (lines 334-344), which does `_strokes.clear(); _tapped = 0; _done = false;` —
  **wiping all drawing progress on the current letter with no confirmation dialog.**
  It sits directly in the toolbar *below the canvas* — exactly the zone a drawing hand
  passes over — separated from four other small tap targets (three 36×36 color
  swatches plus a divider) by only 8px (line 627). A single mis-tap during a drawing
  session erases everything the child just did.
- Worse: the *adjacent* "undo last stroke" button (lines 629-651) doesn't actually undo
  cleanly either — the code comment says it plainly: *"Roll back tapped count to a safe
  value — recalculate from remaining strokes. Simpler: just reset tapped to 0 so child
  re-confirms progress"* — i.e. even the "undo one stroke" button resets **all** dot
  progress back to zero, not just the last stroke. Both buttons in this toolbar are
  effectively full-reset buttons wearing different icons.
- `shop_screen.dart:53-73` (`_buy`) has no guard against a rapid double-tap firing two
  concurrent purchases before `_owned` state refreshes.

**Why it matters:** This is the most direct violation of §4's core promise ("tremor or
extra unintended touches... Filter accidental double/extra touches so a tremor doesn't
register as a wrong answer") in the whole app, and the letter-drawing eraser is the
single most punishing failure mode I found — a child with motor difficulty is by
definition more likely to mis-tap near a canvas, and the mis-tap costs them everything
they just drew.

**Fix:**
- Add a confirmation step (or at minimum a short "are you sure?" state, or a
  hold-to-confirm gesture) before `_onReset()` executes. **Effort: S.**
- Fix "undo last stroke" to actually only remove the last stroke's dot credit, not
  reset all `_tapped` progress. **Effort: M** (needs per-stroke dot-index bookkeeping).
- Add a lightweight commit delay (e.g. require the touch to persist ~80-150ms, or
  ignore a second pointer-down within ~150ms of the first) before `_onTap`/`_trySnap`
  register an answer, across all four game screens. **Effort: M.**

---

## Item 6 — Errors are gentle, neutral, and instantly retryable — never shaming

**Verdict: PARTIAL** — the sound is well-designed; the color is not.

**Evidence — the sound is good:**
- `lib/services/sound_service.dart:121-139` (`_makeBuzz`) — a descending 330→140Hz
  tone, a 50/50 sine+sawtooth blend (not a harsh pure square/sawtooth alarm), 300ms,
  amplitude `0.65` — quieter than the "correct" ding's `0.75` (line 116). The envelope
  (15ms attack, exponential decay) is soft, not a blaring sustained buzzer. (Evaluated
  from the waveform-generation parameters — I could not listen to the actual audio in
  this environment, so treat this as strong-but-not-certain evidence.)
- Retry is always frictionless: every wrong-answer path (all four game screens)
  auto-advances or re-highlights within under a second, never dead-ends.
- No copy anywhere says "Wrong!" or "Failed!" — the language is consistently neutral
  ("Let's try again!", `letters_stage1_screen.dart:288`).

**Evidence — the color is not good:**
- `letters_stage1_screen.dart:400-402` — wrong answer: `bgColor = 0xFFFFE0E0`,
  `borderColor = 0xFFFF6B6B`, `textColor = 0xFFFF6B6B` — a saturated red tile highlight.
- `letters_stage2_screen.dart:379-381` — identical red palette on a wrong tap.
- `shop_screen.dart:57-66` — "Not enough stars!" SnackBar with
  `backgroundColor: const Color(0xFFFF6B6B)` — pure red, shown to the child directly
  during normal Shop use, not a rare/parent-only path.

**Why it matters:** CLAUDE.md's design system is explicit: "**Never**: neon, dark
backgrounds, aggressive red." `0xFFFF6B6B` is exactly that — an "aggressive red" is used
as the universal wrong/error/insufficient-funds signal three separate times, directly
contradicting the app's own stated color rule and the domain doc's "never a harsh
buzzer stacked with negative imagery" (the imagery here is the red itself, not a buzzer
+ X, but the mechanism — red-coded failure — is the same category of problem).

**Fix:** Swap the red palette for the design system's approved `attention`
(`FkColors.warmYellow`, `0xFFFFE7A0`) or a neutral gray/blue everywhere a "wrong" or
"insufficient" state is shown. **Effort: S** (color-constant swap, 3 call sites).

---

## Item 7 — Every skill is presented through ≥2 sensory channels (visual + audio at least)

**Verdict: FAIL** — true for English content, broken for the app's other two supported languages.

**Evidence:**
- `lib/services/tts_service.dart:116-122` — the TTS fetch request hardcodes
  `'tl': 'en-US', 'sl': 'en'`. There is no language parameter anywhere in the service's
  public API (`speak(text)`, `speakFunny(text)`) — it is architecturally impossible to
  request a non-English voice.
- `lib/screens/language_screen.dart:19-23` explicitly offers three learning languages
  (`en`, `ru`, `uz`), and the child's `learningLanguage` is tracked all the way through
  the auth/child system (per the backend work — `ChildProfile.learningLanguage`).
- `lib/screens/game/shapes_screen.dart:26-48` — every shape name shown on screen is in
  **Uzbek** (`'Kvadrat'`, `'Uchburchak'`, `"To'rtburchak"`, `'Romb'`, `'Beshburchak'`,
  `"Olti burchak"`). Grepping the file, `_shape.name` is never passed to
  `TtsService.instance.speak(...)` anywhere — the audio channel simply doesn't exist
  for this screen's actual vocabulary; only the English praise phrases
  (`speakFunny('Amazing! Well done!')`) are spoken.
- `letters_stage1_screen.dart:20-22` (`_letters`) and `letters_stage2_screen.dart:20-23`
  (`_words`) are hardcoded English (`'A'..'O'`, `'ONE'..'TEN'`) regardless of the
  child's selected learning language — so even the letters/numbers game content itself
  isn't localized, only the surrounding chrome (button labels, mascot bubble text) is
  bilingual/Uzbek in places.
- Even where TTS *would* apply, `letter_drawing_screen.dart`'s only spoken content is
  the bare letter name (`TtsService.instance.speak(_def.letter)`, line 276) — the
  actual instruction sentence a child needs ("connect the dots 1→2→3 in order," built
  as `_instruction` at lines 241-244) is shown as **text only** in the mascot bubble and
  never spoken, despite §1's foundational premise that "the child is pre-literate."

**Why it matters:** For a `uz` or `ru` child (a first-class supported case per the
language picker), the promise of "visual + audio reinforcing the same skill" is not
degraded, it's absent — the shapes screen has Uzbek text with no matching audio at all,
and the letters/numbers screens have audio, but in the wrong language for a non-English
learner. This also undermines §2's "multi-sensory input strengthens memory" principle:
a mismatched or missing audio channel doesn't just fail to help, it can actively confuse
a child who's being shown one language and hearing another (or hearing nothing).

**Fix:**
- Thread the active child's `learningLanguage` into `TtsService.speak()`/`speakFunny()`
  and set `tl`/`sl` accordingly (Google Translate's TTS endpoint already used here does
  support other language codes — this may be smaller than it looks). **Effort: M** for
  the plumbing.
- Localize the actual game content arrays (`_letters`, `_words`, and any generic-game
  word lists) per learning language, not just the chrome around them. **Effort: L** —
  real content work, not just code.
- At minimum, wire `shapes_screen.dart`'s `_shape.name` and
  `letter_drawing_screen.dart`'s `_instruction` into TTS once language support exists.
  **Effort: S** once the above is done.

---

## Item 8 — Reward feedback is immediate (~200ms) and describes the action

**Verdict: PARTIAL** — timing is right, description is wrong, and it's a repeated pattern.

**Evidence — timing is good:**
- `SoundService.instance.playCorrect()` fires synchronously inside the tap/snap handler
  in all four game screens (e.g. `letters_stage1_screen.dart:88`,
  `shapes_screen.dart:166`) — effectively immediate, well under the 200ms target.

**Evidence — description is not:**
- `shapes_screen.dart:184` — `TtsService.instance.speakFunny(score >= 7 ? 'Amazing! Well done!' : ...)`.
- `letter_drawing_screen.dart:358` — the **identical** string, `'Amazing! Well done!'`.
- `level_complete_screen.dart:43` — `'You did it! Amazing!'`.
- `good_job_screen.dart:29` — `'Wow! Good job!'` (milder, but still a global judgment,
  not a description of what happened).
- None of these say *what the child did* ("you found the B!", "you traced the curve!").
  All are generic, exclamation-heavy, judgment-style praise — the exact anti-pattern
  the domain doc calls out by name ("you're so smart!" vs. "you traced the whole
  curve!") and that CLAUDE.md forbids outright ("never 'Perfect!!', 'Amazing!!'"). This
  is not a one-off slip; the identical phrase appears independently in two files and a
  close variant in a third, suggesting it's the default praise pattern across the app,
  not an isolated bug.

**Why it matters:** Per §2, well-timed reward *is* landing (good); per §3, it's
teaching the wrong lesson while it does ("you're amazing" isn't earned or specific, and
loses meaning with repetition, per the domain doc's own warning about over-praise).

**Fix:** Replace the four strings above with copy that names the specific action or
skill (e.g. "You found the B!", "You drew the whole A!", using the level/letter/shape
name already available in scope at each call site). **Effort: S** (four string
literals, all the data needed to make them descriptive is already in local scope).

---

## Item 9 — The child never sees technical/error/auth text; those live on parent screens

**Verdict: PASS**

**Evidence:** No stack traces, HTTP status codes, or exception text found in any
child-facing screen. Auth/network failures (register/login/refresh) surface only on
`ParentSignupScreen`/`LoginScreen`, which are reached before a child is ever selected,
and are swallowed silently everywhere else (`ProgressRepository.sync()`,
`SyncService.pullProfile()`, `TelemetryService._flush()` all catch and drop errors per
the code comments). Child-facing "can't do that yet" messaging
(`levels_screen.dart:121-129` "🔒 Complete Letters level to unlock!",
`shop_screen.dart:57-67` "Not enough stars!") is plain, friendly language — not
technical, even though (per Item 6) its *color* is wrong.

No fix needed for this item specifically (see Item 6 for the color issue on the same
surfaces).

---

## Item 10 — A parent/teacher settings surface exposes: target size, timing/pace, sound on/off, difficulty/errorless mode, and TTS voice/language

**Verdict: FAIL** — the cleanest, most complete failure in this audit.

**Evidence:**
- `lib/screens/profile_screen.dart:190-236` is the entire Settings surface (inside a
  `FkParentGate`-protected, correctly parent-facing "Parent dashboard" screen). It
  contains exactly:
  - `profile_screen.dart:202` — `_settingsBtn('Language 🇺🇸', () {})` — **a completely
    empty callback.** Tapping this button does nothing. It's not a stub screen, not a
    "coming soon" toast — the `onPressed` is a no-op closure.
  - `profile_screen.dart:206` — sign out (functional, not one of the five required
    controls).
  - `profile_screen.dart:226-235` — a volume `Slider` wired to
    `TtsService.setVolume`/`SoundService.setVolume` — functional, and the closest thing
    to a "sound on/off" control (dragging to 0 achieves silence, though there's no
    explicit toggle).
- Checked against the five things §5 requires this surface to expose:
  - **Target size** — absent. No control anywhere in the app changes any tap-target or
    key size.
  - **Timing/pace** — absent. No control anywhere adjusts delays, question count, or
    session pacing.
  - **Sound on/off** — partial, via the volume slider only.
  - **Difficulty/errorless mode** — absent. No such toggle exists.
  - **TTS voice/language** — a button exists and is visually present, but is
    non-functional; and per Item 7, the underlying TTS is English-only regardless, so
    even a working button couldn't currently deliver on this today.

**Why it matters:** This is the one §5 item that's explicitly about *caregiver
empowerment* (§5's own principle: "Caregiver involvement matters... give them the
controls"), and it's almost entirely unbuilt. Everything else in this audit is about
whether the *child's* experience degrades gracefully; this item is about whether a
*parent* can adjust it when it doesn't — and right now they can't.

**Fix:** This needs real design + implementation, not a one-line patch — genuinely
**Effort: L**. Suggested order: (1) wire the existing Language button to something —
even a placeholder that's honest about "coming soon" is better than a silent no-op, **S**;
(2) add a difficulty/errorless-mode toggle that the game screens actually read (e.g.
widen `_snapR`, disable the red wrong-highlight, extend dwell) — **M**; (3) add a target-size
slider that scales the tap targets identified in Item 1 — **M**; (4) pace/timing controls — **M**.

---

## Item 11 — Progress is saved locally and resumes exactly where the child stopped

**Verdict: PARTIAL** — level-level granularity is solid; mid-level granularity doesn't exist.

**Evidence — what's saved:**
- `UserService.completeLevel`/`setLettersStage` (SharedPreferences-backed) plus the
  newer `ProgressStore`/`ProgressRepository` (from the prior session's work) correctly
  persist *which levels are done* and survive an app restart. If a child finishes
  "Letters," that's remembered.

**Evidence — what's not saved:**
- `letters_stage1_screen.dart:24-36` — `_current`, `_selected`, `_answered`,
  `_missedLetters`, `_isRetryPhase`, `_retryLetters`, `_retryIndex` are all plain
  `State` fields.
- `letters_stage2_screen.dart:25-30` — `_wordIndex`, `_letterIndex`, `_tapped`,
  `_choices` — same.
- `shapes_screen.dart:66-74` — `_questions`, `_current`, `_tapped`, `_segments` — same.
- `letter_drawing_screen.dart:213-221` — `_letterIndex`, `_strokes`, `_current`,
  `_tapped`, `_done` — same.
- None of these are written anywhere durable. If the app is backgrounded and the OS
  reclaims memory, or the child force-closes it, or it simply crashes, **all progress
  within the current level is lost** — a child 12 questions into a 15-question level
  restarts at question 1.

**Why it matters:** §4 is explicit that fatigue is a first-class concern for CP and
that it should be "easy to pause and resume exactly where the child left off." A child
who fatigues mid-level (plausibly *more* likely for exactly the population this app
targets) loses their work, which directly contradicts both the letter and the intent of
this item.

**Fix:** Persist the handful of primitives listed above (current index, retry queue,
in-progress drawing strokes) to `SharedPreferences` on every state change or on app
pause (`AppLifecycleState.paused`), and restore them in `initState`. The shapes/letter
drawing screens (with active stroke data) are more work than the multiple-choice
screens. **Effort: M** for letters_stage1/2, **M-L** for shapes/letter_drawing (stroke
serialization).

---

## Item 12 — Skills re-appear across levels (spaced repetition), not taught once

**Verdict: FAIL**

**Evidence:**
- `levels_screen.dart:91-98` — only **6** of the product's planned 16 curriculum levels
  are implemented (`letters`, `numbers`, `colors`, `fruits`, `animals`, `food`), each a
  single, distinct, one-shot topic. Worth being explicit about, since the audit brief
  described "the levels dashboard (16 levels)" — as implemented today, it's 6.
- `letters_stage1_screen.dart:33,133-140` (`_missedLetters`, `_startRetryPhase`) *does*
  re-surface letters the child got wrong — but immediately, within the same sitting,
  not spaced across time/sessions. This is error-correction, not spaced repetition.
- No game screen calls into the backend's session/event pipeline at all —
  grepping all four game screens for `TelemetryService`, there are zero references.
  `TelemetryService.instance.init()` is called once when a child is selected
  (`auth_controller.dart:184-186`, from the prior session's work), but nothing ever
  calls `TelemetryService.instance.enqueue(...)` from actual gameplay, so the event
  queue that would feed the backend's BKT/`skill_mastery`/`repetition_queue` machinery
  (described in CLAUDE.md as central to the whole adaptive-engine product) never
  receives a single real event. The server-side spaced-repetition system exists in the
  backend and is completely disconnected from the client's actual play loop.
- Once a level is marked `done`, nothing in the client ever brings its content back.

**Why it matters:** This is arguably the deepest gap in the audit, because it isn't a
UI bug — it's a missing pipeline. Even if every other item here were fixed, spaced
repetition literally cannot happen today, because the signal that would drive it is
never generated.

**Fix:** Two separate pieces, and they're both larger than most fixes in this document:
(1) wire actual gameplay taps/strokes into `TelemetryService.enqueue(...)` from the four
game screens so the backend pipeline has something to work with — **Effort: L**; (2)
build a client-side "review queue" surfacing weak items from prior levels inside
new/current levels, whether sourced from the backend or computed locally from
`_missedLetters`-style local tracking — **Effort: L**. This is a multi-day project, not
a quick patch, and is out of scope for a single follow-up session.

---

## Findings beyond the §5 checklist

Ranked roughly by how directly they harm a child, most severe first.

1. **Unprotected, high-consequence reset button next to the drawing canvas.**
   (`letter_drawing_screen.dart:614-651`) — already covered in depth under Item 5; called
   out again here because it's the single worst failure mode found in this audit for
   the population §4 is about. A child with tremor drawing near the bottom of the
   canvas is exactly the child most likely to clip the eraser by accident, and the
   *only* recovery is redrawing everything from scratch.

2. **Systemic exclamation-heavy, judgment-style praise ("Amazing! Well done!").**
   Already covered under Item 8; flagged again here because it directly contradicts a
   **non-negotiable rule in CLAUDE.md itself** ("never 'Perfect!!', 'Amazing!!'"), not
   just the domain doc's softer guidance — this is a compliance gap against the
   project's own stated constraints, found in three separate files.

3. **TTS is architecturally English-only despite the app offering Uzbek and Russian as
   learning languages**, and the letters/numbers game *content* is hardcoded English
   regardless of the selected language. Covered under Item 7; flagged again because
   its impact is broader than "one accessibility checkbox" — it means two of the app's
   three advertised learning languages currently get a materially worse (or silent)
   product.

4. **Locked-level and tab-lock messaging is text-only, with no audio pairing** — e.g.
   `levels_screen.dart:272-283` ("🔒 'Letters' darajasini tugatib oching!") and
   `levels_screen.dart:121-129` — shown in a `SnackBar`, unread by TTS, to an
   explicitly pre-literate audience (§1). A locked card tapped directly
   (`levels_screen.dart:391`, `onTap: level.locked ? null : ...`) produces **no
   feedback of any kind** — not even the snackbar the locked *tab* gets — so a child
   repeatedly tapping a locked level card gets pure silence, which can read as "this is
   broken" rather than "not yet."

5. **The level-unlock chain is strictly linear with exactly one unlockable level at a
   time** (`levels_screen.dart:78-89`, `_stateOf`). §3's explicit design rule is
   "offer bounded choices" ("do you want the red star or the blue star?") because
   autonomy-within-limits measurably improves engagement — the current dashboard never
   offers the child a choice between two available activities; there is only ever one.
   Not one of the 12 checklist items verbatim, but a direct §3 principle this
   structurally can't satisfy.

6. **No screen in the gameplay path respects `MediaQuery.disableAnimations`
   (reduced-motion).** `FkTheme.reducedMotion()` (`fk_theme.dart:79-81`) exists and is
   correctly checked inside `FkButton`, but none of the four game screens, `good_job`,
   or `level_complete` import `fk_theme.dart` at all — their pulse animations, elastic
   bounce-ins, and confetti (`letter_drawing_screen.dart:976-989`) run unconditionally.
   Relevant to §4's note that sensory processing varies alongside motor ability.

7. **`profile_screen.dart:408-435` "Sign out" only clears local `SharedPreferences`
   (`UserService.signOut()`) and does not touch the backend session in
   `SecureTokenStore`.** Not a child-safety issue, but worth a mention: a parent who
   signs out via this button is not actually logged out of their backend account —
   tokens remain in secure storage. Adjacent to Item 10's "parent controls should do
   what they say."

8. **The "Needs practice → Practice" button always routes to `/game_stage1`**
   (`profile_screen.dart:150`) regardless of what data (if any) suggests that's the
   actual weak area — cosmetic/functional rather than an accessibility issue, noted for
   completeness since I read the file in full.

---

## What's already good (said plainly, not just to balance the ledger)

- **No hard time limits or speed-dependent mechanics anywhere** (Items 2 and 4) — this
  is a real, clean pass across the entire audited surface, not a near-miss.
- **The accuracy/scoring math on both tracing screens genuinely rewards imperfect
  strokes** (Item 3's scoring half) — the 0–10 distance-based mapping is a sound
  design, independent of the gating-radius problem.
- **The synthesized "wrong" sound is thoughtfully built to be gentle** — soft envelope,
  blended waveform, quieter than the "correct" sound, not a harsh alarm (Item 6's audio
  half).
- **No technical or auth text ever reaches the child** (Item 9) — every network/auth
  failure path traced back to a silent catch or a parent-only screen.
- **The design system's touch-target constant is correct and is properly enforced
  where it's used** (`FkTouchTargets.child = 64` + `FkButton`'s `minHeight`) — the
  problem is coverage, not the standard itself.
- **`letter_drawing_screen.dart`'s "Ko'rsatib ber" (show me) demo animation** is a
  genuinely good scaffolding feature — modeling the correct stroke before asking the
  child to attempt it — not required by any checklist item but squarely in the spirit
  of §2's multi-sensory principle.
- **Numbered dot markers** on both tracing screens reduce the cognitive load of
  remembering stroke order, which is a thoughtful accessibility-adjacent design choice
  even though it isn't a checklist item.

---

## Prioritized fix list — ranked by (impact on the child) ÷ (effort)

**Fix first (high impact, low effort — all are S, all are safe, isolated changes):**

1. **Replace judgment-style praise strings** ("Amazing! Well done!" ×2, "You did it!
   Amazing!", "Wow! Good job!") with descriptive, specific copy. Direct violation of a
   CLAUDE.md non-negotiable, four string literals, all data needed is already in scope.
   *(Item 8, Beyond-checklist #2)*
2. **Swap the red wrong-answer/insufficient-funds color** (`0xFFFF6B6B` family, 3 sites)
   for the design system's approved `attention` yellow or a neutral tone. Pure color
   constant swap. *(Item 6)*
3. **Widen `shapes_screen.dart`'s `_snapR` from 10 to ~25-30px** to match
   `letter_drawing_screen.dart`. One constant. *(Item 3)*
4. **Add a confirm step before the letter-drawing eraser wipes progress**, and stop the
   "undo" button from also wiping all dot-progress. The single most damaging
   interaction found in the whole audit, and the fix is small and contained. *(Item 5,
   Beyond-checklist #1)*

**Fix next (high impact, medium effort):**

5. **Resize the ~9 undersized secondary controls** (back buttons, TTS-replay icons,
   color swatches, eraser/undo, shop buy button) to at least 48-64dp with more spacing.
   Mechanical but touches 5 files. *(Item 1)*
6. **Add a short commit-delay/debounce to tap-to-answer and drag-to-snap interactions**
   across the four game screens, so a single accidental brush doesn't register.
   *(Item 5)*
7. **Give locked level cards feedback on tap** (sound + brief message), matching what
   the locked *tab* already does, instead of silence. *(Beyond-checklist #4)*

**Worth doing, but bigger (schedule deliberately, don't block on them):**

8. **Persist mid-level position** (current question/letter index, retry queue, drawn
   strokes) so a killed app resumes exactly where the child stopped. *(Item 11)*
9. **Wire the Language settings button to something real**, even a first pass; it is
   currently a no-op, which is worse than not having the button. *(Item 10)*
10. **Thread the child's `learningLanguage` into `TtsService`** and localize the
    letters/numbers/shapes vocabulary per language. Two-part, non-trivial, but
    high-impact for two of the app's three advertised languages. *(Item 7)*

**Genuinely large — separate projects, not follow-up patches:**

11. **Build the rest of the parent settings surface** (target size, pace, difficulty/
    errorless mode). *(Item 10)*
12. **Wire actual gameplay events into the backend telemetry/adaptive pipeline**, and/or
    build a local review queue, so spaced repetition can exist at all. *(Item 12)*
13. Implement the remaining 10 of 16 curriculum levels. *(Context for Item 12, not a
    checklist item itself.)*

---

*This audit covers the code paths listed in the request as of 2026-07-14. No production
code was modified. Line numbers refer to the current state of each file at the time of
reading and will drift as the code changes.*