import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flexikeys/data/content_packs/content_pack.dart';

const _enPack = ContentPack(
  categoryId: 'widgets',
  locale: 'en',
  title: 'Widgets',
  questionCount: 1,
  items: [ContentItem(id: 'en.widgets.a', display: 'A', word: 'A')],
);

void main() {
  group('ContentPackResolver', () {
    test('returns the exact pack for a locale that has one', () {
      final resolved =
          ContentPackResolver.resolve({'en': _enPack}, 'en');
      expect(identical(resolved, _enPack), isTrue);
    });

    test('falls back to en when the requested locale has no pack', () {
      final resolved =
          ContentPackResolver.resolve({'en': _enPack}, 'ru');
      expect(identical(resolved, _enPack), isTrue);
    });

    test('uz and ru resolve to the byte-identical en pack when neither '
        'has a pack of its own (today\'s actual state for every category)',
        () {
      final packs = {'en': _enPack};
      final uzResolved = ContentPackResolver.resolve(packs, 'uz');
      final ruResolved = ContentPackResolver.resolve(packs, 'ru');
      expect(identical(uzResolved, _enPack), isTrue);
      expect(identical(ruResolved, _enPack), isTrue);
      expect(identical(uzResolved, ruResolved), isTrue);
    });

    test('an existing non-en pack is preferred over the en fallback', () {
      const ruPack = ContentPack(
        categoryId: 'widgets',
        locale: 'ru',
        title: 'Виджеты',
        questionCount: 1,
        items: [ContentItem(id: 'ru.widgets.a', display: 'А', word: 'А')],
      );
      final resolved = ContentPackResolver.resolve(
        {'en': _enPack, 'ru': ruPack},
        'ru',
      );
      expect(identical(resolved, ruPack), isTrue);
    });
  });

  test('ContentItem carries a stable locale-scoped id, not a position', () {
    const item = ContentItem(id: 'ru.animals.zebra', display: '🦓', word: 'ЗЕБРА');
    expect(item.id, 'ru.animals.zebra');
    expect(item.display, '🦓');
    expect(item.word, 'ЗЕБРА');
  });

  test('ContentPack default fields preserve pre-refactor LevelConfig '
      'defaults (ordered: false, starsReward: 10)', () {
    const pack = ContentPack(
      categoryId: 'x',
      locale: 'en',
      title: 'X',
      questionCount: 1,
      items: [ContentItem(id: 'en.x.a', display: 'a', word: 'A')],
    );
    expect(pack.ordered, isFalse);
    expect(pack.starsReward, 10);
    expect(pack.alphabet, '');
    expect(pack.nextLevelToUnlock, isNull);
  });

  test('tileColor survives unchanged for color-swatch items', () {
    const item = ContentItem(
      id: 'en.colors.red',
      display: 'Red',
      word: 'RED',
      tileColor: Color(0xFFE53935),
    );
    expect(item.tileColor, const Color(0xFFE53935));
  });
}
