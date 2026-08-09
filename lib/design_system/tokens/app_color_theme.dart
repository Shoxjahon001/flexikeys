library app_color_theme;

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Theme-aware counterpart to [AppColors].
///
/// [AppColors] stays a flat static-const class — that was a deliberate
/// Phase 1 choice ("no `.of(context)` needed") and every screen migrated
/// off `FkTheme` in Phase 1 reads it directly. That's frozen, documented
/// debt, not something this file retroactively fixes.
///
/// Starting Phase 2, every NEW component must read colors from here —
/// `AppColorTheme.of(context)` or the `context.colors` shorthand below —
/// instead of `AppColors.xxx` directly. `FlexiKeysTheme.dark()` is real and
/// registers [dark] as this extension, but nothing wires `themeMode` to it
/// yet (see CLAUDE.md: dark mode is deliberately dormant, not shipped). The
/// entire point of routing new components through this extension instead of
/// the static class is that turning dark mode on later becomes flipping
/// `themeMode`, not another file-by-file migration — which is exactly the
/// `FkTheme` situation Phase 1 spent its whole budget escaping.
class AppColorTheme extends ThemeExtension<AppColorTheme> {
  final Color primary;
  final Color primaryPressed;
  final Color primarySoft;

  final Color background;
  final Color surface;
  final Color surfaceMuted;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  final Color border;

  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color danger;
  final Color dangerSoft;
  final Color info;
  final Color infoSoft;

  const AppColorTheme({
    required this.primary,
    required this.primaryPressed,
    required this.primarySoft,
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.danger,
    required this.dangerSoft,
    required this.info,
    required this.infoSoft,
  });

  /// Mirrors [AppColors]'s light values exactly.
  static const AppColorTheme light = AppColorTheme(
    primary: AppColors.primary,
    primaryPressed: AppColors.primaryPressed,
    primarySoft: AppColors.primarySoft,
    background: AppColors.background,
    surface: AppColors.surface,
    surfaceMuted: AppColors.surfaceMuted,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textTertiary: AppColors.textTertiary,
    border: AppColors.border,
    success: AppColors.success,
    successSoft: AppColors.successSoft,
    warning: AppColors.warning,
    warningSoft: AppColors.warningSoft,
    danger: AppColors.danger,
    dangerSoft: AppColors.dangerSoft,
    info: AppColors.info,
    infoSoft: AppColors.infoSoft,
  );

  /// [AppColors] only defines dark *neutrals* (canvas/surface/text/border) —
  /// the "soft" accent tints (`successSoft` etc.) have no dark-mode value
  /// declared anywhere yet. Rather than invent literal hex here, each is
  /// derived by blending the light accent at low opacity onto the dark
  /// surface, which is a defensible placeholder but NOT a designer-approved
  /// value — flag it if/when Phase 2 actually ships a dark toggle.
  static final AppColorTheme dark = AppColorTheme(
    primary: AppColors.primary,
    primaryPressed: AppColors.primaryPressed,
    primarySoft: _darkSoft(AppColors.primary),
    background: AppColors.darkCanvas,
    surface: AppColors.darkSurface,
    surfaceMuted: AppColors.darkSurfaceMuted,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textTertiary: AppColors.darkTextTertiary,
    border: AppColors.darkBorder,
    success: AppColors.success,
    successSoft: _darkSoft(AppColors.success),
    warning: AppColors.warning,
    warningSoft: _darkSoft(AppColors.warning),
    danger: AppColors.danger,
    dangerSoft: _darkSoft(AppColors.danger),
    info: AppColors.info,
    infoSoft: _darkSoft(AppColors.info),
  );

  static Color _darkSoft(Color accent) =>
      Color.alphaBlend(accent.withValues(alpha: 0.18), AppColors.darkSurface);

  static AppColorTheme of(BuildContext context) =>
      Theme.of(context).extension<AppColorTheme>() ?? light;

  @override
  AppColorTheme copyWith({
    Color? primary,
    Color? primaryPressed,
    Color? primarySoft,
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? border,
    Color? success,
    Color? successSoft,
    Color? warning,
    Color? warningSoft,
    Color? danger,
    Color? dangerSoft,
    Color? info,
    Color? infoSoft,
  }) {
    return AppColorTheme(
      primary: primary ?? this.primary,
      primaryPressed: primaryPressed ?? this.primaryPressed,
      primarySoft: primarySoft ?? this.primarySoft,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      border: border ?? this.border,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      warning: warning ?? this.warning,
      warningSoft: warningSoft ?? this.warningSoft,
      danger: danger ?? this.danger,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      info: info ?? this.info,
      infoSoft: infoSoft ?? this.infoSoft,
    );
  }

  @override
  AppColorTheme lerp(ThemeExtension<AppColorTheme>? other, double t) {
    if (other is! AppColorTheme) return this;
    return AppColorTheme(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryPressed: Color.lerp(primaryPressed, other.primaryPressed, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      border: Color.lerp(border, other.border, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSoft: Color.lerp(warningSoft, other.warningSoft, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerSoft: Color.lerp(dangerSoft, other.dangerSoft, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoSoft: Color.lerp(infoSoft, other.infoSoft, t)!,
    );
  }
}

/// `context.colors.primary` shorthand for [AppColorTheme.of].
extension AppColorThemeContext on BuildContext {
  AppColorTheme get colors => AppColorTheme.of(this);
}
