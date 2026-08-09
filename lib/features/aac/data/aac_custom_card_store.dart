library aac_custom_card_store;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/aac_card_def.dart';

/// Parent-created custom AAC cards (own photo, own recorded voice, or typed
/// text for TTS fallback — see docs/aac_design_system.md Phase 4).
///
/// Low-volume, simple mutable state — a parent adds a handful of these,
/// rarely — so this follows the same SharedPreferences typed-JSON-list
/// pattern as `ProgressStore` (lib/services/progress/progress_store.dart),
/// not the drift database (reserved for the high-volume append-only
/// tap-event log — see `AppDatabase`'s doc comment for why each storage
/// choice fits its own use case rather than defaulting everything to one
/// mechanism now that drift is available).
class AacCustomCardStore {
  AacCustomCardStore._();
  static final AacCustomCardStore instance = AacCustomCardStore._();

  static const _key = 'aac_custom_cards_v1';

  List<AacCardDef>? _cache;

  Future<List<AacCardDef>> getAll() async {
    final cached = _cache;
    if (cached != null) return cached;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      _cache = const [];
      return _cache!;
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    _cache = decoded
        .map((e) => AacCardDef.fromJson(e as Map<String, dynamic>))
        .map(_backfillAllLanguages)
        .toList();
    return _cache!;
  }

  /// Cards saved before every language was populated (or created while only
  /// one learning language was active) may have `label`/`sentenceTemplate`/
  /// `audioAsset` set for a single [AacLanguage]. A parent-typed label or
  /// recorded voice isn't translated per language — it's the same text/
  /// audio regardless — so this fills every language key from whichever
  /// value already exists, meaning an older card still displays and speaks
  /// correctly after the child's learning language changes, instead of
  /// falling back to the raw card id or staying silent.
  AacCardDef _backfillAllLanguages(AacCardDef card) {
    Map<AacLanguage, String> fillAll(Map<AacLanguage, String> map) {
      if (map.length >= AacLanguage.values.length) return map;
      final value = map.values.firstOrNull;
      if (value == null) return map;
      return {for (final lang in AacLanguage.values) lang: value};
    }

    final label = fillAll(card.label);
    final sentenceTemplate = fillAll(card.sentenceTemplate);
    final audioAsset = fillAll(card.audioAsset);
    if (identical(label, card.label) &&
        identical(sentenceTemplate, card.sentenceTemplate) &&
        identical(audioAsset, card.audioAsset)) {
      return card;
    }
    return AacCardDef(
      id: card.id,
      category: card.category,
      kind: card.kind,
      label: label,
      sentenceTemplate: sentenceTemplate,
      animationAsset: card.animationAsset,
      audioAsset: audioAsset,
      fringeOptions: card.fringeOptions,
      customPhotoPath: card.customPhotoPath,
      difficultyTier: card.difficultyTier,
      isCustom: card.isCustom,
    );
  }

  Future<void> add(AacCardDef card) async {
    assert(card.isCustom, 'AacCustomCardStore only stores custom cards (isCustom=true)');
    final all = await getAll();
    await _save([...all, card]);
  }

  Future<void> update(AacCardDef card) async {
    final all = await getAll();
    await _save([for (final c in all) if (c.id == card.id) card else c]);
  }

  Future<void> remove(String cardId) async {
    final all = await getAll();
    await _save(all.where((c) => c.id != cardId).toList());
  }

  Future<void> _save(List<AacCardDef> cards) async {
    _cache = cards;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(cards.map((c) => c.toJson()).toList()));
  }

  /// Drops the in-memory cache so the next [getAll] re-reads
  /// SharedPreferences. Since this is a singleton, tests that swap the
  /// mocked SharedPreferences backing between cases need this for
  /// isolation — not meant for production use.
  @visibleForTesting
  void resetCacheForTesting() => _cache = null;
}
