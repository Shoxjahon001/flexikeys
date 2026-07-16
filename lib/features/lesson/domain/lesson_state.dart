library lesson_state;

import '../../curriculum/curriculum_models.dart';

/// Phases of the lesson state machine.
/// loadPlan → presentItem → awaitInput → evaluate → feedback
///   → (repeat item | nextItem) → celebrate → summary
enum LessonPhase {
  loadPlan,
  presentItem,
  awaitInput,
  evaluate,
  feedback,
  celebrate,
  summary,
}

/// Per-item attempt record (what the child typed, how many misses).
class ItemAttempt {
  final String itemId;
  final String skillKey;
  final int missCount;
  final bool assisted; // completed with hint/auto-fill
  final int coinsEarned;
  final int durationMs;

  const ItemAttempt({
    required this.itemId,
    required this.skillKey,
    required this.missCount,
    required this.assisted,
    required this.coinsEarned,
    required this.durationMs,
  });
}

/// The immutable state held by [LessonController].
class LessonState {
  final LessonPhase phase;

  /// All items to present in this lesson (new + spaced-repetition reviews).
  final List<CurriculumItem> items;

  /// Index of the current item in [items].
  final int currentIndex;

  /// Letters the child has typed correctly so far for the current item.
  final List<String> typedSoFar;

  /// How many wrong keystrokes on the current item without reset.
  final int missCountCurrent;

  /// Completed attempts, one per item.
  final List<ItemAttempt> attempts;

  /// Total coins accumulated this session.
  final int totalCoins;

  /// Total stars earned this lesson (1–3, personal improvement).
  final int starsEarned;

  /// Whether a break has been suggested (from session_pacing).
  final bool breakSuggested;

  /// Whether the child acknowledged the break and wants to continue.
  final bool breakDismissed;

  /// Milliseconds since lesson start (for session pacing).
  final int elapsedMs;

  /// Session started time (epoch ms).
  final int sessionStartMs;

  const LessonState({
    this.phase = LessonPhase.loadPlan,
    this.items = const [],
    this.currentIndex = 0,
    this.typedSoFar = const [],
    this.missCountCurrent = 0,
    this.attempts = const [],
    this.totalCoins = 0,
    this.starsEarned = 0,
    this.breakSuggested = false,
    this.breakDismissed = false,
    this.elapsedMs = 0,
    this.sessionStartMs = 0,
  });

  CurriculumItem? get currentItem =>
      currentIndex < items.length ? items[currentIndex] : null;

  bool get isLastItem => currentIndex >= items.length - 1;

  bool get lessonComplete => currentIndex >= items.length;

  /// Target text for the current item (the word/letter to type).
  String get currentTargetText => currentItem?.l10n.text ?? '';

  /// Number of correct chars typed so far.
  int get typedCount => typedSoFar.length;

  /// Total chars needed in current item.
  int get totalChars => currentTargetText.length;

  LessonState copyWith({
    LessonPhase? phase,
    List<CurriculumItem>? items,
    int? currentIndex,
    List<String>? typedSoFar,
    int? missCountCurrent,
    List<ItemAttempt>? attempts,
    int? totalCoins,
    int? starsEarned,
    bool? breakSuggested,
    bool? breakDismissed,
    int? elapsedMs,
    int? sessionStartMs,
  }) {
    return LessonState(
      phase: phase ?? this.phase,
      items: items ?? this.items,
      currentIndex: currentIndex ?? this.currentIndex,
      typedSoFar: typedSoFar ?? this.typedSoFar,
      missCountCurrent: missCountCurrent ?? this.missCountCurrent,
      attempts: attempts ?? this.attempts,
      totalCoins: totalCoins ?? this.totalCoins,
      starsEarned: starsEarned ?? this.starsEarned,
      breakSuggested: breakSuggested ?? this.breakSuggested,
      breakDismissed: breakDismissed ?? this.breakDismissed,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      sessionStartMs: sessionStartMs ?? this.sessionStartMs,
    );
  }
}