library app_colors;

import 'package:flutter/material.dart';

/// The single color palette for FlexiKeys — extracted from the "My Voice"
/// reference mockup (2026 visual redesign). Every screen references these;
/// never a raw `Color(0xFF...)` literal outside this file.
///
/// This supersedes the old `FkColors` legacy palette. The one deliberate,
/// documented exception to "every color comes from here" is
/// `lib/design_system/components/keyboard/fk_keyboard_metrics.dart`, which
/// governs *geometry* (key sizes/spacing), not color — its skin still comes
/// from [AppColors]/`AppTypography` like everywhere else.
abstract final class AppColors {
  // ── Light ────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF6D4AFF);
  static const Color primaryPressed = Color(0xFF5533E0);
  static const Color primarySoft = Color(0xFFEFE9FF);

  static const Color background = Color(0xFFF7F6FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF2F1F7);

  static const Color textPrimary = Color(0xFF1C1B2E);
  static const Color textSecondary = Color(0xFF6B6880);
  static const Color textTertiary = Color(0xFF9A97AD);

  static const Color border = Color(0xFFE8E6F0);

  static const Color success = Color(0xFF34C77B);
  static const Color successSoft = Color(0xFFE3F7EC);
  static const Color warning = Color(0xFFFFB020);
  static const Color warningSoft = Color(0xFFFFF3DA);
  static const Color danger = Color(0xFFFF5A5F);
  static const Color dangerSoft = Color(0xFFFFE5E6);
  static const Color info = Color(0xFF3DA9FC);
  static const Color infoSoft = Color(0xFFE3F1FE);

  // ── Dark ─────────────────────────────────────────────────────────────────
  // No pure black — see CLAUDE.md redesign section. Everything else keeps
  // the same hue relationships as light mode.
  static const Color darkCanvas = Color(0xFF14131C);
  static const Color darkSurface = Color(0xFF1E1D2A);
  static const Color darkSurfaceMuted = Color(0xFF262533);
  static const Color darkTextPrimary = Color(0xFFF4F3F9);
  static const Color darkTextSecondary = Color(0xFFACA9BE);
  static const Color darkTextTertiary = Color(0xFF7C7991);
  static const Color darkBorder = Color(0xFF32303F);

  /// One `(background, foreground)` pair per category card color. Never
  /// place a pastel background behind small text without its paired
  /// foreground — see CLAUDE.md accessibility section (contrast ≥ 4.5:1).
  static const List<(Color background, Color foreground)> categoryPalette = [
    (Color(0xFFD9EAFB), Color(0xFF1F5D8F)), // blue
    (Color(0xFFFDF0CE), Color(0xFF8A6412)), // yellow
    (Color(0xFFDCF2DE), Color(0xFF256B37)), // green
    (Color(0xFFEADDF9), Color(0xFF5B3A8C)), // lilac
    (Color(0xFFFBE3D3), Color(0xFF8F4C22)), // peach
    (Color(0xFFFBD9DE), Color(0xFF8F2C41)), // pink
  ];
}
