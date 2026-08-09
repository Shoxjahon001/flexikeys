import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'user_service.dart';

/// Online TTS via Google Translate's synthesis endpoint.
///
/// Audio is fetched once, cached on device, and replayed instantly thereafter.
/// The voice is generated server-side → byte-identical on every phone brand
/// and OS version (iOS, Android, Samsung, Redmi, Xiaomi…).
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final _player = AudioPlayer();
  Directory? _cacheDir;
  bool _ready = false;
  bool _initializing = false;
  double _volume = 1.0;
  int _playId = 0; // cancels stale plays when a new one is requested

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_ready || _initializing) return;
    _initializing = true;
    try {
      // iOS:     playback + mixWithOthers — not silenced by Ring/Silent switch.
      // Android: speech/assistant — system knows this is spoken word content.
      // Wrapped separately so a platform rejection doesn't kill the whole init.
      try {
        await _player.setAudioContext(AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.speech,
            usageType: AndroidUsageType.assistant,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
        ));
      } catch (_) {}

      final dir = await getApplicationCacheDirectory();
      _cacheDir = Directory('${dir.path}/tts_v1');
      await _cacheDir!.create(recursive: true);

      // Mark ready before volume setup — a volume failure must not block TTS.
      _ready = true;

      try {
        _volume = await UserService.getVolume();
        await _player.setVolume(_volume);
      } catch (_) {}
    } catch (_) {
    } finally {
      _initializing = false;
    }
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Speak a word or sentence at a natural reading pace.
  ///
  /// [locale] selects the synthesis voice — 'en' (default, preserves
  /// existing behavior for every pre-existing call site), 'uz', or 'ru'.
  Future<void> speak(String text, {String locale = 'en'}) =>
      _play(text, rate: 0.88, locale: locale);

  /// Speak a short celebratory phrase — slightly brighter and more energetic.
  Future<void> speakFunny(String text, {String locale = 'en'}) =>
      _play(text, rate: 1.05, locale: locale);

  Future<void> stop() async {
    _playId++;
    try {
      await _player.stop();
    } catch (_) {}
  }

  Future<void> setVolume(double vol) async {
    _volume = vol.clamp(0.0, 1.0);
    try {
      await _player.setVolume(_volume);
    } catch (_) {}
    await UserService.setVolume(_volume);
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  Future<void> _play(String raw,
      {required double rate, String locale = 'en'}) async {
    final text = raw.trim().toLowerCase();
    if (text.isEmpty) return;
    if (!_ready) await init();
    if (!_ready) return;

    final id = ++_playId;
    try {
      await _player.stop();
      if (id != _playId) return; // a newer speak() was called while stopping

      final file = await _fetchOrCache(text, locale: locale);
      if (id != _playId) return; // another word was requested while fetching
      if (file == null) return;

      await _player.setPlaybackRate(rate);
      await _player.setVolume(_volume);
      await _player.play(DeviceFileSource(file.path));
    } catch (_) {}
  }

  // Google Translate TTS locale codes this app's three learning languages
  // map to — 'tl' (target language, the voice) differs slightly in format
  // per language; 'sl' (source language, for translation-adjacent request
  // shaping) is set equal to keep this a pure read-aloud, not a translation.
  static const Map<String, String> _localeCodes = {
    'en': 'en-US',
    'uz': 'uz',
    'ru': 'ru',
  };

  Future<File?> _fetchOrCache(String text, {required String locale}) async {
    final dir = _cacheDir;
    if (dir == null) return null;

    final tl = _localeCodes[locale] ?? _localeCodes['en']!;
    final file = File('${dir.path}/${_key(text, locale)}.mp3');
    if (await file.exists()) return file; // instant cache hit

    // Fetch from Google Translate TTS — server-generated, identical every time.
    try {
      final uri = Uri.https('translate.google.com', '/translate_tts', {
        'ie': 'UTF-8',
        'q': text,
        'tl': tl,
        'client': 'gtx',
        'sl': locale,
      });
      final resp = await http.get(uri, headers: {
        // A standard browser UA avoids rate-limiting on the public endpoint.
        'User-Agent': 'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/116.0.0.0 Mobile Safari/537.36',
        'Referer': 'https://translate.google.com/',
        'Accept': 'audio/mpeg, audio/*',
      }).timeout(const Duration(seconds: 7));

      if (resp.statusCode == 200 && resp.bodyBytes.length > 200) {
        await file.writeAsBytes(resp.bodyBytes);
        return file;
      }
    } catch (_) {}

    return null; // offline or error — caller silently skips TTS
  }

  // Stable, filesystem-safe cache key (DJB2 hash of "locale:text" — the
  // locale prefix keeps different-language renditions of similar-looking
  // text from ever sharing a cache slot).
  String _key(String text, String locale) {
    int h = 5381;
    for (final c in '$locale:$text'.codeUnits) {
      h = ((h << 5) + h + c) & 0x7FFFFFFF;
    }
    return h.toRadixString(16);
  }
}
