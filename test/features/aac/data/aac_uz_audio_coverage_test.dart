import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

import 'package:flexikeys/features/aac/data/aac_card_repository.dart';
import 'package:flexikeys/features/aac/domain/aac_card_def.dart';

/// Cards with no human-recorded Uzbek audio yet — deliberate, not a bug.
/// See voice_uzb/mapping.csv for why each was excluded:
///   - ne_pe_dad ("pe_dad"): the closest candidate recording was too
///     ambiguous to confidently confirm as "dad" — left on the
///     AacNeuralTtsService/TtsService fallback until re-recorded.
///   - pa_tablet, pl_bedroom: a recording exists but says something
///     different from the app's exact text (topically close, wording
///     differs) — pending a listen-and-decide.
/// If a key is ever recorded, remove it here — this set intentionally
/// shrinks over time, never grows without a matching mapping.csv update.
const _uzAudioPending = {'pe_dad', 'pa_tablet', 'pl_bedroom'};

void main() {
  testWidgets(
    'every uz audio key either resolves to a real bundled asset or is a documented pending exception',
    (tester) async {
      final cards = await AacCardRepository.instance.loadStarterVocabulary();

      final checked = <String>{};
      final missing = <String>[];
      final unexpectedlyPresent = <String>[];

      Future<void> checkUnit(String id, String? path) async {
        checked.add(id);
        if (_uzAudioPending.contains(id)) {
          // Pending keys must NOT have a resolvable asset yet — if one
          // shows up, mapping.csv/this exception set is stale and should
          // be updated together, not silently left inconsistent.
          var resolvable = true;
          try {
            final bytes = await rootBundle.load(path ?? '');
            resolvable = bytes.lengthInBytes > 0;
          } catch (_) {
            resolvable = false;
          }
          if (resolvable) unexpectedlyPresent.add(id);
          return;
        }

        if (path == null || path.isEmpty) {
          missing.add('$id (no audio_asset.uz path declared)');
          return;
        }
        try {
          final bytes = await rootBundle.load(path);
          if (bytes.lengthInBytes == 0) {
            missing.add('$id ($path resolves but is empty)');
          }
        } catch (e) {
          missing.add('$id ($path failed to load: $e)');
        }
      }

      for (final card in cards) {
        await checkUnit(card.id, card.audioAsset[AacLanguage.uz]);
        for (final opt in card.fringeOptions) {
          await checkUnit(opt.id, opt.audioAsset[AacLanguage.uz]);
        }
      }

      expect(missing, isEmpty,
          reason: 'uz audio keys with no resolvable bundled asset: $missing');
      expect(unexpectedlyPresent, isEmpty,
          reason: 'These are listed as pending in _uzAudioPending but now '
              'resolve to a real asset — remove them from the pending set: '
              '$unexpectedlyPresent');

      // Sanity check the exception set itself isn't stale in the other
      // direction (referencing a card id that no longer exists).
      final unknownPending = _uzAudioPending.difference(checked);
      expect(unknownPending, isEmpty,
          reason: '_uzAudioPending references unknown card/fringe ids: $unknownPending');
    },
  );
}
