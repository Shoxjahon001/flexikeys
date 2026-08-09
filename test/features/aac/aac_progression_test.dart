import 'package:flutter_test/flutter_test.dart';
import 'package:flexikeys/features/aac/domain/aac_progression.dart';

void main() {
  group('AacLevel', () {
    test('card ceilings match the spec (6 / 12 / 24 / uncapped)', () {
      expect(AacLevel.level1.cardCeiling, 6);
      expect(AacLevel.level2.cardCeiling, 12);
      expect(AacLevel.level3.cardCeiling, 24);
      expect(AacLevel.level4.cardCeiling, isNull);
    });

    test('only level4 unlocks sentence building', () {
      expect(AacLevel.level1.unlocksSentenceBuilding, isFalse);
      expect(AacLevel.level2.unlocksSentenceBuilding, isFalse);
      expect(AacLevel.level3.unlocksSentenceBuilding, isFalse);
      expect(AacLevel.level4.unlocksSentenceBuilding, isTrue);
    });
  });

  group('AacProgressionState', () {
    final now = DateTime(2026, 1, 1);

    test('defaults to level1, not manually set', () {
      final state = AacProgressionState(updatedAt: now);
      expect(state.level, AacLevel.level1);
      expect(state.manuallySet, isFalse);
    });

    test('copyWith overrides only given fields', () {
      final state = AacProgressionState(updatedAt: now);
      final next = state.copyWith(level: AacLevel.level2, manuallySet: true);
      expect(next.level, AacLevel.level2);
      expect(next.manuallySet, isTrue);
      expect(next.updatedAt, now);
    });

    test('toJson/fromJson round-trips', () {
      final state = AacProgressionState(
        level: AacLevel.level3,
        manuallySet: true,
        updatedAt: now,
      );
      final restored = AacProgressionState.fromJson(state.toJson());
      expect(restored.level, AacLevel.level3);
      expect(restored.manuallySet, isTrue);
      expect(restored.updatedAt, now);
    });
  });
}
