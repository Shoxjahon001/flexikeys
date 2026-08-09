import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flexikeys/features/aac/data/aac_milestones_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AacMilestonesStore.instance.resetCacheForTesting();
  });

  group('AacMilestonesStore', () {
    test('defaults to not celebrated', () async {
      expect(await AacMilestonesStore.instance.hasCelebratedFirstSentence(), isFalse);
    });

    test('marking celebrated persists', () async {
      await AacMilestonesStore.instance.markFirstSentenceCelebrated();
      expect(await AacMilestonesStore.instance.hasCelebratedFirstSentence(), isTrue);
    });

    test('persists across cache resets', () async {
      await AacMilestonesStore.instance.markFirstSentenceCelebrated();
      AacMilestonesStore.instance.resetCacheForTesting();
      expect(await AacMilestonesStore.instance.hasCelebratedFirstSentence(), isTrue);
    });
  });
}
