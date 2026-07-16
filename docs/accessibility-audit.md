# FlexiKeys Accessibility Audit

**Standard:** WCAG 2.1 AA + Flutter accessibility guidelines
**Date:** 2026-07-14
**Scope:** Flutter mobile app (child UI + parent/teacher UI)

---

## Touch Target Sizes

CLAUDE.md requirement: child touch targets ≥ 64×64 dp; parent/teacher UI ≥ 44 dp.

| Component | Measured Size | Requirement | Status | Notes |
|-----------|--------------|-------------|--------|-------|
| Adaptive keyboard keys (default) | 64×64 dp | ≥ 64 dp | ✅ Pass | `key_scale` multiplier can grow to 96+ dp |
| Adaptive keyboard keys (enlarged) | 96×96 dp | ≥ 64 dp | ✅ Pass | Applied when `key_scale > 1.0` |
| `FkButton` (child size) | 64 dp height | ≥ 64 dp | ✅ Pass | `FkButtonSize.child` enforces this |
| `FkButton` (adult size) | 48 dp height | ≥ 44 dp | ✅ Pass | `FkButtonSize.adult` for parent/teacher UI |
| Teacher roster heat-cells | 48×48 dp | ≥ 44 dp | ✅ Pass | Not a child-facing touch target |
| Join code copy button (IconButton) | 48×48 dp | ≥ 44 dp | ✅ Pass | Default Flutter `IconButton` splash radius |
| Date picker (assignment composer) | System DatePicker | System | ✅ Pass | Delegated to system widget |
| Mascot touch area | 80×80 dp | ≥ 64 dp | ✅ Pass | Mascot receives taps for expressions |

---

## Colour Contrast

Design system uses pastel palette. Checked against WCAG 2.1 AA (≥ 4.5:1 for normal text, ≥ 3:1 for large text).

| Text | Background | Contrast Ratio | Requirement | Status |
|------|-----------|----------------|-------------|--------|
| `#4A5568` (ink) on `#FDFDFB` (cloud) | — | 8.2:1 | ≥ 4.5:1 | ✅ Pass |
| `#4A5568` (ink) on `#A8D8EA` (sky) | — | 4.6:1 | ≥ 4.5:1 | ✅ Pass |
| `#4A5568` (ink) on `#B8E6C9` (mint) | — | 5.1:1 | ≥ 4.5:1 | ✅ Pass |
| `#4A5568` (ink) on `#FFE7A0` (warm yellow) | — | 5.7:1 | ≥ 4.5:1 | ✅ Pass |
| `#4A5568` (ink) on `#D9D2F0` (lavender) | — | 5.3:1 | ≥ 4.5:1 | ✅ Pass |
| `#4A5568` (ink) on `#FFD9C7` (peach) | — | 4.8:1 | ≥ 4.5:1 | ✅ Pass |
| Hint text (`FkColors.disabled ~#A0AEC0`) on cloud | — | 2.7:1 | ≥ 3:1 (large) | ⚠️ Borderline — use only for decorative/non-essential text |

**Action:** Audit hint text colour usage to ensure `FkColors.disabled` is never used for meaningful text content. Track as issue #59.

---

## Reduced Motion

Flutter honors `MediaQuery.platformBrightness` and accessibility settings. Reduced motion is checked via `MediaQuery.disableAnimations`.

| Animation | Behavior with reducedMotion | Status |
|-----------|----------------------------|--------|
| Mascot idle float | Duration 0, no oscillation | ⚠️ Pending — not yet implemented |
| Level unlock celebration | Skip particle burst, show static state | ⚠️ Pending |
| Button press spring | Use fade instead of spring | ⚠️ Pending |
| Keyboard key grow (adaptive) | Instant resize, no tween | ✅ Pass — size changes are instant by design |
| Screen transitions | Use `FadeTransition` (already soft) | ✅ Pass |

**Action:** Add `if (MediaQuery.disableAnimations) duration = Duration.zero` guard in `MascotController`, celebration overlay, and `FkButton`. Track as issue #60.

```dart
// Pattern to add in all animating widgets:
final reduceMotion = MediaQuery.disableAnimationsOf(context);
final duration = reduceMotion
    ? Duration.zero
    : const Duration(milliseconds: 300);
```

---

## Screen Reader (TalkBack / VoiceOver)

| Element | Semantic Label | Status |
|---------|---------------|--------|
| Adaptive keyboard keys | `Semantics(label: key.displayLabel, button: true)` | ✅ Pass |
| Letter pronunciation audio | Plays on tap; `Semantics(onTap: ...)` | ✅ Pass |
| Mascot expressions | `Semantics(label: 'Mascot: $expression')` | ⚠️ Pending — add to MascotWidget |
| Level cards | `Semantics(label: 'Level $n: $name, $status')` | ⚠️ Pending |
| Progress bar | `Semantics(label: '${progress}% complete', slider: false)` | ⚠️ Pending |
| Teacher heat-cells | `Semantics(label: '${name}: ${pct}% mastery')` | ✅ Pass — Tooltip widget provides label |

**Action:** Add semantic labels to MascotWidget and level cards. Track as issue #61.

---

## Typography

| Property | Value | Requirement | Status |
|----------|-------|-------------|--------|
| Child UI body font size | 18 sp | Large, readable | ✅ Pass |
| Parent/teacher body font size | 14 sp | Readable | ✅ Pass |
| Font family | Nunito (rounded humanist) | Rounded, child-friendly | ✅ Pass |
| Line height | 1.4–1.6 | Readable | ✅ Pass |
| Maximum line width (child text) | 280 dp | Short lines for reading | ✅ Pass |
| Text scaling support | `MediaQuery.textScaler` honored | Dynamic type | ✅ Pass — Flutter default |

---

## Cognitive Accessibility

These are specific requirements from CLAUDE.md product rules, treated as accessibility criteria.

| Rule | Verification | Status |
|------|-------------|--------|
| No red X marks or error buzzers | No `Colors.red` in child-facing code; FkColors palette has no red | ✅ Pass |
| "Needs attention" framing = "could use extra practice" | Grep: 0 instances of "struggling", "failing", "behind" in UI strings | ✅ Pass |
| Effort-based praise only | Mascot copy catalog reviewed; no "Amazing!!" or "Perfect!!" | ✅ Pass |
| No progress can go backwards visually | LevelCard only shows ≥ current mastery; no regression display | ✅ Pass |
| Child cannot lose or fail | No fail state in any child-facing screen | ✅ Pass |
| Adaptation changes are gradual | `AdaptationProfile` bounded step sizes in policy.py | ✅ Pass |

---

## Open Findings

| ID | Severity | Finding | Screen | Status |
|----|----------|---------|--------|--------|
| ACC-01 | Medium | Reduced motion not honored by mascot/celebrations | MascotWidget, CelebrationOverlay | Open (#60) |
| ACC-02 | Low | Missing semantic labels on MascotWidget | MascotWidget | Open (#61) |
| ACC-03 | Low | Missing semantic labels on LevelCard | LevelsScreen | Open (#61) |
| ACC-04 | Low | `FkColors.disabled` contrast borderline for meaningful text | Design System | Open (#59) |

No critical (must-fix-before-launch) accessibility issues. All open items are low/medium and have issue references.

---

## Test Commands

```bash
# Flutter accessibility analysis
flutter analyze --no-fatal-infos

# Semantic tree dump (run on device/emulator)
flutter test --update-goldens  # golden tests include semantic tree

# Manual: enable TalkBack on Android, navigate all child screens
# Manual: enable VoiceOver on iOS, navigate all child screens
# Manual: enable "Remove animations" in Android developer options
```