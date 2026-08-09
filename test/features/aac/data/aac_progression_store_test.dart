import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flexikeys/features/aac/data/aac_progression_store.dart';
import 'package:flexikeys/features/aac/domain/aac_progression.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AacProgressionStore.instance.resetCacheForTesting();
  });

  group('AacProgressionStore', () {
    test('defaults to level1, not manually set', () async {
      final state = await AacProgressionStore.instance.get();
      expect(state.level, AacLevel.level1);
      expect(state.manuallySet, isFalse);
    });

    test('setLevel persists the level and marks manuallySet', () async {
      await AacProgressionStore.instance.setLevel(AacLevel.level3);
      final state = await AacProgressionStore.instance.get();
      expect(state.level, AacLevel.level3);
      expect(state.manuallySet, isTrue);
    });

    test('persists across cache resets (round-trips through SharedPreferences)', () async {
      await AacProgressionStore.instance.setLevel(AacLevel.level4);
      AacProgressionStore.instance.resetCacheForTesting();
      final state = await AacProgressionStore.instance.get();
      expect(state.level, AacLevel.level4);
    });
  });
}
