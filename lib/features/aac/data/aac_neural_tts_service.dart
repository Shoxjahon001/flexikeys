library aac_neural_tts_service;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/secure_token_store.dart';

/// Neural TTS for ad-hoc AAC text via the backend (`POST /aac/tts`, Azure
/// Speech neural voices — see backend/src/flexikeys/services/
/// tts_provider.py). Used only for text that isn't known ahead of time —
/// a composed Sentence Strip sentence — never for the 37 fixed vocabulary
/// cards, which have real bundled audio generated offline by
/// tools/generate_aac_audio.py and never reach the network.
///
/// Disk-cached under the app documents directory (audio_cache/{lang}/
/// {hash}.mp3), keyed by a hash of the text itself rather than a card id —
/// there is no card id for an ad-hoc composed sentence. A given composition
/// repeats often in real use ("I want water." gets composed a lot), so a
/// second play of the same sentence never touches the network.
class AacNeuralTtsService {
  AacNeuralTtsService._();
  static final AacNeuralTtsService instance = AacNeuralTtsService._();

  /// Shorter than ApiClient's own internal 10s timeout — per the task
  /// contract, a slow neural-TTS call must not make a child wait; the
  /// caller falls back to on-device TTS instead.
  static const _timeout = Duration(seconds: 5);

  Directory? _documentsDir;

  Future<Directory> _documents() async =>
      _documentsDir ??= await getApplicationDocumentsDirectory();

  /// Returns a playable local file for [text] in [lang] — from disk cache
  /// if already fetched, otherwise from the backend. Returns null (never
  /// throws, never hangs) on any failure: network error, timeout, non-200,
  /// the backend having no Azure key configured (503), or a platform-level
  /// failure reaching the cache directory itself. The caller is expected to
  /// fall back to on-device TTS in every one of those cases. [_timeout]
  /// bounds the whole operation, not just the network call — a plugin
  /// channel with no registered handler (a real Flutter-test-harness
  /// failure mode, not just production) hangs rather than throwing, and a
  /// timeout on only the HTTP step wouldn't catch that.
  Future<File?> synthesize({required String text, required String lang}) async {
    try {
      return await _doSynthesize(text, lang).timeout(_timeout);
    } catch (e) {
      _log('neural TTS failed [$lang] "$text": $e');
      return null;
    }
  }

  Future<File?> _doSynthesize(String text, String lang) async {
    // Same guard AacSentenceComposerService.compose() already uses — a
    // child-session-authed call with no active child session is a doomed
    // 401, not just a wasted request. Checked before the disk cache too
    // (not just the network call): a cache file only ever exists here
    // because some earlier call with an active session wrote it, so no
    // session now means the disk lookup can only ever miss anyway — and
    // skipping it means a screen with no active session (offline, or
    // before login completes — a real, expected AAC state per this app's
    // offline-first design, not just a test artifact) never touches the
    // filesystem at all.
    final childId = await SecureTokenStore.instance.getActiveChildId();
    if (childId == null) {
      _log('no active child session — skipping neural TTS [$lang] "$text"');
      return null;
    }

    final root = await _documents();
    final file = File('${root.path}/audio_cache/$lang/${_hash(text)}.mp3');
    if (await file.exists()) {
      _log('disk cache hit [$lang] "$text"');
      return file;
    }

    final resp = await ApiClient.instance.post(
      '/aac/tts',
      auth: TokenKind.childSession,
      body: {'text': text, 'lang': lang},
    );
    if (resp.statusCode != 200 || resp.bodyBytes.isEmpty) {
      _log('backend returned ${resp.statusCode} [$lang] "$text"');
      return null;
    }

    // Directory creation deferred to here — only right before an actual
    // write, not on every call (a cache-hit or no-session path above never
    // needs to touch the filesystem beyond the read-only existence check).
    await file.parent.create(recursive: true);
    await file.writeAsBytes(resp.bodyBytes);
    _log('backend synthesis ok, cached to disk [$lang] "$text"');
    return file;
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('AacNeuralTtsService: $message');
  }

  // Stable, filesystem-safe cache key (DJB2 hash) — same scheme as
  // TtsService's own cache key, minus the locale prefix (already a
  // separate subdirectory here).
  String _hash(String text) {
    int h = 5381;
    for (final c in text.codeUnits) {
      h = ((h << 5) + h + c) & 0x7FFFFFFF;
    }
    return h.toRadixString(16);
  }
}
