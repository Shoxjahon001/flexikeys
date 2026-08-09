library aac_audio_player;

import 'package:audioplayers/audioplayers.dart';

import '../../../services/tts_service.dart';
import '../domain/aac_card_def.dart';

/// Speaks a card or fringe-option's sentence when a child taps it.
///
/// Primary path: the pre-produced audio asset bundled for the active
/// language (one calm professional voice per language, see
/// docs/aac_design_system.md) — e.g. `shared/aac/audio/en/ne_water.mp3`.
/// Falls back to [TtsService] reading [sentence] aloud when that asset is
/// missing or fails to decode, which is true for every starter-vocabulary
/// card today since no audio has been recorded yet (see
/// docs/aac_phase1_architecture.md). Without this fallback a tap would be
/// silent — never acceptable for an AAC device.
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

  /// Plays [bundledAssetPath] if present and loadable; otherwise falls back
  /// to on-device TTS reading [sentence] aloud in [language].
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
    if (bundledAssetPath != null && bundledAssetPath.isNotEmpty) {
      try {
        await _player.stop();
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
        await completed.timeout(const Duration(seconds: 20), onTimeout: () {});
        return;
      } catch (_) {
        // Asset/file missing or undecodable — fall through to the TTS fallback.
      }
    }
    await TtsService.instance.speak(sentence, locale: language.code);
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
    await TtsService.instance.stop();
  }
}
