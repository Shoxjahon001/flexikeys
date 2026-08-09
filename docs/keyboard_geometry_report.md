# Keyboard geometry report — sub-48dp touch-target finding

Report only — no code changes. Persisted from the Phase 1 design-token unification
follow-up ("(b) sub-48dp key width") so it can be shared and referenced independently
of chat history. Numbers are unchanged from the original report.

## Context

`FkKeyboardMetrics.keySize` (extracted byte-for-byte from the pre-Phase-1 inline
formula) computes:

```
W = 36 × keyScale × widthFactor × perKeyScale
H = 48 × keyScale × perKeyScale, then clamped to ≥ 64 whenever keyScale ≥ 1.0
```

Real `widthFactor` values in production layouts (en/uz/ru): **1.0** (normal letter
key), **1.3** (uz `o' g' sh ch ng`), **1.4** (backspace, all 3 layouts). Policy bounds
(`shared/adaptive_policy.json`): `key_scale` 1.00 → 1.40 in steps of 0.05,
`key_scale_per_key` up to 1.50.

### No "breakpoint" axis exists

`FkKeyboardMetrics.keySize` is a pure function of `AdaptationProfile` — it never reads
`MediaQuery`/screen width. Key **size** is identical on a phone and a tablet today.
There is nothing to cross against "breakpoint"; the table below has one real axis
(adaptive profile), not two.

## 1. Full geometry table

`keyScale` × widthFactor, `perKeyScale = 1.0` (no per-key override):

| keyScale | normal (1.0×) W / H | uz-wide (1.3×) W / H | backspace (1.4×) W / H |
|---|---|---|---|
| 1.00 (default — every child starts here) | **36.0** / 64.0 ❌ | **46.8** / 64.0 ❌ | 50.4 / 64.0 ✅ |
| 1.05 | **37.8** / 64.0 ❌ | 49.1 / 64.0 ✅ | 52.9 / 64.0 ✅ |
| 1.10 | **39.6** / 64.0 ❌ | 51.5 / 64.0 ✅ | 55.4 / 64.0 ✅ |
| 1.15 | **41.4** / 64.0 ❌ | 53.8 / 64.0 ✅ | 58.0 / 64.0 ✅ |
| 1.20 | **43.2** / 64.0 ❌ | 56.2 / 64.0 ✅ | 60.5 / 64.0 ✅ |
| 1.25 | **45.0** / 64.0 ❌ | 58.5 / 64.0 ✅ | 63.0 / 64.0 ✅ |
| 1.30 | **46.8** / 64.0 ❌ | 60.8 / 64.0 ✅ | 65.5 / 64.0 ✅ |
| 1.35 | 48.6 / 64.8 ✅ | 63.2 / 64.8 ✅ | 68.0 / 64.8 ✅ |
| 1.40 (global max) | 50.4 / 67.2 ✅ | 65.5 / 67.2 ✅ | 70.6 / 67.2 ✅ |

Per-key override cases (independent of global `keyScale`):

| Case | W | Result |
|---|---|---|
| `keyScale=1.00, perKeyScale=1.25` | 45.0 | ❌ (a locally-boosted key can still be under 48dp) |
| `keyScale=1.00, perKeyScale=1.50` (max) | 54.0 | ✅ |
| `keyScale=1.40, perKeyScale=1.50` (max combined, worst case) | 75.6 | ✅ |

**Scope of the problem:** on the pure global-scale grid (27 cells: 9 `keyScale` steps
× 3 widthFactors), **8 of 27 are under 48dp**, all concentrated in one place — normal
keys are under 48dp for **7 of the 9 possible `keyScale` steps** (1.00 through 1.30
inclusive), only clearing it in the top 2 steps (1.35, 1.40). Since `key_scale` starts
at 1.00 and only reaches the top via repeated `+0.05` adaptation steps triggered by
observed struggle, **most children, most of the time — including every child before
any adaptation has fired — see sub-48dp normal keys.** This is close to the default
experience, not an edge case.

### Related finding: row width may already overflow on phones

Gap math: each key wraps itself in `Padding(EdgeInsets.all(innerSpacing))`, so
neighboring keys' padding adds rather than shares. Production usage
(`lesson_player_screen.dart` via `keyboardLayoutFor()`) always renders the full 10-key
top row — the `lessonLayout()` progressive-reveal filter exists in
`keyboard_layouts.dart` but is dead code, never called anywhere in the app.

At today's default profile, the widest row's total required width is:

```
2×outerPadding(8) + 10×keyWidth(36) + 10×2×innerSpacing(4) = 16 + 360 + 80 = 456dp
```

Common phone widths are ~360–412dp (budget Android) to ~390–428dp (recent iPhones).
**The keyboard's widest row already needs more horizontal space than most phones
have, before any touch-target fix is applied**, and there's no scroll/shrink/
`FittedBox` between `FkKeyboard` and the screen — just a plain centered `Row` of
fixed-size children. This is calculated, not empirically confirmed on a device/
simulator — but the arithmetic is reproducible from the two formulas above, and it
directly constrains option viability below: naively widening keys to fix touch
targets makes an existing width problem worse.

## 2. Options (verbatim)

**A. Raise `baseKeyWidth` (36→48+)** — smallest code change, symmetric fix. But per
the math above, a 48dp-wide 10-key row needs `16 + 480 + 80 = 576dp` — nowhere close
to fitting a phone in portrait. Not viable alone; only usable paired with B.

**B. Reduce keys visible per row** — actually wire up the existing (currently dead)
`lessonLayout()` filter so only the letters relevant to the current lesson/curriculum
stage render, plus wrap remaining full-alphabet views (free-typing, later
"Words/Sentences" stages) in either a second row or a horizontally scrollable strip.
Directly fixes both the width-fit problem and gives real room to widen keys. Biggest
option — it's a layout/product change (what's visible when), not just a constant
tweak.

**C. Tighten inter-key gap to reclaim width for wider keys** — recommended against for
this specific audience. `innerSpacing`/dwell/debounce exist specifically to stop
imprecise or tremor-driven taps from hitting the wrong neighbor; shrinking gaps to buy
width directly fights the adaptive engine's own accidental-tap mitigation. Listed only
to rule it out with reasoning, not proposed as viable.

**D. Add a width floor symmetric to the existing height floor** — `keyW.clamp(minWidth,
∞)`, same pattern as today's `keyH.clamp(64, ∞)`. Minimal, consistent code change, but
same fit problem as A: the floor value is capped by whatever actually fits on screen
for the given key count, so this doesn't remove the need to also answer "how many keys
per row."

**E. Profile-specific / progressive minimum** — instead of one static floor, make the
width floor itself part of the adaptive profile (e.g., a `key_scale_min` that ramps
from a slightly-lower "fits everyone" default toward 48dp+ as the child's actual
device width and observed motor precision allow) — most correct long-term, but is a
backend/policy change (`shared/adaptive_policy.json` + the Python policy engine), not
just a Flutter fix, and is a meaningfully bigger effort than the others.

## 3. Recommendation (verbatim)

Sequence B before A/D: fix the underlying "always render all 10 keys" behavior first
(it's already dead code waiting to be wired in — `lessonLayout()` exists but is
unused), which both resolves the overflow risk and frees enough width to raise the
floor meaningfully. Once row width is under control, add D (symmetric width clamp)
with a floor **above 48dp**, not at it — for 3–5yo (curriculum levels 1–4ish,
small-vocabulary/pre-reading), target something closer to 56–64dp to match the app's
own existing 64dp child-touch-target standard (CLAUDE.md already commits to 64dp
elsewhere, e.g. `FkKeyboardMetrics.minTouchTarget`); for 8–10yo (later levels, more
keys mastered, presumably steadier fine motor control), 48dp is more defensible as the
actual working target rather than just a compliance floor. There's currently no "age"
input anywhere in `AdaptationProfile` — this recommendation implies either inferring an
age-appropriate default from curriculum level, or accepting one floor for all ages and
letting the *existing* behavior-driven adaptation (which already grows keys further
for kids who struggle) do the rest. Leaning toward the latter (simpler, no new profile
field) but it's genuinely a product call — both are defensible.

**Treat 48dp as a floor, not a target.** These users are 3–7 year olds: small fingers
but poor motor precision, so the comfortable size is likely well above the WCAG
minimum.

---

No code has been changed for this finding yet — implementation is pending a decision
on which option(s) above to pursue.
