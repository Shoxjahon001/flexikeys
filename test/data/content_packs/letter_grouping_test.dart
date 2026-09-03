import 'package:flutter_test/flutter_test.dart';

import 'package:flexikeys/data/content_packs/content_pack.dart';
import 'package:flexikeys/data/content_packs/letters_content_packs.dart';

void main() {
  group('splitIntoGroups (ru letters)', () {
    late List<ContentPack> groups;
    setUp(() => groups = splitIntoGroups(LettersContentPacks.resolve('ru')));

    test('produces exactly 9 groups summing to all 33 letters, in order, '
        'no gaps, no duplicates', () {
      expect(groups.length, 9);
      final allWords = groups.expand((g) => g.items.map((i) => i.word));
      expect(allWords.toSet().length, 33, reason: 'no duplicates');
      final full = LettersContentPacks.resolve('ru');
      expect(allWords.toList(), full.items.map((i) => i.word).toList(),
          reason: 'groups must cover the alphabet in order with no gaps');
    });

    test('every group has 3 or 4 letters', () {
      for (final g in groups) {
        expect(g.items.length, anyOf(3, 4), reason: g.categoryId);
      }
    });

    test('group sizes are front-loaded 4s then 3s: 6 groups of 4, 3 of 3',
        () {
      expect(groups.map((g) => g.items.length).toList(),
          [4, 4, 4, 4, 4, 4, 3, 3, 3]);
    });

    test('each group has a unique, stable slug distinct from the parent '
        "pack's own categoryId and the unrelated Drawing-module "
        "letters_group_N slugs", () {
      final slugs = groups.map((g) => g.categoryId).toSet();
      expect(slugs.length, groups.length);
      for (var i = 0; i < groups.length; i++) {
        expect(groups[i].categoryId, 'letters_ru_group_${i + 1}');
      }
    });

    test('each group inherits the parent pack\'s locale, alphabet, and '
        'starsReward', () {
      final full = LettersContentPacks.resolve('ru');
      for (final g in groups) {
        expect(g.locale, 'ru');
        expect(g.alphabet, full.alphabet);
        expect(g.starsReward, full.starsReward);
        expect(g.starsReward, 5);
        expect(g.ordered, isTrue);
        expect(g.questionCount, g.items.length);
      }
    });

    test('group titles are the letter range, e.g. "А-Г"', () {
      expect(groups[0].title, 'А-Г');
      expect(groups.last.title, 'Э-Я');
    });

    test('group item ids are reused verbatim from the parent pack (no new '
        'ids minted)', () {
      final full = LettersContentPacks.resolve('ru');
      final allGroupIds = groups.expand((g) => g.items.map((i) => i.id));
      expect(allGroupIds.toList(), full.items.map((i) => i.id).toList());
    });
  });

  test('en letters pack has no groupSizes — stays a flat run', () {
    final en = LettersContentPacks.resolve('en');
    expect(en.groupSizes, isNull);
  });

  test('ru letters pack declares groupSizes summing to its item count', () {
    final ru = LettersContentPacks.resolve('ru');
    expect(ru.groupSizes, isNotNull);
    expect(ru.groupSizes!.fold<int>(0, (a, b) => a + b), ru.items.length);
  });
}
