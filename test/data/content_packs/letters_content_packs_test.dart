import 'package:flutter_test/flutter_test.dart';

import 'package:flexikeys/data/content_packs/content_pack.dart';
import 'package:flexikeys/data/content_packs/letters_content_packs.dart';

const _cyrillicLetters = [
  'А', 'Б', 'В', 'Г', 'Д', 'Е', 'Ё', 'Ж', 'З', 'И', 'Й', 'К', 'Л', 'М', 'Н',
  'О', 'П', 'Р', 'С', 'Т', 'У', 'Ф', 'Х', 'Ц', 'Ч', 'Ш', 'Щ', 'Ъ', 'Ы', 'Ь',
  'Э', 'Ю', 'Я',
];

void main() {
  test('en pack is the full A-Z alphabet, in order, no pronunciation '
      'overrides', () {
    final pack = LettersContentPacks.resolve('en');
    expect(pack.categoryId, 'letters');
    expect(pack.locale, 'en');
    expect(pack.ordered, isTrue);
    expect(pack.items.length, 26);

    const expectedLetters = [
      'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
      'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    ];
    for (var i = 0; i < expectedLetters.length; i++) {
      final letter = expectedLetters[i];
      expect(pack.items[i].word, letter, reason: 'index $i');
      expect(pack.items[i].display, letter, reason: 'index $i');
      expect(pack.items[i].id, 'en.letters.${letter.toLowerCase()}',
          reason: 'index $i');
      expect(pack.items[i].pronunciation, isNull, reason: 'index $i');
      expect(pack.items[i].spokenText, letter, reason: 'index $i');
    }
  });

  group('ru pack', () {
    late ContentPack pack;
    setUp(() => pack = LettersContentPacks.resolve('ru'));

    test('is the complete 33-letter Russian alphabet, in order', () {
      expect(pack.categoryId, 'letters');
      expect(pack.locale, 'ru');
      expect(pack.ordered, isTrue);
      expect(pack.items.length, 33);
      for (var i = 0; i < _cyrillicLetters.length; i++) {
        expect(pack.items[i].word, _cyrillicLetters[i], reason: 'index $i');
        expect(pack.items[i].display, _cyrillicLetters[i],
            reason: 'index $i');
      }
    });

    test('every item has a unique, ascii, locale-scoped id', () {
      final ids = pack.items.map((i) => i.id).toSet();
      expect(ids.length, pack.items.length, reason: 'no duplicate ids');
      for (final item in pack.items) {
        expect(item.id, startsWith('ru.letters.'));
        expect(RegExp(r'^[a-z0-9_.]+$').hasMatch(item.id), isTrue,
            reason: '${item.id} must be ASCII (asset-filename constraint)');
      }
    });

    test('Ъ and Ь are spoken by letter name, not their (nonexistent) sound',
        () {
      final tvyordy = pack.items.firstWhere((i) => i.word == 'Ъ');
      final myagky = pack.items.firstWhere((i) => i.word == 'Ь');
      expect(tvyordy.pronunciation, 'твёрдый знак');
      expect(tvyordy.spokenText, 'твёрдый знак');
      expect(myagky.pronunciation, 'мягкий знак');
      expect(myagky.spokenText, 'мягкий знак');
    });

    test('Ё is present, distinct from Е, and has no pronunciation override '
        '(it has its own real sound)', () {
      final ye = pack.items.firstWhere((i) => i.word == 'Е');
      final yo = pack.items.firstWhere((i) => i.word == 'Ё');
      expect(ye.word, isNot(yo.word));
      expect(yo.pronunciation, isNull);
      expect(yo.spokenText, 'Ё');
    });

    test('every other letter has no pronunciation override', () {
      for (final item in pack.items) {
        if (item.word == 'Ъ' || item.word == 'Ь') continue;
        expect(item.pronunciation, isNull, reason: item.id);
        expect(item.spokenText, item.word, reason: item.id);
      }
    });
  });

  test('uz still falls back to the en pack (no uz pack exists yet)', () {
    final en = LettersContentPacks.resolve('en');
    final uz = LettersContentPacks.resolve('uz');
    expect(identical(uz, en), isTrue);
  });

  test('ru no longer falls back to en now that a ru pack exists', () {
    final en = LettersContentPacks.resolve('en');
    final ru = LettersContentPacks.resolve('ru');
    expect(identical(ru, en), isFalse);
    expect(ru.locale, 'ru');
  });
}
