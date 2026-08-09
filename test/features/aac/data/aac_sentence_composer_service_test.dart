import 'package:flutter_test/flutter_test.dart';

import 'package:flexikeys/features/aac/data/aac_sentence_composer_service.dart';
import 'package:flexikeys/features/aac/domain/aac_card_def.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AacSentenceComposerService', () {
    test('empty word list returns an empty string, never throws', () async {
      final result = await AacSentenceComposerService.instance.compose(
        words: const [],
        language: AacLanguage.en,
      );
      expect(result, '');
    });

    // No secure-storage platform channel is available in this test
    // environment (no plugin mock registered) — compose() must treat that
    // failure the same as "no active child session" and fall back to the
    // naive word-join rather than throwing, exactly the guarantee that
    // matters for a child who taps "speak" with no network available.
    test(
      'falls back to the naive word-join when child session lookup fails',
      () async {
        final result = await AacSentenceComposerService.instance.compose(
          words: const ['water', 'please'],
          language: AacLanguage.en,
        );
        expect(result, 'water please');
      },
    );
  });
}
