import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:flexikeys/data/content_packs/content_pack.dart';
import 'package:flexikeys/data/content_packs/spelling_content_packs.dart';

void main() {
  group('lengthSort flag', () {
    test('is true for every ru word category except numbers', () {
      for (final categoryId in ['colors', 'fruits', 'animals', 'food']) {
        final pack = SpellingContentPacks.resolve(categoryId, 'ru')!;
        expect(pack.lengthSort, isTrue, reason: categoryId);
      }
    });

    test('numbers is exempt — stays numeric via ordered:true, not '
        'lengthSort (ЧЕТЫРЕ/4 must never come before ОДИН/1)', () {
      final pack = SpellingContentPacks.resolve('numbers', 'ru')!;
      expect(pack.lengthSort, isFalse);
      expect(pack.ordered, isTrue);
    });

    test('every en/uz pack is unaffected (lengthSort false, same as '
        'before this field existed)', () {
      for (final categoryId in [
        'numbers', 'colors', 'fruits', 'animals', 'food'
      ]) {
        for (final locale in ['en', 'uz']) {
          final pack = SpellingContentPacks.resolve(categoryId, locale)!;
          expect(pack.lengthSort, isFalse, reason: '$locale/$categoryId');
        }
      }
    });
  });

  group('orderItemsForSession — this is the real function '
      'GenericGameScreen calls, not a re-implementation', () {
    List<String> wordsFor(String categoryId) {
      final pack = SpellingContentPacks.resolve(categoryId, 'ru')!;
      return orderItemsForSession(pack, Random())
          .map((i) => i.word)
          .toList();
    }

    test('colors ramps from shortest to longest, ties keep original order',
        () {
      expect(wordsFor('colors'), [
        'СИНИЙ', // 5
        'БЕЛЫЙ', // 5
        'ЖЁЛТЫЙ', // 6
        'ЧЁРНЫЙ', // 6
        'КРАСНЫЙ', // 7
        'ЗЕЛЁНЫЙ', // 7
        'РОЗОВЫЙ', // 7
        'ОРАНЖЕВЫЙ', // 9
        'ФИОЛЕТОВЫЙ', // 10
        'КОРИЧНЕВЫЙ', // 10
      ]);
    });

    test('is monotonically non-decreasing in length for every lengthSort '
        'category', () {
      for (final categoryId in ['colors', 'fruits', 'animals', 'food']) {
        final words = wordsFor(categoryId);
        for (var i = 1; i < words.length; i++) {
          expect(words[i].length, greaterThanOrEqualTo(words[i - 1].length),
              reason: '$categoryId: "${words[i - 1]}" -> "${words[i]}"');
        }
      }
    });

    test('is deterministic regardless of Random seed — sorting twice with '
        'different Random instances gives the identical sequence', () {
      for (final categoryId in ['colors', 'fruits', 'animals', 'food']) {
        final pack = SpellingContentPacks.resolve(categoryId, 'ru')!;
        final a = orderItemsForSession(pack, Random(1)).map((i) => i.word);
        final b = orderItemsForSession(pack, Random(999)).map((i) => i.word);
        expect(a, b, reason: categoryId);
      }
    });

    test('numbers pack stays in numeric order (ordered:true, lengthSort '
        'false) — never touched by the length sort', () {
      const expectedOrder = [
        'ОДИН', 'ДВА', 'ТРИ', 'ЧЕТЫРЕ', 'ПЯТЬ', 'ШЕСТЬ', 'СЕМЬ', 'ВОСЕМЬ',
        'ДЕВЯТЬ', 'ДЕСЯТЬ', 'ОДИННАДЦАТЬ', 'ДВЕНАДЦАТЬ', 'ТРИНАДЦАТЬ',
        'ПЯТНАДЦАТЬ', 'ДВАДЦАТЬ',
      ];
      expect(wordsFor('numbers'), expectedOrder);
    });
  });

  group('orderItemsForSession — unseeded/shuffled categories unaffected',
      () {
    test('en colors (ordered:false, lengthSort:false) still shuffles — '
        'not suddenly sorted by length', () {
      final pack = SpellingContentPacks.resolve('colors', 'en')!;
      // Run several shuffles; at least one must differ from the original
      // list order, proving orderItemsForSession still shuffles rather
      // than silently switching to a fixed/sorted order for en.
      final original = pack.items.map((i) => i.word).toList();
      var sawDifferentOrder = false;
      for (var seed = 0; seed < 20; seed++) {
        final shuffled = orderItemsForSession(pack, Random(seed))
            .map((i) => i.word)
            .toList();
        if (shuffled.toString() != original.toString()) {
          sawDifferentOrder = true;
          break;
        }
      }
      expect(sawDifferentOrder, isTrue);
    });
  });
}
