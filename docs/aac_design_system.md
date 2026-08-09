# "My Voice" — AAC Module Design System (Phase 0)

> Status: **DRAFT — awaiting approval before Phase 1.**
> Scope: design tokens + interaction spec for the AAC (Augmentative and Alternative
> Communication) module. Companion doc to `docs/FLEXIKEYS_DOMAIN_KNOWLEDGE.md` §4-5
> (motor accessibility, assistive-tech principles) — read that first; this doc does
> not repeat its reasoning, only applies it to AAC-specific decisions.

## 0. Grounding: what already exists (and what this reuses)

Before inventing anything, here's what "My Voice" inherits from the existing
FlexiKeys design system (`lib/design_system/fk_tokens.dart`, `fk_theme.dart`) rather
than duplicating:

- **Palette: reuse `FkColors.playful` as-is.** It already contains exactly six
  colors — `coral #E0567B`, `skyBlue #4A90D9`, `leaf #4CAF50`, `sunshine #FFC107`,
  `grape #9C27B0`, `tangerine #FF8C42` — which map cleanly onto the six requested
  AAC categories (see §1). **No new color tokens are introduced.**
- **Theme extension pattern: matches `FkPlayTheme`.** `AacTheme` follows the exact
  same `ThemeExtension<AacTheme>` shape (`copyWith`/`lerp`/static `.of(context)`
  with a const default fallback) and is registered alongside `FkTheme()` and
  `FkPlayTheme()` in `FkTheme.themeData()`'s `extensions:` list — one more entry,
  not a parallel theming system.
- **Radii, spacing, elevation, motion durations/curves, type scale: reused from
  `FkRadii`/`FkSpacing`/`FkElevation`/`FkDurations`/`FkCurves`/`FkTextStyles`.**
  AAC-specific additions are called out explicitly in §3-4 where the existing
  tokens don't cover a need (e.g. touch targets far larger than
  `FkTouchTargets.child`).
- **Parent gate: reuse `FkParentGate` unmodified** for the "My Voice" settings
  surface (§Phase 4) — it already does exactly what's needed (math-challenge gate,
  no PII/PIN stored).
- **Tap-scale + haptic precedent: matches `FkButton`.** The card tap sequence in
  §4 mirrors `FkButton`'s existing `onTapDown` → `HapticFeedback.lightImpact()` +
  `AnimationController` scale pattern — same duration/curve tokens, extended with
  the AAC-specific full-screen confirmation step.

Two things `AacCard`'s animated-loop requirement will need that **aren't in the
codebase yet** — flagging now, not deciding now:

1. **Lottie.** There is currently zero Rive/Lottie usage anywhere in `lib/` — all
   existing motion is either simple `AnimationController` tweens (the float-loop
   in `cloud_mascot.dart`) or a custom `CustomPainter` (`MascotRenderer`). Adding
   `lottie` would be the first animation-*library* dependency in this codebase.
   This needs your explicit sign-off before Phase 2 (per your own "no new heavy
   dependencies without asking" rule) — I'll ask concretely when we get there,
   with a lightweight alternative (a small custom `CustomPainter`/sprite-frame
   loop reusing the `MascotRenderer` approach) costed out as a comparison.
2. **drift.** Not currently a dependency (the app's local storage today is
   `shared_preferences` + `flutter_secure_storage`, no embedded SQL database).
   Phase 1's offline event-logging design will need a real recommendation here
   (drift vs. a simpler append-only JSON/shared_preferences log) — flagged for
   that phase, not decided here.

---

## 1. Color system

One accent per category. Six categories, six existing `FkColors.playful` entries —
a direct, no-new-tokens match:

| Category | Color token | Hex | Family |
|---|---|---|---|
| 🟦 Daily Activities | `FkColors.skyBlue` | `#4A90D9` | blue |
| 🟩 Needs | `FkColors.leaf` | `#4CAF50` | green |
| 🟨 Feelings | `FkColors.sunshine` | `#FFC107` | yellow/amber |
| 🟪 People | `FkColors.grape` | `#9C27B0` | purple |
| 🟧 Places | `FkColors.tangerine` | `#FF8C42` | orange |
| 🩷 Play | `FkColors.coral` | `#E0567B` | pink/coral |

**Feelings → sunshine/amber is deliberate, not a placeholder default.** It keeps
difficult feelings (sad, scared, pain) inside the app's existing "attention, never
alarm" register — `sunshine` is already reserved app-wide for
attention-without-red (see CLAUDE.md: *"Sunshine — attention — never red for
children"*). A hard feeling should read as *noticed*, not as an error state.

### Contrast — computed, not assumed

The brief asks for WCAG AA minimum / AAA target on card labels. I ran the actual
sRGB contrast math (not a visual guess) before writing a rule:

| Pairing | Ratio | Passes |
|---|---|---|
| `coral` full-strength + white **or** ink text | 3.63:1 | Large text only (≥18pt) — fails AA for normal-size labels, fails AAA |
| `sunshine` full-strength + white text | 1.63:1 | Fails everything — near-invisible |
| `sunshine` full-strength + `inkDeep` text | 8.10:1 | **Passes AAA** |
| `inkDeep` (#2A2F45) text on white/near-white | 13.19:1 | Passes AAA with large margin |

The mid-luminance accents (coral, skyBlue, leaf, grape, tangerine) sit in a range
where **neither black nor white text reaches AA** at full saturation — only
`sunshine`, being light, happens to work with dark text. Rather than one rule for
five colors and a special case for the sixth, the system uses **one rule for all
six**:

> **Card and tile surfaces are a soft tint of the category color (≈10–15%
> mixed into white), never the full-saturation color as a text background.
> Labels are always `FkColors.inkDeep` on that tint. The full-saturation accent
> is reserved for the icon/animation container, a border/top-stripe, and
> selection rings — never for text backgrounds.**

This guarantees ≥AAA contrast on every label, on every category, with zero
per-color exceptions to remember or get wrong later.

**No rainbow chaos**: a Category Home screen is the only screen that shows all six
accents at once (one per tile, by design — it *is* the category picker). Every
screen reached *from* a category (Card Grid, Confirmation Overlay, Fringe screen)
uses that **one** category's accent exclusively.

---

## 2. Card anatomy

```
┌─────────────────────────────┐
│                             │  ← 28px corner radius (FkRadii.lg, upper end
│      [ANIMATION AREA]       │    of the requested 24-28px range)
│    (loop illustration,      │  ← Soft layered shadow: FkElevation.medium
│      3–5s, looping)         │    (blur 20, alpha 0.12) at rest;
│                             │    FkElevation.low while pressed (settles down,
│                             │    not up — a pressed card should feel grounded)
├─────────────────────────────┤
│        Brush Teeth          │  ← Label: FkTextStyles.playHeadline scale
│                             │    (min 24sp — exceeds the 20sp floor),
└─────────────────────────────┘    inkDeep, centered, max 2 lines
```

- **Corner radius**: 28px (`FkRadii.lg`).
- **Shadow**: `FkElevation.medium(category color)` at rest — a *tinted* shadow
  (using the category accent, not flat black) so cards feel like they belong to
  their category even in the drop shadow. `FkElevation.low` while pressed.
- **Animation area**: top ~65% of the card, own rounded-top container in the
  category's full-saturation accent (this is where full saturation belongs —
  a small icon-sized area, not a text background), animation content sits on top.
- **Label**: bottom ~35%, `inkDeep` on the tinted card surface, min 24sp
  (`FkTextStyles.playHeadline`-equivalent), centered, 1-2 lines, generous
  line-height for children with early reading.
- **Touch target**: see `AacSizes` in §3 — 120-160px, well above
  `FkTouchTargets.child` (64px), because AAC cards are the *primary* interaction
  unit for a child who may have significantly reduced motor precision — this is
  a deliberately larger tier, not a stylistic choice.
- **Padding**: minimum `FkSpacing.sm` (16px) inside the card at every edge.

---

## 3. Grid rules

| Level | Cards per screen | Grid | Min gap |
|---|---|---|---|
| Beginner | 4 max | 2×2 | `FkSpacing.lg` (32px) |
| Advanced | 6 max | 2×3 or 3×2 (device-width dependent) | `FkSpacing.md` (24px) |

Never more than 6 on any child-facing screen, ever — including the Category Home
(6 categories = the hard ceiling, not a starting point that grows). The gap sizes
above are **larger than typical grid gutters on purpose**: this is the
"accidental-touch protection" margin from
`docs/FLEXIKEYS_DOMAIN_KNOWLEDGE.md` §4 — a wobbly or tremor-affected tap that
lands between two 120-160px cards separated by 24-32px should land on *neither*,
not on the wrong one.

---

## 4. Motion spec

**The tap sequence is identical every single time, on every card, in every
category — predictability is the point (cause-and-effect learning for AAC
specifically depends on it):**

1. **Touch down**: `HapticFeedback.mediumImpact()` (heavier than `FkButton`'s
   `lightImpact` — this is a communicative act, not a UI button, and deserves a
   more distinct confirmation) + card scales `1.0 → 1.08` (`AnimationController`,
   `FkDurations.fast` 200ms, `FkCurves.spring` i.e. `elasticOut` — already the
   token used for "make this feel alive" elsewhere in the system).
2. **Release** (or after `AacSizes.debounce` if dwell-activated — see below):
   full-screen `ConfirmationOverlay` fades/scales in over `FkDurations.normal`
   (300ms).
3. **Overlay**: the same loop animation plays full-screen (3-5s, one full loop
   minimum, `Curves.easeInOut` transitions in/out).
4. **Voice**: the sentence is spoken (pre-generated audio, §Phase 1) — starts
   as the overlay animation begins, not after it finishes, so audio and motion
   are felt as one event.
5. **Text**: the sentence appears in large text at the bottom of the overlay
   (`FkTextStyles.playDisplay`-equivalent, min 28sp) as the voice starts,
   word-by-word reveal optional but not required for v1.
6. **Dismiss**: auto-dismiss after the loop completes, **or** a large "✓" button
   (`AacSizes.cardMax`-equivalent tap target, bottom-center) for a child who wants
   to replay/confirm manually, **or** a smaller "back" affordance (top-left, still
   ≥64px) if the tap was a mistake.

**Accidental-touch debounce**: repeated taps within 300ms are ignored (matches the
domain doc's explicit debounce requirement) — this applies to the *first* tap
registering, not to the deliberate "tap again to replay" affordance in step 6.

**Dwell-time activation** (opt-in, parent setting, for severe motor impairment):
replaces "touch down → immediate scale-up" with "touch down → progress ring fills
over `dwellDuration` (default 600ms, parent-adjustable 300-2000ms) → activates on
completion, cancels if finger lifts early." This is an alternate *trigger*, not a
different card — steps 2-6 are unchanged once triggered.

**Reduced-motion variant** (system `MediaQuery.disableAnimations`, same check
`FkButton` already makes): every animated step above has a static equivalent —
scale-up becomes a static highlight border, the loop animation becomes a single
static frame of the same illustration, overlay transitions become instant cuts.
Voice and text timing are unchanged (motion reduction never removes the
communication payload, only the movement).

---

## 5. Typography & spacing (all reused, none new)

| Token | Value | AAC usage |
|---|---|---|
| `FkTextStyles.playDisplay` | 40sp/w800 | Confirmation overlay sentence text |
| `FkTextStyles.playHeadline` | 28sp/w800 | Card labels, category tile labels |
| `FkTextStyles.playLabel` | 20sp/w700 | Fringe-screen option labels |
| `FkSpacing.*` | 4/8/16/24/32/48 | All layout spacing — see §3 for grid-specific minimums |
| `FkRadii.lg` | 32px | Card corners (see §2: using 28px, between `md` 24 and `lg` 32 — will define `AacRadii.card = 28.0` as a named exception, documented in code, not a silent magic number) |

## 6. Elevation & motion tokens (all reused, none new)

`FkElevation.low/medium`, `FkDurations.fast/normal/slow`,
`FkCurves.standard/spring/gentle` — used exactly as documented in §2 and §4 above.
No new elevation or duration tokens are needed for Phase 0.

---

## Open questions for you before Phase 1

1. **Lottie vs. custom-drawn animation** (§0) — which direction, or do you want to
   see a cost/quality comparison first?
2. **drift vs. simpler local storage** for offline usage-event logging (§0) — same,
   flagging now so it's not a surprise in Phase 1.
3. Card radius: I landed on 28px as a named `AacRadii.card` constant rather than
   reusing `FkRadii.lg` (32px) exactly — confirming that's fine rather than
   silently picking a number outside your existing scale.
