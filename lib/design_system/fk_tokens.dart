library fk_tokens;

import 'package:flutter/material.dart';

/// Color tokens. Every screen must reference these — never a raw
/// `Color(0xFF...)` literal.
///
/// This file holds two palettes side by side:
/// - The **legacy** raw colors + semantic aliases (unchanged) — consumed
///   directly by lib/features/{parent,teacher,rewards,lesson,drawing}/**.
///   The 3 auth screens and fk_keyboard.dart no longer depend on these —
///   they moved to the token system in lib/design_system/tokens/ (see
///   [AppColors] and friends) when `FkTheme` was retired. Do not repoint
///   these legacy aliases; they still back the screens listed above.
/// - The **redesign** palette (2026 visual refresh) — punchy, saturated
///   brand colors over soft surfaces, matching docs/CLAUDE.md's Design
///   System section. New/redesigned screens should use [FkPlayTheme]
///   (see fk_theme.dart), which is built from these.
abstract final class FkColors {
  // ── Legacy raw palette (unchanged — do not edit) ────────────────────────
  static const Color sky = Color(0xFFA8D8EA);
  static const Color cloud = Color(0xFFFDFDFB);
  static const Color mint = Color(0xFFB8E6C9);
  static const Color warmYellow = Color(0xFFFFE7A0);
  static const Color lavender = Color(0xFFD9D2F0);
  static const Color peach = Color(0xFFFFD9C7);
  static const Color ink = Color(0xFF4A5568);
  static const Color inkSoft = Color(0xFF718096);

  // Disabled / muted (legacy)
  static const Color disabled = Color(0xFFCBD5E0);
  static const Color disabledInk = Color(0xFFA0AEC0);

  // Legacy semantic aliases — drive FkTheme's defaults; do not repoint.
  static const Color background = sky;
  static const Color surface = cloud;
  static const Color primary = lavender;
  static const Color success = mint;
  static const Color attention = warmYellow; // never red for children
  static const Color accent = peach;

  // ── Redesign palette (2026 visual refresh) ──────────────────────────────
  static const Color indigo = Color(0xFF6C63E0); // brand primary
  static const Color skyBlue = Color(0xFF4A90D9); // brand secondary
  static const Color coral = Color(0xFFE0567B); // brand accent
  static const Color leaf = Color(0xFF4CAF50); // success
  static const Color sunshine = Color(0xFFFFC107); // attention — never red
  static const Color grape = Color(0xFF9C27B0); // playful extra
  static const Color tangerine = Color(0xFFFF8C42); // playful extra
  static const Color lavenderMist = Color(0xFFE8ECFA); // background
  static const Color inkDeep = Color(0xFF2A2F45); // primary text
  static const Color inkMedium = Color(0xFF6B7186); // secondary text
  static const Color playDisabled = Color(0xFFBEC5D8);
  static const Color playDisabledInk = Color(0xFFAEB4C8);

  /// Rainbow swatch row for color pickers, confetti, and decorative
  /// accents — always draw from this list rather than inventing a hue
  /// inline.
  static const List<Color> playful = [
    coral, skyBlue, leaf, sunshine, grape, tangerine,
  ];
}

abstract final class FkRadii {
  static const double xs = 10; // new — chips, small icon buttons
  static const double sm = 16;
  static const double md = 24;
  static const double lg = 32;
  static const double pill = 999;

  static const BorderRadius xsAll = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
}

abstract final class FkSpacing {
  static const double xxs = 4; // new — tight icon padding
  static const double xs = 8;
  static const double sm = 16;
  static const double md = 24;
  static const double lg = 32;
  static const double xl = 48;
}

abstract final class FkElevation {
  /// Soft diffuse shadow — low opacity, large blur radius.
  static List<BoxShadow> low(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.10),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> medium(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.12),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];
}

abstract final class FkDurations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);
}

abstract final class FkCurves {
  static const Curve standard = Curves.easeOutCubic;
  static const Curve spring = Curves.elasticOut;
  static const Curve gentle = Curves.easeInOut;
}

/// Child touch targets ≥ 64×64dp. Adult targets ≥ 44dp.
abstract final class FkTouchTargets {
  static const double child = 64;
  static const double adult = 44;
}

abstract final class FkTextStyles {
  // Child UI — large, rounded, friendly
  static const TextStyle childDisplay = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 40,
    fontWeight: FontWeight.w800,
    color: FkColors.ink,
    height: 1.15,
  );
  static const TextStyle childHeadline = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: FkColors.ink,
    height: 1.2,
  );
  static const TextStyle childLabel = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: FkColors.ink,
    height: 1.3,
  );
  static const TextStyle childBody = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: FkColors.ink,
    height: 1.4,
  );

  // Adult UI — denser but still rounded
  static const TextStyle adultHeadline = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: FkColors.ink,
  );
  static const TextStyle adultLabel = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: FkColors.ink,
  );
  static const TextStyle adultBody = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: FkColors.inkSoft,
  );
  static const TextStyle adultCaption = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: FkColors.inkSoft,
  );

  // ── Redesign text styles ─────────────────────────────────────────────────
  // Same size/weight hierarchy as the child.* scale above, but colored with
  // the redesign ink tones and adding a "hero" tier for celebration moments
  // (level-complete, good-job interstitials).
  static const TextStyle heroDisplay = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 44,
    fontWeight: FontWeight.w900,
    color: FkColors.inkDeep,
    height: 1.1,
  );
  static const TextStyle playDisplay = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 40,
    fontWeight: FontWeight.w800,
    color: FkColors.inkDeep,
    height: 1.15,
  );
  static const TextStyle playHeadline = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: FkColors.inkDeep,
    height: 1.2,
  );
  static const TextStyle playLabel = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: FkColors.inkDeep,
    height: 1.3,
  );
  static const TextStyle playBody = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: FkColors.inkDeep,
    height: 1.4,
  );
  static const TextStyle playCaption = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: FkColors.inkMedium,
    height: 1.3,
  );
}