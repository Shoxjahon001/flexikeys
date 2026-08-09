library app_motion;

import 'package:flutter/material.dart';

/// Motion tokens. Press feedback = scale to [pressScale] + shadow lift
/// (soft → lifted). Card entrance = fade + [entranceSlideOffset] slide up,
/// staggered [staggerDelay] per item.
///
/// All call sites must respect reduced motion
/// (`MediaQuery.of(context).disableAnimations`) — see [AppMotion.reduced].
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  /// Entrances (fade/slide in).
  static const Curve entrance = Curves.easeOutCubic;

  /// Screen/state transitions.
  static const Curve transition = Curves.easeInOutCubic;

  /// Press feedback (button/card tap).
  static const Curve press = Curves.elasticOut;

  static const double pressScale = 0.96;
  static const double entranceSlideOffset = 12; // px, upward
  static const Duration staggerDelay = Duration(milliseconds: 40);

  static bool reduced(BuildContext context) =>
      MediaQuery.of(context).disableAnimations;
}
