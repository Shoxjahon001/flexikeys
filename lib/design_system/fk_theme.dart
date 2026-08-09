library fk_theme;

import 'package:flutter/material.dart';
import 'fk_tokens.dart';

/// ThemeExtension for the 2026 visual-refresh screens (levels dashboard,
/// game/drawing/coloring screens, and anything else redesigned under that
/// pass). Access via `FkPlayTheme.of(context)`.
///
/// This is now the only theme extension left in this file — `FkTheme` (the
/// legacy pastel extension that used to live here, and used to gate the 3
/// auth screens + `fk_keyboard.dart` off this file's redesign palette) was
/// retired in the Phase 1 design-tokens unification: those screens, plus
/// every shared atom that used to read `FkTheme.of(context)`, now read
/// `AppColors`/`AppTypography` (lib/design_system/tokens/) directly instead.
/// `FkPlayTheme` itself is a separate, still-open migration target — a
/// later phase should fold it into the same token set and delete this file
/// too.
class FkPlayTheme extends ThemeExtension<FkPlayTheme> {
  final Color background;
  final Color surface;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color success;
  final Color attention;
  final Color ink;
  final Color inkSoft;
  final Color disabled;

  const FkPlayTheme({
    this.background = FkColors.lavenderMist,
    this.surface = Colors.white,
    this.primary = FkColors.indigo,
    this.secondary = FkColors.skyBlue,
    this.accent = FkColors.coral,
    this.success = FkColors.leaf,
    this.attention = FkColors.sunshine,
    this.ink = FkColors.inkDeep,
    this.inkSoft = FkColors.inkMedium,
    this.disabled = FkColors.playDisabled,
  });

  static const FkPlayTheme _default = FkPlayTheme();

  static FkPlayTheme of(BuildContext context) {
    return Theme.of(context).extension<FkPlayTheme>() ?? _default;
  }

  @override
  FkPlayTheme copyWith({
    Color? background,
    Color? surface,
    Color? primary,
    Color? secondary,
    Color? accent,
    Color? success,
    Color? attention,
    Color? ink,
    Color? inkSoft,
    Color? disabled,
  }) {
    return FkPlayTheme(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      success: success ?? this.success,
      attention: attention ?? this.attention,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      disabled: disabled ?? this.disabled,
    );
  }

  @override
  FkPlayTheme lerp(FkPlayTheme? other, double t) {
    if (other == null) return this;
    return FkPlayTheme(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      success: Color.lerp(success, other.success, t)!,
      attention: Color.lerp(attention, other.attention, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkSoft: Color.lerp(inkSoft, other.inkSoft, t)!,
      disabled: Color.lerp(disabled, other.disabled, t)!,
    );
  }
}
