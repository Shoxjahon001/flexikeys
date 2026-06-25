import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

/// Plays short synthesized sound effects (ding = correct, buzz = wrong).
/// Uses temp files (DeviceFileSource) for reliable iOS + Android playback.
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  String? _correctPath;
  String? _wrongPath;

  final _correctPlayer = AudioPlayer();
  final _wrongPlayer = AudioPlayer();

  bool _ready = false;
  bool _initializing = false;

  Future<void> init() async {
    if (_ready || _initializing) return;
    _initializing = true;
    try {
      // iOS: playback + mixWithOthers → not silenced by Ring/Silent switch,
      //      plays alongside TTS without interrupting it.
      // Android: sonification content, game usage, duck other audio briefly.
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.game,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
        ),
      );

      // Write WAV bytes to temp files; DeviceFileSource is reliably supported
      // on both iOS and Android, unlike BytesSource which can fail on iOS.
      final dir = await getTemporaryDirectory();
      final correctFile = File('${dir.path}/flexikeys_ding.wav');
      final wrongFile = File('${dir.path}/flexikeys_buzz.wav');
      await correctFile.writeAsBytes(_makeDing());
      await wrongFile.writeAsBytes(_makeBuzz());
      _correctPath = correctFile.path;
      _wrongPath = wrongFile.path;

      _ready = true;
    } catch (_) {
      // Silently fail — sound effects are non-critical.
    } finally {
      _initializing = false;
    }
  }

  Future<void> playCorrect() async {
    if (!_ready) await init();
    final path = _correctPath;
    if (path == null) return;
    try {
      await _correctPlayer.play(DeviceFileSource(path));
    } catch (_) {}
  }

  Future<void> playWrong() async {
    if (!_ready) await init();
    final path = _wrongPath;
    if (path == null) return;
    try {
      await _wrongPlayer.play(DeviceFileSource(path));
    } catch (_) {}
  }

  // ─── WAV synthesis ──────────────────────────────────────────────────────────

  /// Bell-like ding: 880 Hz with harmonics, exponential decay, 350 ms.
  static Uint8List _makeDing() {
    const sampleRate = 22050;
    const freq = 880.0;
    const durationSec = 0.35;
    final n = (sampleRate * durationSec).toInt();
    final pcm = List<int>.filled(n, 0);
    for (int i = 0; i < n; i++) {
      final t = i / sampleRate;
      final env = exp(-t * 7.0);
      final wave = sin(2 * pi * freq * t) * 0.70 +
                   sin(2 * pi * freq * 2 * t) * 0.20 +
                   sin(2 * pi * freq * 3 * t) * 0.10;
      pcm[i] = (wave * env * 0.75 * 32767).round().clamp(-32767, 32767);
    }
    return _buildWav(pcm, sampleRate);
  }

  /// Descending buzzy tone: 330→140 Hz, sawtooth-sine mix, 300 ms.
  static Uint8List _makeBuzz() {
    const sampleRate = 22050;
    const durationSec = 0.30;
    final n = (sampleRate * durationSec).toInt();
    final pcm = List<int>.filled(n, 0);
    double phase = 0;
    for (int i = 0; i < n; i++) {
      final t = i / sampleRate;
      final freq = 330.0 - (190.0 * t / durationSec);
      phase += 2 * pi * freq / sampleRate;
      final env = (t < 0.015 ? t / 0.015 : exp(-(t - 0.015) * 9.0))
          .clamp(0.0, 1.0);
      final saw = ((phase / (2 * pi)) % 1.0) * 2 - 1;
      final wave = sin(phase) * 0.5 + saw * 0.5;
      pcm[i] = (wave * env * 0.65 * 32767).round().clamp(-32767, 32767);
    }
    return _buildWav(pcm, sampleRate);
  }

  static Uint8List _buildWav(List<int> pcm, int sampleRate) {
    final dataSize = pcm.length * 2;
    final buf = ByteData(44 + dataSize);
    _str(buf, 0,  'RIFF');
    buf.setUint32(4,  36 + dataSize, Endian.little);
    _str(buf, 8,  'WAVE');
    _str(buf, 12, 'fmt ');
    buf.setUint32(16, 16, Endian.little);
    buf.setUint16(20, 1,  Endian.little); // PCM
    buf.setUint16(22, 1,  Endian.little); // mono
    buf.setUint32(24, sampleRate,     Endian.little);
    buf.setUint32(28, sampleRate * 2, Endian.little); // byte rate
    buf.setUint16(32, 2,  Endian.little); // block align
    buf.setUint16(34, 16, Endian.little); // bits per sample
    _str(buf, 36, 'data');
    buf.setUint32(40, dataSize, Endian.little);
    for (int i = 0; i < pcm.length; i++) {
      buf.setInt16(44 + i * 2, pcm[i], Endian.little);
    }
    return buf.buffer.asUint8List();
  }

  static void _str(ByteData buf, int offset, String s) {
    for (int i = 0; i < s.length; i++) {
      buf.setUint8(offset + i, s.codeUnitAt(i));
    }
  }
}
