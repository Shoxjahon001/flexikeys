import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';
import 'user_service.dart';

class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final _tts = FlutterTts();
  bool _initialized = false;

  static double get _defaultPitch => 1.1;
  static double get _defaultRate => Platform.isIOS ? 0.50 : 0.42;

  Future<void> init() async {
    if (_initialized) return;
    try {
      if (Platform.isIOS) {
        await _tts.setSharedInstance(true);
        // playback + mixWithOthers: not silenced by Ring/Silent switch,
        // plays alongside audioplayers sounds without interruption.
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [IosTextToSpeechAudioCategoryOptions.mixWithOthers],
          IosTextToSpeechAudioMode.defaultMode,
        );
      }

      // Prefer Australian accent (more melodic), fall back to US English.
      await _setLanguageWithFallback();

      await _tts.setSpeechRate(_defaultRate);
      await _tts.setPitch(_defaultPitch);
      await _tts.awaitSpeakCompletion(false);
      final vol = await UserService.getVolume();
      await _tts.setVolume(vol);
      _initialized = true;
    } catch (_) {}
  }

  Future<void> _setLanguageWithFallback() async {
    try {
      final result = await _tts.setLanguage('en-AU');
      // flutter_tts returns 1 on success, 0 on failure (varies by platform).
      if (result == 0) throw Exception('en-AU not available');
    } catch (_) {
      try {
        await _tts.setLanguage('en-US');
      } catch (_) {}
    }
  }

  Future<void> speak(String text) async {
    if (!_initialized) await init();
    if (!_initialized) return;
    try {
      await _tts.stop();
      await _tts.setPitch(_defaultPitch);
      await _tts.setSpeechRate(_defaultRate);
      await _tts.speak(text.toLowerCase());
    } catch (_) {}
  }

  /// Happy, clear celebratory voice — fun but easy for kids to understand.
  Future<void> speakFunny(String text) async {
    if (!_initialized) await init();
    if (!_initialized) return;
    try {
      await _tts.stop();
      await _tts.setPitch(1.6);
      await _tts.setSpeechRate(Platform.isIOS ? 0.44 : 0.50);
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
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
