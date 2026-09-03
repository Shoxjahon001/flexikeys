import 'package:flutter_test/flutter_test.dart';

import 'package:flexikeys/data/content_packs/keyboard_key_count.dart';
import 'package:flexikeys/data/content_packs/spelling_content_packs.dart';

void main() {
  group('keyCountFor', () {
    test('steps through 6 -> 8 -> 10 as unique letters grow', () {
      expect(keyCountFor(1), 6);
      expect(keyCountFor(3), 6); // 6 >= 3+3
      expect(keyCountFor(4), 8); // 6 >= 4+3 fails, 8 >= 4+3 holds
      expect(keyCountFor(5), 8);
      expect(keyCountFor(6), 10); // 8 >= 6+3 fails, 10 >= 6+3 holds
      expect(keyCountFor(7), 10);
    });

    test('degrades distractor count gracefully once even 10 keys cannot '
        'fit the target — never throws, never exceeds the 10-key ceiling',
        () {
      expect(keyCountFor(8), 10); // 2 distractors instead of 3
      expect(keyCountFor(9), 10); // 1 distractor
      expect(keyCountFor(10), 10); // 0 distractors — the КОРИЧНЕВЫЙ case
    });

    test('never returns a board smaller than the unique-letter count '
        '(the answer must always fully fit)', () {
      for (var unique = 1; unique <= 10; unique++) {
        expect(keyCountFor(unique), greaterThanOrEqualTo(unique),
            reason: 'unique=$unique');
      }
    });

    test('is monotonically non-decreasing', () {
      for (var unique = 1; unique < 10; unique++) {
        expect(keyCountFor(unique + 1), greaterThanOrEqualTo(keyCountFor(unique)),
            reason: 'unique=$unique -> ${unique + 1}');
      }
    });
  });

  group('stableHash', () {
    test('is deterministic — same input, same output, every call', () {
      final a = stableHash('ru.animals.zebra');
      final b = stableHash('ru.animals.zebra');
      expect(a, b);
    });

    test('different ids produce different hashes (no obvious collisions '
        'among real content ids)', () {
      final ids = [
        for (final categoryId in ['numbers', 'colors', 'fruits', 'animals', 'food'])
          ...SpellingContentPacks.resolve(categoryId, 'ru')!.items.map((i) => i.id),
      ];
      final hashes = ids.map(stableHash).toSet();
      expect(hashes.length, ids.length, reason: 'no hash collisions among real ids');
    });

    test('is non-negative (used directly as a Random seed)', () {
      for (final text in ['a', 'ru.colors.krasny', '', 'КОРИЧНЕВЫЙ']) {
        expect(stableHash(text), greaterThanOrEqualTo(0), reason: text);
      }
    });
  });

  test('the real key-count for every ru word stays within [unique, 10] — '
      'the reviewed table never asks for a board it cannot have', () {
    for (final categoryId in ['numbers', 'colors', 'fruits', 'animals', 'food']) {
      final pack = SpellingContentPacks.resolve(categoryId, 'ru')!;
      for (final item in pack.items) {
        final unique = item.word.split('').toSet().length;
        final board = keyCountFor(unique);
        expect(unique, lessThanOrEqualTo(10), reason: item.id);
        expect(board, greaterThanOrEqualTo(unique), reason: item.id);
        expect(board, lessThanOrEqualTo(10), reason: item.id);
        expect(kKeyboardBoardSizes, contains(board), reason: item.id);
      }
    }
  });
}
