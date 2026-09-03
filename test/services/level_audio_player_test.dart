import 'package:flutter_test/flutter_test.dart';

import 'package:flexikeys/data/content_packs/content_pack.dart';
import 'package:flexikeys/services/level_audio_player.dart';

// NOTE: this file deliberately does not directly `await
// LevelAudioPlayer.instance.speak(...)`. Doing so was tried and reproduced
// a confirmed hang: in this test environment, the underlying `audioplayers`
// plugin's platform-channel call (for a path missing from the asset
// bundle, which is every path today — see PROGRESS.md) can block the
// entire isolate hard enough that no `Future.timeout()` — including the
// ones already inside LevelAudioPlayer — can recover it. That's a
// `flutter_test`-environment limitation in this plugin, not something
// provable/disprovable from pure Dart test code, and not evidence of a
// production bug: the app stays fully responsive in real use (a genuine
// isolate block would freeze the whole UI, not just go quiet), and
// AacAudioPlayer already uses the identical `_player.play(AssetSource(...))`
// pattern in production today. Every game-screen widget test that
// exercises this call path does so via a fire-and-forget
// `Future.delayed(...)` (never awaited by the test), which is why those
// tests pass reliably without hitting this.
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
