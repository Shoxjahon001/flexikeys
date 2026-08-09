import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flexikeys/design_system/aac/aac_theme.dart';
import 'package:flexikeys/features/aac/data/aac_card_repository.dart';
import 'package:flexikeys/features/aac/domain/aac_card_def.dart';

void main() {
  // Loads the real bundled shared/aac/*.json files — this is as much a
  // content-authoring correctness check (37 hand-written cards across 6
  // JSON files) as it is a repository test.
  //
  // Plain test() + a one-time binding init, not testWidgets(): this is pure
  // async asset I/O with no widget tree involved, and testWidgets() (which
  // expects each test to pump/settle a widget tree) deadlocked across
  // multiple test bodies in this file when nothing was ever pumped.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AacCardRepository — real bundled vocabulary', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('loads all 37 starter cards across 6 categories', () async {
      final cards = await AacCardRepository.instance.loadStarterVocabulary();
      expect(cards, hasLength(37));
      expect(cards.every((c) => !c.isCustom), isTrue);
    });

    test('every category has at least one card', () async {
      final cards = await AacCardRepository.instance.loadStarterVocabulary();
      for (final category in AacCategory.values) {
        expect(
          cards.where((c) => c.category == category),
          isNotEmpty,
          reason: '$category should have at least one starter card',
        );
      }
    });

    test('difficulty tiers accumulate to 6 / 12 / 24 / 37', () async {
      final cards = await AacCardRepository.instance.loadStarterVocabulary();
      int upTo(int tier) => cards.where((c) => c.difficultyTier <= tier).length;
      expect(upTo(1), 6);
      expect(upTo(2), 12);
      expect(upTo(3), 24);
      expect(upTo(4), 37);
    });

    test('every card has a non-empty en/uz/ru label and sentence template', () async {
      final cards = await AacCardRepository.instance.loadStarterVocabulary();
      for (final c in cards) {
        for (final lang in AacLanguage.values) {
          expect(c.label[lang], isNotNull, reason: '${c.id} missing $lang label');
          expect(c.label[lang], isNotEmpty, reason: '${c.id} has empty $lang label');
          expect(c.sentenceTemplate[lang], isNotNull,
              reason: '${c.id} missing $lang sentence template');
        }
      }
    });

    test('branch cards (food, pain) have fringe options with matching languages', () async {
      final cards = await AacCardRepository.instance.loadStarterVocabulary();
      final branchCards = cards.where((c) => c.kind == AacCardKind.branch).toList();
      expect(branchCards.map((c) => c.id), containsAll(['ne_food', 'fe_pain']));
      for (final c in branchCards) {
        expect(c.fringeOptions, isNotEmpty);
        for (final option in c.fringeOptions) {
          for (final lang in AacLanguage.values) {
            expect(option.fillValue[lang], isNotNull,
                reason: '${c.id}/${option.id} missing $lang fill value');
          }
        }
      }
    });

    test('direct (non-branch) cards define no fringe options', () async {
      final cards = await AacCardRepository.instance.loadStarterVocabulary();
      for (final c in cards.where((c) => c.kind == AacCardKind.direct)) {
        expect(c.fringeOptions, isEmpty, reason: '${c.id} is direct but has fringe options');
      }
    });

    test('all 37 card ids are unique', () async {
      final cards = await AacCardRepository.instance.loadStarterVocabulary();
      final ids = cards.map((c) => c.id).toSet();
      expect(ids, hasLength(37));
    });

    test('loadUnlocked(maxTier: 1) returns exactly the 6 tier-1 cards', () async {
      final unlocked = await AacCardRepository.instance.loadUnlocked(maxTier: 1);
      expect(unlocked, hasLength(6));
      expect(unlocked.every((c) => c.difficultyTier <= 1), isTrue);
    });

    test('loadCategory returns only cards in that category', () async {
      final needs = await AacCardRepository.instance.loadCategory(AacCategory.needs);
      expect(needs, isNotEmpty);
      expect(needs.every((c) => c.category == AacCategory.needs), isTrue);
    });
  });
}
