library app_radius;

import 'package:flutter/material.dart';

/// Corner-radius scale. The old codebase had 16 distinct ad-hoc radius
/// values in play (see Phase 0 audit) — every rounded corner in the app
/// must map onto one of these five.
abstract final class AppRadius {
  static const double sm = 12; // chips, inputs
  static const double md = 16; // small cards, list rows
  static const double lg = 20; // grid cards
  static const double xl = 28; // hero image frames, sheets
  static const double pill = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
}
