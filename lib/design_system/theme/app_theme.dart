library flexikeys_theme;

import 'package:flutter/material.dart';

import '../aac/aac_theme.dart';
import '../fk_theme.dart';
import '../tokens/app_color_theme.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_typography.dart';

/// The app's root [ThemeData], built entirely from [AppColors]/
/// [AppTypography] — supersedes `FkTheme.themeData()`.
///
/// Named `FlexiKeysTheme`, not `AppTheme`: the legacy `lib/theme/app_theme.dart`
/// (a separate, unmigrated static-const color bag, still consumed by the
/// core child gameplay stack — see Phase 0 audit) already owns that class
/// name. Once every remaining consumer of the legacy file is migrated in a
/// later phase, that file can be deleted and this one can be renamed to
/// `AppTheme` — deliberately not done in Phase 1 to avoid a same-turn
/// name collision.
///
/// [FkPlayTheme] and [AacTheme] are still registered as `extensions` here
/// unchanged — they are out of scope for this phase (only `FkTheme` is
/// being retired) and every screen currently reading them via
/// `FkPlayTheme.of(context)`/`AacTheme.of(context)` must keep working
/// identically.
abstract final class FlexiKeysTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Nunito',
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      extensions: const [FkPlayTheme(), AacTheme(), AppColorTheme.light],
      textTheme: _textTheme(
        primary: AppColors.textPrimary,
        secondary: AppColors.textSecondary,
      ),
      dividerColor: AppColors.border,
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Nunito',
      scaffoldBackgroundColor: AppColors.darkCanvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        primary: AppColors.primary,
        surface: AppColors.darkSurface,
        error: AppColors.danger,
      ),
      // FkPlayTheme/AacTheme have no dark variant yet — same known gap as
      // the rest of the app (see Phase 1 report). Registering the light
      // extension values here is a deliberate placeholder, not a claim
      // that AAC/2026-redesign screens are dark-mode-correct. AppColorTheme
      // is the one extension that IS dark-correct — see app_color_theme.dart.
      extensions: [const FkPlayTheme(), const AacTheme(), AppColorTheme.dark],
      textTheme: _textTheme(
        primary: AppColors.darkTextPrimary,
        secondary: AppColors.darkTextSecondary,
      ),
      dividerColor: AppColors.darkBorder,
    );
  }

  static TextTheme _textTheme({
    required Color primary,
    required Color secondary,
  }) {
    return TextTheme(
      displayLarge: AppTypography.display.copyWith(color: primary),
      headlineLarge: AppTypography.h1.copyWith(color: primary),
      headlineMedium: AppTypography.h2.copyWith(color: primary),
      headlineSmall: AppTypography.h3.copyWith(color: primary),
      titleLarge: AppTypography.h3.copyWith(color: primary),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: primary),
      bodyMedium: AppTypography.body.copyWith(color: secondary),
      bodySmall: AppTypography.caption.copyWith(color: secondary),
      labelLarge: AppTypography.label.copyWith(color: secondary),
    );
  }
}
