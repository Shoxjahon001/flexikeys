import 'package:flutter_tts/flutter_tts.dart';
import 'user_service.dart';

/// Singleton wrapper around FlutterTts.
/// Call [init] once at app startup, then [speak] from anywhere.
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final _tts = FlutterTts();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.42);
      await _tts.setPitch(1.1);
      await _tts.awaitSpeakCompletion(false);
      final vol = await UserService.getVolume();
      await _tts.setVolume(vol);
      _initialized = true;
    } catch (_) {
      // TTS unavailable on this device — app continues silently
    }
  }

  Future<void> speak(String text) async {
    if (!_initialized) await init();
    if (!_initialized) return;
    try {
      await _tts.stop();
      await _tts.speak(text.toLowerCase());
    } catch (_) {}
  }

  Future<void> setVolume(double vol) async {
    final clamped = vol.clamp(0.0, 1.0);
    try {
      await _tts.setVolume(clamped);
    } catch (_) {}
    await UserService.setVolume(clamped);
  }

  Future<void> stop() async {
    try { await _tts.stop(); } catch (_) {}
  }
}
