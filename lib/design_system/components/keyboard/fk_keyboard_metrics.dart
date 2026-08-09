library fk_keyboard_metrics;

import 'dart:ui' show Size;

import '../../../features/adaptive/adaptive_profile.dart';
import '../../../features/keyboard/keyboard_layouts.dart';

/// Keyboard key geometry — extracted verbatim from `FkKeyboard`/`_KeyWidget`
/// (Phase 1 design-system unification), values byte-for-byte identical to
/// what shipped before this file existed.
///
/// **Why this is exempt from the app's 4pt spacing scale
/// (`AppSpacing`/`AppRadius`) and from any color/typography token
/// migration:** key width/height/padding/touch-target-minimum are ergonomic
/// constraints — finger size, device DPI, and the adaptive-profile math
/// that drives the accessibility feature this keyboard exists for (bigger
/// keys for a child who mis-taps, more spacing for one who double-fires,
/// etc.) — not visual-design choices. Snapping them onto a generic spacing
/// scale would mean the design system silently overriding a documented
/// accessibility/ergonomics decision every time that scale changes for
/// unrelated reasons. So these numbers are pinned here, standalone, with no
/// dependency on any token file (old or new) — the *only* place in the app
/// where a literal pixel constant is intentional, not debt.
///
/// `FkKeyboard`'s *skin* (colors, text style) is NOT exempt — it now reads
/// `AppColors`/`AppTypography` like every other widget. Only this file's
/// geometry is frozen.
abstract final class FkKeyboardMetrics {
  /// Un-scaled key width, before `profile.keyScale`/`widthFactor`/
  /// per-key overrides are applied.
  static const double baseKeyWidth = 36.0;

  /// Un-scaled key height, before `profile.keyScale`/per-key overrides.
  static const double baseKeyHeight = 48.0;

  /// A scaled-up key's height is clamped to at least this — matches
  /// `FkTouchTargets.child` today, frozen independently: see class doc.
  static const double minTouchTarget = 64.0;

  /// Base spacing unit the keyboard's own padding is derived from —
  /// matches `FkSpacing.xs` today, frozen independently: see class doc.
  static const double basePaddingUnit = 8.0;

  static const double baseKeyFontSize = 18.0;
  static const double minKeyFontSize = 14.0;
  static const double maxKeyFontSize = 28.0;

  /// The keyboard's own outer padding (`FkKeyboard.build`'s
  /// `EdgeInsets.all(...)`).
  static double outerPadding(AdaptationProfile profile) =>
      basePaddingUnit * profile.keySpacing;

  /// Per-row vertical padding and per-key padding — same formula at both
  /// call sites in the original widget, kept as one function since they
  /// were never actually different values.
  static double innerSpacing(AdaptationProfile profile) =>
      basePaddingUnit / 2 * profile.keySpacing;

  /// A single key's rendered size for [keyDef] under [profile].
  /// [isBackspace] mirrors `_KeyWidgetState._isBackspace` — the backspace
  /// key ignores any per-key scale override.
  static Size keySize({
    required AdaptationProfile profile,
    required KeyDef keyDef,
    required bool isBackspace,
  }) {
    final baseW = baseKeyWidth * profile.keyScale;
    final baseH = baseKeyHeight * profile.keyScale;

    final perKeyScale = isBackspace
        ? 1.0
        : (profile.keyScalePerKey[keyDef.value] ?? 1.0);

    final keyW = baseW * keyDef.widthFactor * perKeyScale;
    final keyH = baseH * perKeyScale;
    // Only height is floored to the touch-target minimum, and only once
    // the profile has scaled up at all — matches the original exactly
    // (width is never clamped).
    final effectiveH = profile.keyScale >= 1.0
        ? keyH.clamp(minTouchTarget, double.infinity)
        : keyH;

    return Size(keyW, effectiveH);
  }

  /// The key label's font size for [profile].
  static double keyFontSize(AdaptationProfile profile) =>
      (baseKeyFontSize * profile.keyScale).clamp(minKeyFontSize, maxKeyFontSize);
}
