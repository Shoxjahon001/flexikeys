library audio_service;

/// AudioService: sequential queue for lesson audio playback.
///
/// Responsibilities:
/// - Play curriculum audio files (letters, words, animal sounds) in order.
/// - Preload the next item while current one plays (reduces perceived latency).
/// - Disk-cache downloaded audio so offline sessions work.
/// - Honor COPPA: no external analytics; all logging is local and non-PII.
///
/// Usage:
///   await AudioService.instance.playSequence([item1audioUrl, item2audioUrl]);
///   await AudioService.instance.stopAll();

import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final _player = AudioPlayer();
  bool _initialized = false;
  String? _cacheDir;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    final dir = await getApplicationSupportDirectory();
    _cacheDir = '${dir.path}/audio_cache';
    await Directory(_cacheDir!).create(recursive: true);
    await _player.setAudioContext(AudioContext(
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: const {AVAudioSessionOptions.mixWithOthers},
      ),
      android: const AudioContextAndroid(
        audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        isSpeakerphoneOn: false,
        stayAwake: false,
        contentType: AndroidContentType.speech,
        usageType: AndroidUsageType.media,
      ),
    ));
    _initialized = true;
  }

  /// Download [url] to disk cache and return local file path.
  /// Returns the local path immediately if the file is already cached.
  Future<String?> _cachedPath(String url) async {
    await _ensureInit();
    final cacheKey = Uri.parse(url).pathSegments.join('_').replaceAll('/', '_');
    final file = File('$_cacheDir/$cacheKey');
    if (await file.exists()) return file.path;
    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      }
    } catch (_) {
      // Network unavailable — caller handles null gracefully.
    }
    return null;
  }

  /// Play a single audio URL. Waits until playback completes.
  Future<void> play(String url) async {
    final path = await _cachedPath(url);
    if (path == null) return;
    await _player.play(DeviceFileSource(path));
    await _player.onPlayerComplete.first;
  }

  /// Play [urls] in sequence, preloading the next file during playback.
  /// Stops early if [stopSignal] is set to true by the caller.
  Future<void> playSequence(
    List<String> urls, {
    bool Function()? stopSignal,
  }) async {
    for (int i = 0; i < urls.length; i++) {
      if (stopSignal != null && stopSignal()) break;

      // Start preloading next item concurrently.
      final Future<String?>? preload = (i + 1 < urls.length)
          ? _cachedPath(urls[i + 1])
          : null;

      await play(urls[i]);
      await preload; // ensure preload completes (or fails) before moving on
    }
  }

  /// Play an animal item: sound first (e.g. "Moooo"), then the word audio.
  Future<void> playAnimalItem({
    required String soundUrl,
    required String wordUrl,
    bool Function()? stopSignal,
  }) async {
    await playSequence([soundUrl, wordUrl], stopSignal: stopSignal);
  }

  Future<void> stopAll() async {
    await _player.stop();
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}