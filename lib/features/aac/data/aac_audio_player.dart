library aac_audio_player;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../../../services/tts_service.dart';
import '../domain/aac_card_def.dart';
import 'aac_neural_tts_service.dart';

/// Speaks a card or fringe-option's sentence when a child taps it.
///
/// Three-tier fallback, each strictly better-effort than the next:
///   1. The pre-produced audio asset bundled for the active language (one
///      calm professional voice per language, see docs/aac_design_system.md
///      and tools/generate_aac_audio.py) — e.g.
///      `shared/aac/audio/en/ne_water.mp3`. Covers every fixed vocabulary
///      card/fringe-option/sentence. Container isn't uniform across
///      languages: en/ru are Azure-generated MP3 (via generate_aac_audio.py,
///      not yet run as of this writing); uz is human-recorded AAC/M4A (see
///      voice_uzb/mapping.csv) — `AssetSource` doesn't care, it just plays
///      whatever the JSON's `audio_asset[lang]` path points to.
///   2. [AacNeuralTtsService] — the backend's Azure neural TTS, disk-cached.
///      Only reached for text with no bundled asset, which today means an
///      ad-hoc Sentence Strip composition (bundledAssetPath is always null
///      for those — see AacSentenceStripScreen._speak()), OR a starter card
///      whose bundled asset doesn't exist yet (e.g. pe_dad/pa_tablet/
///      pl_bedroom in uz — see voice_uzb/mapping.csv for why those three
///      were deliberately left unrecorded).
///   3. [TtsService] (online, cached) reading [sentence] aloud — the
///      original, still-real last resort if the backend is unreachable or
///      has no Azure key configured. Without this tier a tap could go
///      silent — never acceptable for an AAC device.
///
/// Vocabulary asset paths (e.g. `shared/aac/audio/en/ne_water.mp3`) are
/// declared exactly as registered under `flutter: assets:` in pubspec.yaml
/// (`shared/aac/`, not `assets/`), so the player's [AudioCache] prefix is
/// cleared — audioplayers' default `AssetSource` prefix is `'assets/'`
/// (see audioplayers' `AudioCache.prefix` doc), which would otherwise look
/// for the file under a non-existent `assets/shared/aac/...` path.
class AacAudioPlayer {
  AacAudioPlayer._() {
    _player.audioCache = AudioCache(prefix: '');
  }
  static final AacAudioPlayer instance = AacAudioPlayer._();

  final AudioPlayer _player = AudioPlayer();

  // Monotonic generation guard: a `stop()` (or a newer `speak()`) bumps
  // this, and every stage below checks it before actually starting
  // playback — so a neural-TTS network fetch that's still in flight when
  // the active locale changes can never start speaking the old language
  // after the fact. Mirrors TtsService's own `_playId`.
  int _playId = 0;

  void _log(String message) {
    if (kDebugMode) debugPrint('AacAudioPlayer: $message');
  }

  /// Plays [bundledAssetPath] if present and loadable; otherwise tries
  /// backend neural TTS; otherwise falls back to [TtsService].
  ///
  /// [isDeviceFile] distinguishes a parent-recorded custom-card voice (a
  /// real absolute file path under the app's documents directory, played
  /// via [DeviceFileSource]) from a bundled starter-vocabulary asset
  /// (played via [AssetSource]) — the two need different audioplayers
  /// source types. Callers pass `card.isCustom`: a custom card's
  /// `audioAsset[language]`, if set, is always a recorded device file;
  /// a starter card's is always a bundled Flutter asset.
  Future<void> speak({
    required String? bundledAssetPath,
    required String sentence,
    required AacLanguage language,
    bool isDeviceFile = false,
  }) async {
    final id = ++_playId;

    if (bundledAssetPath != null && bundledAssetPath.isNotEmpty) {
      try {
        await _player.stop();
        if (id != _playId) return; // superseded while stopping
        final source = isDeviceFile
            ? DeviceFileSource(bundledAssetPath)
            : AssetSource(bundledAssetPath);
        // Subscribed before play() is awaited: play()'s Future resolves once
        // playback *starts*, not once it ends, and attaching the listener
        // only after that await could miss a very short clip's completion
        // event entirely. AacConfirmationScreen awaits this whole method to
        // know when the spoken audio has actually finished (so it can start
        // its auto-dismiss timer) — a parent-recorded custom-card voice can
        // run several seconds, so returning at playback-start (as this used
        // to do) meant the confirmation screen could close and cut the
        // recording off mid-sentence. The timeout is a safety net only, in
        // case the completion event never fires (e.g. a file that failed to
        // decode silently instead of throwing) — it does not fail the call.
        final completed = _player.onPlayerComplete.first;
        await _player.play(source);
        if (id != _playId) {
          await _player.stop();
          return;
        }
        await completed.timeout(const Duration(seconds: 20), onTimeout: () {});
        _log('played bundled asset ($bundledAssetPath)');
        return;
      } catch (_) {
        // Asset/file missing or undecodable — fall through to neural TTS.
        _log('bundled asset failed/missing ($bundledAssetPath) — trying neural TTS');
      }
    }

    final neuralFile = await AacNeuralTtsService.instance.synthesize(
      text: sentence,
      lang: language.code,
    );
    if (id != _playId) return; // language/word changed while fetching

    if (neuralFile != null) {
      try {
        await _player.stop();
        if (id != _playId) return;
        final completed = _player.onPlayerComplete.first;
        await _player.play(DeviceFileSource(neuralFile.path));
        if (id != _playId) {
          await _player.stop();
          return;
        }
        await completed.timeout(const Duration(seconds: 20), onTimeout: () {});
        _log('played neural TTS (backend/disk cache)');
        return;
      } catch (_) {
        _log('neural TTS file failed to play — falling back to device TTS');
      }
    } else {
      _log('neural TTS unavailable — falling back to device TTS');
    }

    if (id != _playId) return;
    await TtsService.instance.speak(sentence, locale: language.code);
    _log('played device TTS (TtsService) for "$sentence" [${language.code}]');
  }

  Future<void> stop() async {
    _playId++;
    try {
      await _player.stop();
    } catch (_) {}
    await TtsService.instance.stop();
  }
}
