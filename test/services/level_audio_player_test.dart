import 'package:flutter_test/flutter_test.dart';

import 'package:flexikeys/data/content_packs/content_pack.dart';
import 'package:flexikeys/services/level_audio_player.dart';

void main() {
  test('assetPathFor strips the locale prefix and matches the manifest '
      "exporter's own convention exactly", () {
    const item = ContentItem(id: 'ru.animals.zebra', display: '🦓', word: 'ЗЕБРА');
    expect(LevelAudioPlayer.assetPathFor(item, 'ru'),
        'shared/level_content/audio/ru/animals.zebra.mp3');
  });

  test('assetPathFor for en', () {
    const item = ContentItem(id: 'en.letters.a', display: 'A', word: 'A');
    expect(LevelAudioPlayer.assetPathFor(item, 'en'),
        'shared/level_content/audio/en/letters.a.mp3');
  });

  test('assetPathFor falls back to the full id if it somehow lacks the '
      'expected locale prefix (defensive — should never happen for a '
      'real content-pack item)', () {
    const item = ContentItem(id: 'weird_id', display: 'X', word: 'X');
    expect(LevelAudioPlayer.assetPathFor(item, 'ru'),
        'shared/level_content/audio/ru/weird_id.mp3');
  });
}
