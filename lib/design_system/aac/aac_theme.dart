library aac_theme;

import 'package:flutter/material.dart';
import '../fk_tokens.dart';

/// The six top-level "My Voice" AAC categories. Fixed set — see
/// docs/aac_design_system.md §1 for the color/category mapping rationale.
enum AacCategory { dailyActivities, needs, feelings, people, places, play }

/// AAC-specific sizing/timing constants not covered by [FkTouchTargets].
///
/// AAC cards are the primary interaction unit for a child who may have
/// significantly reduced motor precision, so they use a deliberately larger
/// touch-target tier than the generic child target (64px) — see
/// docs/aac_design_system.md §2-4 for the reasoning behind each value.
abstract final class AacSizes {
  static const double cardMin = 120;
  static const double cardMax = 160;
  static const double cardRadius = 28; // between FkRadii.md(24) and FkRadii.lg(32)

  static const double gridGapBeginner = FkSpacing.lg; // 32 — max 4 cards/screen
  static const double gridGapAdvanced = FkSpacing.md; // 24 — max 6 cards/screen

  /// Repeated taps within this window are ignored (tremor/accidental-touch
  /// protection) — does not apply to the deliberate "tap again to replay"
  /// affordance on the confirmation overlay.
  static const Duration tapDebounce = Duration(milliseconds: 300);

  /// Dwell-to-activate timing (opt-in parent setting, alternate trigger for
  /// severe motor impairment). Default and parent-adjustable range.
  static const Duration dwellDefault = Duration(milliseconds: 600);
  static const Duration dwellMin = Duration(milliseconds: 300);
  static const Duration dwellMax = Duration(milliseconds: 2000);

  static const Duration animationLoopMin = Duration(seconds: 3);
  static const Duration animationLoopMax = Duration(seconds: 5);
}

/// ThemeExtension for the "My Voice" AAC module. Access via
/// `AacTheme.of(context)`. Registered alongside [FkPlayTheme] in
/// `FlexiKeysTheme.light()`/`.dark()` — one more extension, not a parallel
/// theming system. Reuses [FkColors]/[FkRadii]/[FkSpacing]/[FkElevation]/
/// [FkDurations]/[FkCurves] throughout; see docs/aac_design_system.md §0 for
/// what's reused vs. newly introduced here.
class AacTheme extends ThemeExtension<AacTheme> {
  final Color background;
  final Color surface;
  final Color ink;
  final Color inkSoft;
  final Color disabled;

  // One full-saturation accent per category — reuses FkColors.playful
  // exactly (see docs/aac_design_system.md §1: six colors, six categories,
  // no new color tokens).
  final Color dailyActivities;
  final Color needs;
  final Color feelings;
  final Color people;
  final Color places;
  final Color play;

  const AacTheme({
    this.background = FkColors.lavenderMist,
    this.surface = Colors.white,
    this.ink = FkColors.inkDeep,
    this.inkSoft = FkColors.inkMedium,
    this.disabled = FkColors.playDisabled,
    this.dailyActivities = FkColors.skyBlue,
    this.needs = FkColors.leaf,
    this.feelings = FkColors.sunshine,
    this.people = FkColors.grape,
    this.places = FkColors.tangerine,
    this.play = FkColors.coral,
  });

  static const AacTheme _default = AacTheme();

  static AacTheme of(BuildContext context) {
    return Theme.of(context).extension<AacTheme>() ?? _default;
  }

  /// The full-saturation accent for [category] — use only for the
  /// icon/animation container, borders, and selection rings. Never as a
  /// text background: see docs/aac_design_system.md §1 for the computed
  /// contrast ratios behind that rule (full-saturation accents fall short
  /// of WCAG AA for label-sized text against both white and ink).
  Color colorFor(AacCategory category) {
    switch (category) {
      case AacCategory.dailyActivities:
        return dailyActivities;
      case AacCategory.needs:
        return needs;
      case AacCategory.feelings:
        return feelings;
      case AacCategory.people:
        return people;
      case AacCategory.places:
        return places;
      case AacCategory.play:
        return play;
    }
  }

  /// The soft tinted card/tile surface for [category] (~12% of the category
  /// color blended into white). Card and tile backgrounds use this, with
  /// [ink] labels on top — guarantees ≥AAA contrast on every category with
  /// one rule, no per-color exceptions. See docs/aac_design_system.md §1.
  Color tintFor(AacCategory category) => Color.alphaBlend(
        colorFor(category).withValues(alpha: 0.12),
        Colors.white,
      );

  @override
  AacTheme copyWith({
    Color? background,
    Color? surface,
    Color? ink,
    Color? inkSoft,
    Color? disabled,
    Color? dailyActivities,
    Color? needs,
    Color? feelings,
    Color? people,
    Color? places,
    Color? play,
  }) {
    return AacTheme(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      disabled: disabled ?? this.disabled,
      dailyActivities: dailyActivities ?? this.dailyActivities,
      needs: needs ?? this.needs,
      feelings: feelings ?? this.feelings,
      people: people ?? this.people,
      places: places ?? this.places,
      play: play ?? this.play,
    );
  }

  @override
  AacTheme lerp(AacTheme? other, double t) {
    if (other == null) return this;
    return AacTheme(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkSoft: Color.lerp(inkSoft, other.inkSoft, t)!,
      disabled: Color.lerp(disabled, other.disabled, t)!,
      dailyActivities: Color.lerp(dailyActivities, other.dailyActivities, t)!,
      needs: Color.lerp(needs, other.needs, t)!,
      feelings: Color.lerp(feelings, other.feelings, t)!,
      people: Color.lerp(people, other.people, t)!,
      places: Color.lerp(places, other.places, t)!,
      play: Color.lerp(play, other.play, t)!,
    );
  }
}
