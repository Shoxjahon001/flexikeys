import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../data/content_packs/content_pack.dart';
import 'tts_service.dart';

/// Speaks a level-content item (a letter, a number word, a spelling word)
/// when a child taps it or completes it.
///
/// Two-tier fallback:
///   1. The pre-produced audio asset bundled for [locale], if present —
///      see tools/generate_level_audio.py and shared/level_content/. As of
///      this writing no locale has any generated files yet (Azure
///      credentials pending) — this tier always falls through to (2) for
///      every item, in every locale, until real files exist and are
///      declared under `flutter: assets:` in pubspec.yaml. The `play()`
///      call itself is time-bounded (not just the completion event) —
///      audioplayers has no documented contract for how quickly a path
///      missing from the asset bundle fails.
///   2. [TtsService] (online, cached) — the same live fallback every
///      level-content call site used before this class existed, so a tap
///      never goes silent regardless of asset-generation progress.
///
/// Deliberately does NOT add [AacAudioPlayer]'s middle neural-TTS-backend
/// tier ([AacNeuralTtsService]) — that tier's first step,
/// `SecureTokenStore.getActiveChildId()` (`flutter_secure_storage`), was
/// confirmed (empirically, via a reproduced hang in this exact codebase)
/// to be able to block the entire isolate hard enough that not even a
/// manual `Future.any` race against a plain `Future.delayed` could recover
/// — a risk no `Future.timeout()` anywhere in this class can defend
/// against, since a genuinely blocked isolate can't run the timer that
/// would fire it. The actual Russian-Learn-content silence bug this class
/// exists to fix turned out to be unrelated to tiering at all: every
/// Drawing/Learn TTS call site was omitting `locale:` entirely, always
/// defaulting to `en` — see PROGRESS.md.
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
      await _playBundledAsset(id, assetPath);
      if (id != _playId) return;
      _log('played bundled asset ($assetPath)');
      return;
    } catch (_) {
      _log('bundled asset missing/failed/timed out ($assetPath) — falling back to TtsService');
    }

    if (id != _playId) return;
    await TtsService.instance.speak(item.spokenText, locale: locale);
  }

  /// Throws (including [TimeoutException]) on anything short of a fully
  /// completed (or superseded) playback — [speak] treats any exception
  /// here as "try the next tier."
  Future<void> _playBundledAsset(int id, String assetPath) async {
    await _player.stop();
    if (id != _playId) return;
    final completed = _player.onPlayerComplete.first;
    // Bounds play() itself, not just the completion event below — a path
    // missing from the asset bundle has no documented fast-fail contract.
    await _player.play(AssetSource(assetPath)).timeout(const Duration(seconds: 5));
    if (id != _playId) {
      await _player.stop();
      return;
    }
    await completed.timeout(const Duration(seconds: 10), onTimeout: () {});
  }

  Future<void> stop() async {
    _playId++;
    try {
      await _player.stop();
    } catch (_) {}
    await TtsService.instance.stop();
  }
}
