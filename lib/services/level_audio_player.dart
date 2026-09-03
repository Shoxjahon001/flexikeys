import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../data/content_packs/content_pack.dart';
import 'tts_service.dart';

/// Speaks a level-content item (a letter, a number word, a spelling word)
/// when a child taps it or completes it.
///
/// Two-tier fallback, mirroring [AacAudioPlayer]'s pattern minus its
/// middle neural-TTS-backend tier (no such endpoint exists for level
/// content — out of scope here, see PROGRESS.md):
///   1. The pre-produced audio asset bundled for [locale], if present —
///      see tools/generate_level_audio.py and shared/level_content/. As of
///      this writing no locale has any generated files yet (Azure
///      credentials pending) — this tier always falls through to (2) for
///      every item, in every locale, until real files exist and are
///      declared under `flutter: assets:` in pubspec.yaml.
///   2. [TtsService] (online, cached) — the same live fallback every
///      level-content call site already used before this class existed,
///      so a tap never goes silent regardless of asset-generation
///      progress.
class LevelAudioPlayer {
  LevelAudioPlayer._() {
    _player.audioCache = AudioCache(prefix: '');
  }
  static final LevelAudioPlayer instance = LevelAudioPlayer._();

  final AudioPlayer _player = AudioPlayer();

  // Monotonic generation guard, same contract as TtsService/AacAudioPlayer's
  // own `_playId` — a newer speak() (or stop()) cancels a still-in-flight
  // older one rather than letting it start audible playback after the fact.
  int _playId = 0;

  void _log(String message) {
    if (kDebugMode) debugPrint('LevelAudioPlayer: $message');
  }

  /// [item]'s bundled-asset path for [locale] — matches exactly what
  /// tool/export_audio_manifest.dart declares and
  /// tools/generate_level_audio.py writes to.
  static String assetPathFor(ContentItem item, String locale) {
    final prefix = '$locale.';
    final bareId =
        item.id.startsWith(prefix) ? item.id.substring(prefix.length) : item.id;
    return 'shared/level_content/audio/$locale/$bareId.mp3';
  }

  Future<void> speak(ContentItem item, {required String locale}) async {
    final id = ++_playId;
    final assetPath = assetPathFor(item, locale);

    try {
      await _player.stop();
      if (id != _playId) return; // superseded while stopping
      final completed = _player.onPlayerComplete.first;
      await _player.play(AssetSource(assetPath));
      if (id != _playId) {
        await _player.stop();
        return;
      }
      await completed.timeout(const Duration(seconds: 10), onTimeout: () {});
      _log('played bundled asset ($assetPath)');
      return;
    } catch (_) {
      // Asset missing or undecodable — fall through to live TTS.
      _log('bundled asset missing/failed ($assetPath) — falling back to TtsService');
    }

    if (id != _playId) return;
    await TtsService.instance.speak(item.spokenText, locale: locale);
  }

  Future<void> stop() async {
    _playId++;
    try {
      await _player.stop();
    } catch (_) {}
    await TtsService.instance.stop();
  }
}
