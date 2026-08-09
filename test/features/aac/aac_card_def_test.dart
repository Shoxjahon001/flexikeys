import 'package:flutter_test/flutter_test.dart';
import 'package:flexikeys/features/aac/domain/aac_card_def.dart';
import 'package:flexikeys/design_system/aac/aac_theme.dart';

AacCardDef _direct({String id = 'da_eat'}) => AacCardDef(
      id: id,
      category: AacCategory.dailyActivities,
      kind: AacCardKind.direct,
      label: const {AacLanguage.en: 'Eat', AacLanguage.uz: 'Ovqatlanish'},
      sentenceTemplate: const {
        AacLanguage.en: 'I want to eat.',
        AacLanguage.uz: 'Men ovqatlanmoqchiman.',
      },
      animationAsset: 'assets/aac/animations/da_eat.json',
      audioAsset: const {AacLanguage.en: 'assets/aac/audio/en/da_eat.mp3'},
      difficultyTier: 1,
    );

AacCardDef _branch() => AacCardDef(
      id: 'ne_food',
      category: AacCategory.needs,
      kind: AacCardKind.branch,
      label: const {AacLanguage.en: 'Food'},
      sentenceTemplate: const {AacLanguage.en: 'I want {noun}.'},
      animationAsset: 'assets/aac/animations/ne_food.json',
      audioAsset: const {AacLanguage.en: 'assets/aac/audio/en/ne_food.mp3'},
      difficultyTier: 2,
      fringeOptions: [
        const AacFringeOption(
          id: 'ne_food_banana',
          label: {AacLanguage.en: 'Banana'},
          fillValue: {AacLanguage.en: 'banana'},
          animationAsset: 'assets/aac/animations/ne_food_banana.json',
          audioAsset: {AacLanguage.en: 'assets/aac/audio/en/ne_food_banana.mp3'},
        ),
      ],
    );

void main() {
  group('AacCardDef', () {
    test('branch card requires at least one fringe option', () {
      expect(
        () => AacCardDef(
          id: 'bad',
          category: AacCategory.needs,
          kind: AacCardKind.branch,
          label: const {},
          sentenceTemplate: const {},
          animationAsset: '',
          audioAsset: const {},
          difficultyTier: 1,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('direct card sentenceFor returns the template as-is', () {
      expect(_direct().sentenceFor(AacLanguage.en), 'I want to eat.');
    });

    test('direct card falls back to English when a translation is missing', () {
      expect(_direct().sentenceFor(AacLanguage.ru), 'I want to eat.');
    });

    test('branch card substitutes the chosen fringe fillValue', () {
      final food = _branch();
      final sentence = food.sentenceFor(AacLanguage.en, chosenFringe: food.fringeOptions.first);
      expect(sentence, 'I want banana.');
    });

    test('branch card without a chosen fringe returns the raw template', () {
      final food = _branch();
      expect(food.sentenceFor(AacLanguage.en), 'I want {noun}.');
    });

    test('toJson/fromJson round-trips a direct card', () {
      final original = _direct();
      final restored = AacCardDef.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.category, original.category);
      expect(restored.kind, AacCardKind.direct);
      expect(restored.label[AacLanguage.en], 'Eat');
      expect(restored.sentenceTemplate[AacLanguage.uz], 'Men ovqatlanmoqchiman.');
      expect(restored.difficultyTier, 1);
    });

    test('toJson/fromJson round-trips a branch card with fringe options', () {
      final original = _branch();
      final restored = AacCardDef.fromJson(original.toJson());
      expect(restored.kind, AacCardKind.branch);
      expect(restored.fringeOptions, hasLength(1));
      expect(restored.fringeOptions.first.fillValue[AacLanguage.en], 'banana');
      expect(
        restored.sentenceFor(AacLanguage.en, chosenFringe: restored.fringeOptions.first),
        'I want banana.',
      );
    });

    test('isCustom defaults to false', () {
      expect(_direct().isCustom, isFalse);
    });
  });

  group('AacFringeOption', () {
    test('toJson/fromJson round-trips', () {
      const option = AacFringeOption(
        id: 'x',
        label: {AacLanguage.en: 'Head'},
        fillValue: {AacLanguage.en: 'head'},
        animationAsset: 'a.json',
        audioAsset: {AacLanguage.en: 'a.mp3'},
      );
      final restored = AacFringeOption.fromJson(option.toJson());
      expect(restored.id, 'x');
      expect(restored.fillValue[AacLanguage.en], 'head');
    });
  });
}
