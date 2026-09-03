import 'dart:math';

/// Board sizes the spelling-task keyboard supports, smallest first. Kept
/// as one ordered list so [keyCountFor] and the widget layer agree on
/// exactly which sizes exist without repeating the literals.
const List<int> kKeyboardBoardSizes = [6, 8, 10];

/// How many distractor (non-answer) keys a board should carry, before
/// [keyCountFor] clamps to the smallest board size that fits everything —
/// see [keyCountFor]'s doc for how this interacts with the fixed 6/8/10
/// board-size ceiling.
const int kTargetDistractorCount = 3;

/// The single, documented mapping from "how many unique letters does this
/// answer need" to "how many keys should the board show" — the only place
/// this decision is made; callers never invent their own thresholds.
///
/// Steps through the fixed board sizes in [kKeyboardBoardSizes] (6 → 8 →
/// 10), picking the smallest one that can hold every unique letter of the
/// answer *plus* [kTargetDistractorCount] distractors. If even the largest
/// board (10) can't fit that many distractors — true today only for
/// Russian's two 10-unique-letter color words, ФИОЛЕТОВЫЙ and
/// КОРИЧНЕВЫЙ — the board is simply every answer letter with zero
/// distractors (still correct and playable, just harder; there is no
/// larger board size to fall back to without redesigning the grid layout,
/// which is out of scope here). [uniqueLetterCount] must never exceed the
/// largest board size — [generic_game_screen.dart]'s own content-pack
/// tests already assert every real word stays at or under that ceiling.
int keyCountFor(int uniqueLetterCount) {
  for (final boardSize in kKeyboardBoardSizes) {
    if (boardSize >= uniqueLetterCount + kTargetDistractorCount) {
      return boardSize;
    }
  }
  return max(uniqueLetterCount, kKeyboardBoardSizes.last);
}

/// A stable, deterministic hash of [text] — the DJB2 variant already used
/// by `TtsService._key` in this codebase, reused here rather than
/// `Object.hashCode` (whose exact algorithm for `String` is an
/// implementation detail, not a public stability contract). Used to seed
/// a per-item [Random] so a spelling task's keyboard shuffles the same way
/// every time that exact item is shown — a retry or relaunch must not
/// reshuffle it differently.
int stableHash(String text) {
  int h = 5381;
  for (final c in text.codeUnits) {
    h = ((h << 5) + h + c) & 0x7FFFFFFF;
  }
  return h;
}
