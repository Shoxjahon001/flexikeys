library lesson_controller;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../adaptive/adaptive_profile.dart';
import '../../curriculum/curriculum_models.dart';
import '../../keyboard/fk_keyboard.dart';
import '../domain/lesson_state.dart';
import '../../../design_system/mascot/mascot_controller.dart';

/// After this many misses on one item, auto-fill remaining characters.
const _assistedThreshold = 3;

/// Flat coins per item — effort-based, never accuracy-scaled.
const _coinsPerItem = 10;

/// Session target: suggest break after 7 minutes.
const _breakSuggestMs = 7 * 60 * 1000;

/// Lesson controller — drives the typed state machine.
///
/// External callers:
///   - [loadPlan] to start a lesson
///   - [onKeystroke] to process keyboard input
///   - [dismissBreak] when child chooses to continue after break suggestion
///   - [endSession] to gracefully stop
class LessonController extends StateNotifier<LessonState> {
  LessonController(this._mascotRef) : super(const LessonState());

  final MascotController _mascotRef;

  // Tracks when the current item was first shown, for duration recording.
  int _itemShownMs = 0;

  // Callback invoked when an item is fully completed (for telemetry + rewards).
  void Function(ItemAttempt)? onItemCompleted;

  // Callback invoked when all items are done (for rewards flow).
  void Function(LessonState)? onLessonComplete;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Load a lesson plan and move to [LessonPhase.presentItem].
  void loadPlan({
    required List<CurriculumItem> items,
    required List<CurriculumItem> reviewItems,
  }) {
    final all = [...items, ...reviewItems];
    final now = DateTime.now().millisecondsSinceEpoch;
    state = state.copyWith(
      phase: LessonPhase.presentItem,
      items: all,
      currentIndex: 0,
      typedSoFar: [],
      missCountCurrent: 0,
      attempts: [],
      totalCoins: 0,
      starsEarned: 0,
      sessionStartMs: now,
      elapsedMs: 0,
    );
    _itemShownMs = now;
    _mascotRef.onLessonEvent(LessonEvent.sessionStart);
    _transitionToAwaitInput();
  }

  /// Process a keystroke from FkKeyboard.
  void onKeystroke(KeystrokeRecord record, AdaptationProfile profile) {
    if (state.phase != LessonPhase.awaitInput) return;

    final item = state.currentItem;
    if (item == null) return;

    final target = item.l10n.text;
    if (target.isEmpty) return;

    // Rejected events still log to telemetry (handled by caller) but never
    // produce negative UI feedback. Skip processing for accidental taps.
    if (record.rejectedByDwell || record.rejectedByDebounce) return;

    final expectedChar = _nextExpectedChar(target, state.typedSoFar);
    if (expectedChar == null) return;

    if (record.actualKey == expectedChar) {
      _handleCorrectKey(record, target, profile);
    } else {
      _handleWrongKey(record, profile);
    }
  }

  /// Child chose to continue after break suggestion.
  void dismissBreak() {
    state = state.copyWith(breakSuggested: false, breakDismissed: true);
  }

  /// Update elapsed time (call from a periodic timer in the UI).
  void tick(int nowMs) {
    final elapsed = nowMs - state.sessionStartMs;
    state = state.copyWith(elapsedMs: elapsed);

    // Session pacing: suggest break after threshold if not already suggested.
    if (!state.breakSuggested &&
        !state.breakDismissed &&
        elapsed >= _breakSuggestMs) {
      state = state.copyWith(breakSuggested: true);
      _mascotRef.onLessonEvent(LessonEvent.fatigueDetected);
    }
  }

  /// Graceful session end.
  void endSession() {
    _mascotRef.onLessonEvent(LessonEvent.sessionEnd);
    state = state.copyWith(phase: LessonPhase.summary);
  }

  // ── Internal transitions ──────────────────────────────────────────────────

  void _transitionToAwaitInput() {
    _itemShownMs = DateTime.now().millisecondsSinceEpoch;
    state = state.copyWith(
      phase: LessonPhase.awaitInput,
      typedSoFar: [],
      missCountCurrent: 0,
    );
  }

  void _handleCorrectKey(
    KeystrokeRecord record,
    String target,
    AdaptationProfile profile,
  ) {
    final newTyped = [...state.typedSoFar, record.actualKey];

    if (newTyped.length >= target.length) {
      // Word complete
      _completeCurrentItem(newTyped, assisted: false);
    } else {
      state = state.copyWith(
        phase: LessonPhase.evaluate,
        typedSoFar: newTyped,
      );
      _mascotRef.onLessonEvent(LessonEvent.itemCorrect);
      // Continue awaiting next character
      Future.microtask(() {
        if (mounted) state = state.copyWith(phase: LessonPhase.awaitInput);
      });
    }
  }

  void _handleWrongKey(KeystrokeRecord record, AdaptationProfile profile) {
    final newMiss = state.missCountCurrent + 1;

    if (newMiss >= _assistedThreshold) {
      // Record the final miss count before auto-filling remaining characters.
      state = state.copyWith(missCountCurrent: newMiss);
      final target = state.currentItem!.l10n.text;
      final remaining = _remainingChars(target, state.typedSoFar);
      final newTyped = [...state.typedSoFar, ...remaining];
      _completeCurrentItem(newTyped, assisted: true);
    } else {
      state = state.copyWith(
        phase: LessonPhase.feedback,
        missCountCurrent: newMiss,
      );
      _mascotRef.onLessonEvent(LessonEvent.itemStruggling);
      // Return to awaitInput after brief feedback
      Future.microtask(() {
        if (mounted) state = state.copyWith(phase: LessonPhase.awaitInput);
      });
    }
  }

  void _completeCurrentItem(List<String> typed, {required bool assisted}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final item = state.currentItem!;
    final attempt = ItemAttempt(
      itemId: item.id,
      skillKey: item.skillKey,
      missCount: state.missCountCurrent,
      assisted: assisted,
      coinsEarned: _coinsPerItem,
      durationMs: now - _itemShownMs,
    );

    final newAttempts = [...state.attempts, attempt];
    final newCoins = state.totalCoins + _coinsPerItem;
    final nextIndex = state.currentIndex + 1;

    state = state.copyWith(
      phase: LessonPhase.celebrate,
      typedSoFar: typed,
      attempts: newAttempts,
      totalCoins: newCoins,
    );

    onItemCompleted?.call(attempt);
    _mascotRef.onLessonEvent(LessonEvent.levelComplete);

    Future.microtask(() {
      if (!mounted) return;
      if (nextIndex >= state.items.length) {
        // All items done
        final stars = _computeStars(newAttempts);
        state = state.copyWith(
          phase: LessonPhase.summary,
          currentIndex: nextIndex,
          starsEarned: stars,
        );
        onLessonComplete?.call(state);
        _mascotRef.onLessonEvent(LessonEvent.sessionEnd);
      } else {
        state = state.copyWith(
          currentIndex: nextIndex,
          phase: LessonPhase.presentItem,
        );
        // Brief present pause then await input
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) _transitionToAwaitInput();
        });
      }
    });
  }

  /// Stars by personal improvement: no misses = 3, few = 2, assisted = 1.
  int _computeStars(List<ItemAttempt> attempts) {
    if (attempts.isEmpty) return 1;
    final assistedCount = attempts.where((a) => a.assisted).length;
    final avgMiss =
        attempts.map((a) => a.missCount).reduce((a, b) => a + b) / attempts.length;
    if (assistedCount == 0 && avgMiss < 0.5) return 3;
    if (assistedCount <= attempts.length ~/ 3 && avgMiss < 2) return 2;
    return 1;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String? _nextExpectedChar(String target, List<String> typed) {
    // Handle Uzbek multi-char units: check digraphs first
    final remaining = target.substring(_joinedLength(typed));
    if (remaining.isEmpty) return null;
    // Check for known Uzbek digraphs at the start of remaining
    for (final dg in const ["o'", "g'", "sh", "ch", "ng", "O'", "G'"]) {
      if (remaining.startsWith(dg)) return dg;
    }
    return remaining[0];
  }

  int _joinedLength(List<String> typed) {
    return typed.fold(0, (acc, c) => acc + c.length);
  }

  List<String> _remainingChars(String target, List<String> typed) {
    final remaining = <String>[];
    int pos = _joinedLength(typed);
    while (pos < target.length) {
      // Try digraphs
      bool matched = false;
      for (final dg in const ["o'", "g'", "sh", "ch", "ng", "O'", "G'"]) {
        if (target.substring(pos).startsWith(dg)) {
          remaining.add(dg);
          pos += dg.length;
          matched = true;
          break;
        }
      }
      if (!matched) {
        remaining.add(target[pos]);
        pos++;
      }
    }
    return remaining;
  }
}

/// Provider for the lesson controller.
/// [MascotController] is injected so the lesson can drive mascot expressions.
final lessonControllerProvider =
    StateNotifierProvider<LessonController, LessonState>(
  (ref) => LessonController(ref.read(mascotControllerProvider.notifier)),
);