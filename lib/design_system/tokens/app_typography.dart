library app_typography;

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Type scale for the 2026 redesign — Nunito (bundled asset, weights
/// 400/500/600/700/800/900 — see pubspec.yaml `fonts:`), full Latin +
/// Cyrillic coverage for EN/UZ/RU. Superseded from `FkTextStyles`.
///
/// Rules (see CLAUDE.md): max 2 lines for any card caption with ellipsis;
/// never below 12sp; `letterSpacing: -0.2` on [display]/[h1] only.
abstract final class AppTypography {
  static const TextStyle display = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 34,
    height: 40 / 34,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );
  static const TextStyle h1 = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 28,
    height: 34 / 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );
  static const TextStyle h2 = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static const TextStyle h3 = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle body = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 15,
    height: 22 / 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
  static const TextStyle caption = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );
  static const TextStyle label = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
  );
}
