library praise_copy;

/// Centralized child-facing praise copy for TTS playback.
///
/// Per docs/FLEXIKEYS_DOMAIN_KNOWLEDGE.md §3: praise describes the action —
/// it does not label the child. No "Amazing!"/"Perfect!"/"Well done!".
/// Kept in one place so these can be localized (uz/en/ru) later without
/// hunting through every game screen. This is not a full i18n system —
/// just a single source of truth for the strings until one exists.
abstract final class PraiseCopy {
  /// Shapes screen — after a shape is traced with a high accuracy score.
  static const String shapeTraced = 'You traced the shape';

  /// Letter-drawing screen — after a letter is fully traced and checked.
  static const String letterTraced = 'You traced the whole letter';

  /// Level-complete screen — shown after any level type finishes.
  static const String levelComplete = 'You finished the level';

  /// Good-job interstitial — mid-level checkpoint (letters stage 1).
  static const String midLevelCheckpoint = 'You found the letters';
}