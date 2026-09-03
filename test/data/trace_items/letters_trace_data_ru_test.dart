import 'package:flutter_test/flutter_test.dart';

import 'package:flexikeys/data/trace_items/letters_trace_data.dart';
import 'package:flexikeys/data/trace_items/letters_trace_data_ru.dart';
import 'package:flexikeys/data/trace_items/trace_item_def.dart';

const _expectedLetters = [
  'А', 'Б', 'В', 'Г', 'Д', 'Е', 'Ё', 'Ж', 'З', 'И', 'Й', 'К', 'Л', 'М', 'Н',
  'О', 'П', 'Р', 'С', 'Т', 'У', 'Ф', 'Х', 'Ц', 'Ч', 'Ш', 'Щ', 'Ъ', 'Ы', 'Ь',
  'Э', 'Ю', 'Я',
];

void main() {
  test('all 33 letters present, in alphabetical order, no dupes', () {
    expect(kLetterTraceItemsRu.length, 33);
    expect(kLetterTraceItemsRu.map((i) => i.label).toList(), _expectedLetters);
    expect(kLetterTraceItemsRu.map((i) => i.label).toSet().length, 33);
  });

  group('requirement 1: no aliasing with the Latin (en) letters', () {
    test('no ru label collides with an en label', () {
      final enLabels = kLetterTraceItems.map((i) => i.label).toSet();
      final ruLabels = kLetterTraceItemsRu.map((i) => i.label).toSet();
      expect(enLabels.intersection(ruLabels), isEmpty,
          reason: 'Cyrillic А/В/Е/К/М/Н/О/Р/С/Т/Х look identical to their '
              'Latin twins but must never be treated as the same item');
    });

    test('every ru label is outside the Latin A-Z range (genuinely '
        'Cyrillic code points, not visual lookalikes stored as Latin)', () {
      final latinAZ = RegExp(r'^[A-Z]$');
      for (final item in kLetterTraceItemsRu) {
        expect(latinAZ.hasMatch(item.label), isFalse, reason: item.label);
      }
    });
  });

  group('requirement 2: descenders (Д, У, Ц, Щ) fit the 0-1 canvas, no clip',
      () {
    test('every coordinate stays within [0,1] on both axes', () {
      for (final item in kLetterTraceItemsRu) {
        for (final d in item.dots) {
          expect(d.dx, inInclusiveRange(0.0, 1.0), reason: '${item.label} dot x');
          expect(d.dy, inInclusiveRange(0.0, 1.0), reason: '${item.label} dot y');
        }
        for (final path in item.ghost) {
          for (final p in path) {
            expect(p.dx, inInclusiveRange(0.0, 1.0), reason: '${item.label} ghost x');
            expect(p.dy, inInclusiveRange(0.0, 1.0), reason: '${item.label} ghost y');
          }
        }
      }
    });

    test('Д/У/Ц/Щ actually descend below the 0.87 baseline (proves the '
        'transform preserved the descender, not silently clamped it)', () {
      for (final label in ['Д', 'У', 'Ц', 'Щ']) {
        final item = kLetterTraceItemsRu.firstWhere((i) => i.label == label);
        final maxY = [
          ...item.dots.map((d) => d.dy),
          ...item.ghost.expand((p) => p).map((d) => d.dy),
        ].reduce((a, b) => a > b ? a : b);
        expect(maxY, greaterThan(0.87), reason: label);
      }
    });
  });

  group('requirement 3: Ё/Й shifted bodies + dot handling', () {
    test('Ё and Й bodies start below y=0.15 to leave room for the dots/breve',
        () {
      for (final label in ['Ё', 'Й']) {
        final item = kLetterTraceItemsRu.firstWhere((i) => i.label == label);
        final minBodyY = item.ghost
            .where((p) => p.length > 1) // exclude Ё's lone-point dot strokes
            .expand((p) => p)
            .map((d) => d.dy)
            .reduce((a, b) => a < b ? a : b);
        expect(minBodyY, greaterThan(0.15), reason: label);
      }
    });

    test('Ё has exactly 2 single-point ghost strokes (the diaeresis dots), '
        'both above the body', () {
      final yo = kLetterTraceItemsRu.firstWhere((i) => i.label == 'Ё');
      final dotStrokes = yo.ghost.where((p) => p.length == 1).toList();
      expect(dotStrokes.length, 2);
      final bodyTop = yo.ghost
          .where((p) => p.length > 1)
          .expand((p) => p)
          .map((d) => d.dy)
          .reduce((a, b) => a < b ? a : b);
      for (final dot in dotStrokes) {
        expect(dot.single.dy, lessThan(bodyTop));
      }
    });
  });

  group('requirement 5: stroke counts beyond the Latin max (4) are present '
      'and handled generically', () {
    test('Д has 5 strokes, Ё has 6 — more than any Latin letter', () {
      final maxLatinStrokes =
          kLetterTraceItems.map((i) => i.ghost.length).reduce((a, b) => a > b ? a : b);
      expect(maxLatinStrokes, lessThanOrEqualTo(4));

      final d = kLetterTraceItemsRu.firstWhere((i) => i.label == 'Д');
      final yo = kLetterTraceItemsRu.firstWhere((i) => i.label == 'Ё');
      expect(d.ghost.length, 5);
      expect(yo.ghost.length, 6);
    });
  });

  group('requirement 6: grouping is data-driven, never hardcoded', () {
    test('33 letters split into 9 groups of 3-4, covering the alphabet in '
        'order with no gaps or duplicates', () {
      expect(kLetterGroupsRu.length, 9);
      expect(kLetterGroupsRu.map((g) => g.items.length).toList(),
          [4, 4, 4, 4, 4, 4, 3, 3, 3]);
      final allLabels =
          kLetterGroupsRu.expand((g) => g.items.map((i) => i.label)).toList();
      expect(allLabels, _expectedLetters);
    });

    test('en groups are unaffected — still exactly 7, [4,4,4,4,4,3,3]', () {
      expect(kLetterGroups.length, 7);
      expect(kLetterGroups.map((g) => g.items.length).toList(),
          [4, 4, 4, 4, 4, 3, 3]);
    });

    test('computeGroupSizes has no hardcoded 26/33 special case — it '
        'generalizes to other counts too', () {
      expect(computeGroupSizes(12), [4, 4, 4]);
      expect(computeGroupSizes(9), [3, 3, 3]);
      expect(computeGroupSizes(15), [4, 4, 4, 3]);
    });

    test('ru group ids are namespaced separately from the Drawing module\'s '
        'own English group ids and each other', () {
      final ids = kLetterGroupsRu.map((g) => g.id).toSet();
      expect(ids.length, 9);
      for (final id in ids) {
        expect(id, startsWith('letters_group_ru_'));
      }
      expect(ids.intersection(kLetterGroups.map((g) => g.id).toSet()), isEmpty);
    });
  });
}
