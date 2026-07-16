library fk_theme;

import 'package:flutter/material.dart';
import 'fk_tokens.dart';

/// ThemeExtension consumed by the auth screens and fk_keyboard.dart.
/// Access via `FkTheme.of(context)`. Do not repoint its default colors —
/// see the note in fk_tokens.dart. For the 2026 visual-refresh screens, use
/// [FkPlayTheme] instead.
class FkTheme extends ThemeExtension<FkTheme> {
  final Color background;
  final Color surface;
  final Color primary;
  final Color success;
  final Color attention;
  final Color accent;
  final Color ink;
  final Color inkSoft;
  final Color disabled;

  const FkTheme({
    this.background = FkColors.background,
    this.surface = FkColors.surface,
    this.primary = FkColors.primary,
    this.success = FkColors.success,
    this.attention = FkColors.attention,
    this.accent = FkColors.accent,
    this.ink = FkColors.ink,
    this.inkSoft = FkColors.inkSoft,
    this.disabled = FkColors.disabled,
  });

  static const FkTheme _default = FkTheme();

  static FkTheme of(BuildContext context) {
    return Theme.of(context).extension<FkTheme>() ?? _default;
  }

  @override
  FkTheme copyWith({
    Color? background,
    Color? surface,
    Color? primary,
    Color? success,
    Color? attention,
    Color? accent,
    Color? ink,
    Color? inkSoft,
    Color? disabled,
  }) {
    return FkTheme(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      primary: primary ?? this.primary,
      success: success ?? this.success,
      attention: attention ?? this.attention,
      accent: accent ?? this.accent,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      disabled: disabled ?? this.disabled,
    );
  }

  @override
  FkTheme lerp(FkTheme? other, double t) {
    if (other == null) return this;
    return FkTheme(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      success: Color.lerp(success, other.success, t)!,
      attention: Color.lerp(attention, other.attention, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkSoft: Color.lerp(inkSoft, other.inkSoft, t)!,
      disabled: Color.lerp(disabled, other.disabled, t)!,
    );
  }

  /// Reduced-motion preference (from MediaQuery).
  static bool reducedMotion(BuildContext context) =>
      MediaQuery.of(context).disableAnimations;

  /// The canonical ThemeData to pass to MaterialApp.
  static ThemeData themeData() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Nunito',
      scaffoldBackgroundColor: FkColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: FkColors.lavender,
        brightness: Brightness.light,
        surface: FkColors.surface,
      ),
      extensions: const [FkTheme(), FkPlayTheme()],
      textTheme: const TextTheme(
        displayLarge: FkTextStyles.childDisplay,
        headlineLarge: FkTextStyles.childHeadline,
        titleLarge: FkTextStyles.childLabel,
        bodyLarge: FkTextStyles.childBody,
        labelLarge: FkTextStyles.adultLabel,
        bodyMedium: FkTextStyles.adultBody,
        bodySmall: FkTextStyles.adultCaption,
      ),
    );
  }
}

/// ThemeExtension for the 2026 visual-refresh screens (levels dashboard,
/// game/drawing/coloring screens, and anything else redesigned under that
/// pass). Access via `FkPlayTheme.of(context)`. Kept fully separate from
/// [FkTheme] so the punchier redesign palette never leaks into the
/// out-of-scope auth screens or fk_keyboard.dart, which stay on [FkTheme].
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