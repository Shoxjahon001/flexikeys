library app_shadows;

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Shadow tokens. Never use `Colors.black` shadows — everything is tinted
/// off [AppColors.textPrimary] (soft/lifted) or [AppColors.primary]
/// (primaryGlow), matching the reference mockup exactly (its rgba values
/// are this app's `textPrimary`/`primary` at reduced opacity).
abstract final class AppShadows {
  /// Default resting elevation for cards, chips, list rows.
  static final List<BoxShadow> soft = [
    BoxShadow(
      color: AppColors.textPrimary.withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  /// Pressed / hover / FAB elevation.
  static final List<BoxShadow> lifted = [
    BoxShadow(
      color: AppColors.textPrimary.withValues(alpha: 0.10),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];

  /// Play button + FAB only — the one place a colored (not neutral) glow
  /// is used.
  static final List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.28),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}
