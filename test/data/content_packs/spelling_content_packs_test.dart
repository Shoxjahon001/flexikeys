import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flexikeys/data/content_packs/content_pack.dart';
import 'package:flexikeys/data/content_packs/spelling_content_packs.dart';

/// Snapshot of every word/id/display/color from the pre-refactor
/// lib/data/level_configs.dart (LevelConfig/GameItem), typed out
/// independently of the migration itself — this is what proves the
/// migration didn't silently drop, reorder, or corrupt a single item, not
/// just that the new code "looks right" by inspection.
void main() {
  group('numbers pack (en) matches pre-refactor content exactly', () {
    late ContentPack pack;
    setUp(() => pack = SpellingContentPacks.resolve('numbers', 'en')!);

    test('config fields unchanged', () {
      expect(pack.categoryId, 'numbers');
      expect(pack.locale, 'en');
      expect(pack.title, 'Numbers');
      expect(pack.questionCount, 15);
      expect(pack.ordered, isTrue);
      expect(pack.nextLevelToUnlock, 'colors');
      expect(pack.alphabet, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ');
    });

    test('all 15 items unchanged, in order', () {
      const expected = [
        ('1', '1', 'ONE'),
        ('2', '2', 'TWO'),
        ('3', '3', 'THREE'),
        ('4', '4', 'FOUR'),
        ('5', '5', 'FIVE'),
        ('6', '6', 'SIX'),
        ('7', '7', 'SEVEN'),
        ('8', '8', 'EIGHT'),
        ('9', '9', 'NINE'),
        ('10', '10', 'TEN'),
        ('11', '11', 'ELEVEN'),
        ('12', '12', 'TWELVE'),
        ('13', '13', 'THIRTEEN'),
        ('15', '15', 'FIFTEEN'),
        ('20', '20', 'TWENTY'),
      ];
      expect(pack.items.length, expected.length);
      for (var i = 0; i < expected.length; i++) {
        final (id, display, word) = expected[i];
        expect(pack.items[i].id, 'en.numbers.$id', reason: 'index $i');
        expect(pack.items[i].display, display, reason: 'index $i');
        expect(pack.items[i].word, word, reason: 'index $i');
      }
    });
  });

  group('colors pack (en) matches pre-refactor content exactly', () {
    late ContentPack pack;
    setUp(() => pack = SpellingContentPacks.resolve('colors', 'en')!);

    test('config fields unchanged', () {
      expect(pack.categoryId, 'colors');
      expect(pack.questionCount, 10);
      expect(pack.ordered, isFalse);
      expect(pack.nextLevelToUnlock, 'fruits');
    });

    test('all 10 items unchanged, including tileColor', () {
      const expected = [
        ('red', 'Red', 'RED', Color(0xFFE53935)),
        ('blue', 'Blue', 'BLUE', Color(0xFF1E88E5)),
        ('green', 'Green', 'GREEN', Color(0xFF43A047)),
        ('yellow', 'Yellow', 'YELLOW', Color(0xFFFDD835)),
        ('orange', 'Orange', 'ORANGE', Color(0xFFFF7043)),
        ('purple', 'Purple', 'PURPLE', Color(0xFF7B1FA2)),
        ('pink', 'Pink', 'PINK', Color(0xFFEC407A)),
        ('brown', 'Brown', 'BROWN', Color(0xFF795548)),
        ('black', 'Black', 'BLACK', Color(0xFF424242)),
        ('white', 'White', 'WHITE', Color(0xFFE0E0E0)),
      ];
      expect(pack.items.length, expected.length);
      for (var i = 0; i < expected.length; i++) {
        final (id, display, word, color) = expected[i];
        expect(pack.items[i].id, 'en.colors.$id', reason: 'index $i');
        expect(pack.items[i].display, display, reason: 'index $i');
        expect(pack.items[i].word, word, reason: 'index $i');
        expect(pack.items[i].tileColor, color, reason: 'index $i');
      }
    });
  });

  group('fruits pack (en) matches pre-refactor content exactly', () {
    late ContentPack pack;
    setUp(() => pack = SpellingContentPacks.resolve('fruits', 'en')!);

    test('config fields unchanged', () {
      expect(pack.categoryId, 'fruits');
      expect(pack.questionCount, 12);
      expect(pack.ordered, isFalse);
      expect(pack.nextLevelToUnlock, 'animals');
    });

    test('all 12 items unchanged', () {
      const expected = [
        ('apple', '🍎', 'APPLE'),
        ('banana', '🍌', 'BANANA'),
        ('grape', '🍇', 'GRAPE'),
        ('orange', '🍊', 'ORANGE'),
        ('melon', '🍈', 'MELON'),
        ('mango', '🥭', 'MANGO'),
        ('lemon', '🍋', 'LEMON'),
        ('pear', '🍐', 'PEAR'),
        ('peach', '🍑', 'PEACH'),
        ('cherry', '🍒', 'CHERRY'),
        ('kiwi', '🥝', 'KIWI'),
        ('pineapple', '🍍', 'PINEAPPLE'),
      ];
      expect(pack.items.length, expected.length);
      for (var i = 0; i < expected.length; i++) {
        final (id, display, word) = expected[i];
        expect(pack.items[i].id, 'en.fruits.$id', reason: 'index $i');
        expect(pack.items[i].display, display, reason: 'index $i');
        expect(pack.items[i].word, word, reason: 'index $i');
      }
    });
  });

  group('animals pack (en) matches pre-refactor content exactly', () {
    late ContentPack pack;
    setUp(() => pack = SpellingContentPacks.resolve('animals', 'en')!);

    test('config fields unchanged', () {
      expect(pack.categoryId, 'animals');
      expect(pack.questionCount, 12);
      expect(pack.ordered, isFalse);
      expect(pack.nextLevelToUnlock, 'food');
    });

    test('all 12 items unchanged', () {
      const expected = [
        ('cat', '🐱', 'CAT'),
        ('dog', '🐶', 'DOG'),
        ('lion', '🦁', 'LION'),
        ('hippo', '🦛', 'HIPPO'),
        ('monkey', '🐒', 'MONKEY'),
        ('zebra', '🦓', 'ZEBRA'),
        ('rabbit', '🐰', 'RABBIT'),
        ('bear', '🐻', 'BEAR'),
        ('fox', '🦊', 'FOX'),
        ('tiger', '🐯', 'TIGER'),
        ('cow', '🐮', 'COW'),
        ('wolf', '🐺', 'WOLF'),
      ];
      expect(pack.items.length, expected.length);
      for (var i = 0; i < expected.length; i++) {
        final (id, display, word) = expected[i];
        expect(pack.items[i].id, 'en.animals.$id', reason: 'index $i');
        expect(pack.items[i].display, display, reason: 'index $i');
        expect(pack.items[i].word, word, reason: 'index $i');
      }
    });
  });

  group('food pack (en) matches pre-refactor content exactly', () {
    late ContentPack pack;
    setUp(() => pack = SpellingContentPacks.resolve('food', 'en')!);

    test('config fields unchanged', () {
      expect(pack.categoryId, 'food');
      expect(pack.questionCount, 10);
      expect(pack.ordered, isFalse);
      expect(pack.nextLevelToUnlock, isNull);
    });

    test('all 10 items unchanged', () {
      const expected = [
        ('pizza', '🍕', 'PIZZA'),
        ('burger', '🍔', 'BURGER'),
        ('cake', '🎂', 'CAKE'),
        ('juice', '🧃', 'JUICE'),
        ('taco', '🌮', 'TACO'),
        ('donut', '🍩', 'DONUT'),
        ('cookie', '🍪', 'COOKIE'),
        ('soup', '🍜', 'SOUP'),
        ('meat', '🥩', 'MEAT'),
        ('sushi', '🍣', 'SUSHI'),
      ];
      expect(pack.items.length, expected.length);
      for (var i = 0; i < expected.length; i++) {
        final (id, display, word) = expected[i];
        expect(pack.items[i].id, 'en.food.$id', reason: 'index $i');
        expect(pack.items[i].display, display, reason: 'index $i');
        expect(pack.items[i].word, word, reason: 'index $i');
      }
    });
  });

  group('locale fallback (uz/ru have no packs yet)', () {
    for (final categoryId in ['numbers', 'colors', 'fruits', 'animals', 'food']) {
      test('$categoryId: uz and ru both resolve to the exact en pack', () {
        final en = SpellingContentPacks.resolve(categoryId, 'en');
        final uz = SpellingContentPacks.resolve(categoryId, 'uz');
        final ru = SpellingContentPacks.resolve(categoryId, 'ru');
        expect(identical(uz, en), isTrue,
            reason: 'uz must be byte-identical to en until a uz pack exists');
        expect(identical(ru, en), isTrue,
            reason: 'ru must fall back to en until a ru pack is added');
      });
    }

    test('unknown category id resolves to null', () {
      expect(SpellingContentPacks.resolve('not_a_category', 'en'), isNull);
    });
  });

  test('every word across every en spelling pack is uppercase Latin only '
      '(sanity check the migration did not alter casing)', () {
    for (final categoryId in ['numbers', 'colors', 'fruits', 'animals', 'food']) {
      final pack = SpellingContentPacks.resolve(categoryId, 'en')!;
      for (final item in pack.items) {
        expect(item.word, item.word.toUpperCase(), reason: item.id);
        expect(RegExp(r'^[A-Z]+$').hasMatch(item.word), isTrue,
            reason: '${item.id}: "${item.word}"');
      }
    }
  });
}
