import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flexikeys/design_system/aac/aac_theme.dart';
import 'package:flexikeys/features/aac/data/aac_custom_card_store.dart';
import 'package:flexikeys/features/aac/domain/aac_card_def.dart';

AacCardDef _custom(String id) => AacCardDef(
      id: id,
      category: AacCategory.people,
      kind: AacCardKind.direct,
      label: {AacLanguage.en: 'Family Dog'},
      sentenceTemplate: {AacLanguage.en: 'I want the dog.'},
      animationAsset: '',
      audioAsset: const {},
      customPhotoPath: '/tmp/dog.jpg',
      difficultyTier: 1,
      isCustom: true,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // AacCustomCardStore.instance is a singleton with an in-memory cache —
    // without this, a later test would silently see an earlier test's
    // cached list instead of the freshly-mocked (empty) SharedPreferences.
    AacCustomCardStore.instance.resetCacheForTesting();
  });

  group('AacCustomCardStore', () {
    test('getAll returns empty list when nothing stored', () async {
      final all = await AacCustomCardStore.instance.getAll();
      expect(all, isEmpty);
    });

    test('add persists a custom card', () async {
      await AacCustomCardStore.instance.add(_custom('custom_1'));
      final all = await AacCustomCardStore.instance.getAll();
      expect(all.map((c) => c.id), contains('custom_1'));
    });

    test('add asserts isCustom must be true', () async {
      final notCustom = _custom('x').toJson();
      notCustom['is_custom'] = false;
      expect(
        () => AacCustomCardStore.instance.add(AacCardDef.fromJson(notCustom)),
        throwsA(isA<AssertionError>()),
      );
    });

    test('update replaces the matching card in place', () async {
      await AacCustomCardStore.instance.add(_custom('custom_2'));
      final updated = _custom('custom_2').toJson();
      updated['label'] = {'en': 'Updated Label'};
      await AacCustomCardStore.instance.update(AacCardDef.fromJson(updated));

      final all = await AacCustomCardStore.instance.getAll();
      final found = all.firstWhere((c) => c.id == 'custom_2');
      expect(found.label[AacLanguage.en], 'Updated Label');
    });

    test('remove deletes the matching card', () async {
      await AacCustomCardStore.instance.add(_custom('custom_3'));
      await AacCustomCardStore.instance.remove('custom_3');
      final all = await AacCustomCardStore.instance.getAll();
      expect(all.map((c) => c.id), isNot(contains('custom_3')));
    });

    test('persisted cards survive a round-trip through SharedPreferences', () async {
      await AacCustomCardStore.instance.add(_custom('custom_4'));
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('aac_custom_cards_v1');
      expect(raw, isNotNull);
      expect(raw, contains('custom_4'));
    });

    test('backfills a single-language card to every language on load', () async {
      await AacCustomCardStore.instance.add(const AacCardDef(
        id: 'custom_5',
        category: AacCategory.people,
        kind: AacCardKind.direct,
        label: {AacLanguage.uz: 'Rex'},
        sentenceTemplate: {AacLanguage.uz: 'Rex'},
        animationAsset: '',
        audioAsset: {AacLanguage.uz: '/tmp/rex.m4a'},
        difficultyTier: 1,
        isCustom: true,
      ));
      // Forces a fresh getAll() read (and thus the backfill pass) instead
      // of returning the just-added in-memory object as-is.
      AacCustomCardStore.instance.resetCacheForTesting();

      final all = await AacCustomCardStore.instance.getAll();
      final found = all.firstWhere((c) => c.id == 'custom_5');
      for (final lang in AacLanguage.values) {
        expect(found.label[lang], 'Rex');
        expect(found.sentenceTemplate[lang], 'Rex');
        expect(found.audioAsset[lang], '/tmp/rex.m4a');
      }
    });

    test('does not fabricate audio for a card with no recording', () async {
      await AacCustomCardStore.instance.add(_custom('custom_6'));
      AacCustomCardStore.instance.resetCacheForTesting();

      final all = await AacCustomCardStore.instance.getAll();
      final found = all.firstWhere((c) => c.id == 'custom_6');
      expect(found.audioAsset, isEmpty);
    });
  });
}
