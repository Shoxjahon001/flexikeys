import 'package:flutter_test/flutter_test.dart';

import 'package:flexikeys/data/content_packs/letters_content_packs.dart';

/// Snapshot of the pre-refactor lib/screens/game/letters_stage1_screen.dart
/// hardcoded `_letters` list (A-O, 15 letters) — proves the migration into
/// LettersContentPacks didn't drop, reorder, or add a letter.
void main() {
  test('en pack is exactly A-O, in order, unchanged', () {
    final pack = LettersContentPacks.resolve('en');
    expect(pack.categoryId, 'letters');
    expect(pack.locale, 'en');
    expect(pack.ordered, isTrue);
    expect(pack.questionCount, 15);

    const expectedLetters = [
      'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O'
    ];
    expect(pack.items.length, expectedLetters.length);
    for (var i = 0; i < expectedLetters.length; i++) {
      final letter = expectedLetters[i];
      expect(pack.items[i].word, letter, reason: 'index $i');
      expect(pack.items[i].display, letter, reason: 'index $i');
      expect(pack.items[i].id, 'en.letters.${letter.toLowerCase()}',
          reason: 'index $i');
    }
  });

  test('uz and ru both fall back to the exact en pack today', () {
    final en = LettersContentPacks.resolve('en');
    final uz = LettersContentPacks.resolve('uz');
    final ru = LettersContentPacks.resolve('ru');
    expect(identical(uz, en), isTrue);
    expect(identical(ru, en), isTrue);
  });
}
