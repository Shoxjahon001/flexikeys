library aac_sentence_composer_service;

import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/network/secure_token_store.dart';
import '../domain/aac_card_def.dart';

/// Composes a natural sentence from Sentence Strip words via the backend
/// AI layer (`POST /aac/compose-sentence`, see backend/src/flexikeys/
/// modules/aac/). Falls back to a naive space-joined sentence — identical
/// in spirit to the backend's own offline fallback
/// (`AacService._template_sentence`) — whenever there's no active child
/// session, no network, or the call is slow/fails. A child always hears
/// *something* the instant they tap speak; the AI call can only upgrade
/// that sentence, never gate it.
class AacSentenceComposerService {
  AacSentenceComposerService._();
  static final AacSentenceComposerService instance = AacSentenceComposerService._();

  final ApiClient _api = ApiClient.instance;

  /// Shorter than ApiClient's own internal 10s timeout — waiting that long
  /// in silence for a "nicer" sentence is worse than speaking the naive
  /// join promptly.
  static const _timeout = Duration(seconds: 3);

  Future<String> compose({
    required List<String> words,
    required AacLanguage language,
  }) async {
    final fallback = words.join(' ');
    if (words.isEmpty) return fallback;

    // Everything below can fail in ordinary, expected ways (no secure
    // storage available yet, offline, slow network, backend down) — all of
    // it collapses to the same safe fallback, never an uncaught exception.
    try {
      final childId = await SecureTokenStore.instance.getActiveChildId();
      if (childId == null) return fallback;

      final resp = await _api
          .post(
            '/aac/compose-sentence',
            auth: TokenKind.childSession,
            body: {
              'child_id': childId,
              'words': words,
              'language': language.code,
            },
          )
          .timeout(_timeout);
      if (resp.statusCode != 200) return fallback;

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final sentence = data['sentence'] as String?;
      if (sentence == null || sentence.trim().isEmpty) return fallback;
      return sentence;
    } catch (_) {
      return fallback;
    }
  }
}
