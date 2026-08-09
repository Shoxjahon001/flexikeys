library praise_copy;

import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';

/// Centralized child-facing praise copy for TTS playback.
///
/// Per docs/FLEXIKEYS_DOMAIN_KNOWLEDGE.md §3: praise describes the action —
/// it does not label the child. No "Amazing!"/"Perfect!"/"Well done!".
/// Kept in one place so these can be localized (uz/en/ru) without hunting
/// through every game screen. Every call site is inside a `State` method
/// with a live `BuildContext`, so these read straight from `AppLocalizations`
/// rather than duplicating the strings here.
abstract final class PraiseCopy {
  /// Shapes screen — after a shape is traced with a high accuracy score.
  static String shapeTraced(BuildContext context) =>
      AppLocalizations.of(context)!.praiseShapeTraced;

  /// Letter-drawing screen — after a letter is fully traced and checked.
  static String letterTraced(BuildContext context) =>
      AppLocalizations.of(context)!.praiseLetterTraced;

  /// Level-complete screen — shown after any level type finishes.
  static String levelComplete(BuildContext context) =>
      AppLocalizations.of(context)!.praiseLevelComplete;

  /// Good-job interstitial — mid-level checkpoint (letters stage 1).
  static String midLevelCheckpoint(BuildContext context) =>
      AppLocalizations.of(context)!.praiseMidLevelCheckpoint;
}
