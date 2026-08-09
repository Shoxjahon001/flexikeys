library aac_card_repository;

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../../design_system/aac/aac_theme.dart';
import '../domain/aac_card_def.dart';
import 'aac_custom_card_store.dart';

/// Loads the bundled starter AAC vocabulary and merges it with any
/// parent-created custom cards.
///
/// Unlike curriculum content (which flows entirely through the backend —
/// `shared/curriculum/*.json` -> `import_curriculum.py` -> Postgres ->
/// `GET /curriculum/next` -> Flutter over HTTP, with zero local-asset
/// loading anywhere in this app), AAC vocabulary is bundled directly as a
/// Flutter asset (`shared/aac/*.json`, declared in pubspec.yaml) and loaded
/// via `rootBundle` — a deliberate departure from the curriculum precedent.
/// AAC vocabulary is the child's only voice; it must be available the
/// instant the app opens, with or without a network, which the original
/// spec states as a hard requirement ("Everything works offline; sync is a
/// bonus, never a requirement") — not just a nice-to-have like prefetched
/// lesson content.
class AacCardRepository {
  AacCardRepository._();
  static final AacCardRepository instance = AacCardRepository._();

  static const _categoryFiles = [
    'shared/aac/category_daily_activities.json',
    'shared/aac/category_needs.json',
    'shared/aac/category_feelings.json',
    'shared/aac/category_people.json',
    'shared/aac/category_places.json',
    'shared/aac/category_play.json',
  ];

  List<AacCardDef>? _starterCache;

  /// All starter (non-custom) vocabulary cards. Loaded once and cached for
  /// the process lifetime — the bundled JSON never changes at runtime.
  Future<List<AacCardDef>> loadStarterVocabulary() async {
    final cached = _starterCache;
    if (cached != null) return cached;

    final cards = <AacCardDef>[];
    for (final path in _categoryFiles) {
      final raw = await rootBundle.loadString(path);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      // "category" is declared once per file (see shared/aac/*.json), not
      // repeated on every card object — inject it into each card's JSON
      // before parsing so AacCardDef.fromJson sees a consistent shape.
      final category = decoded['category'] as String;
      final cardList = decoded['cards'] as List<dynamic>;
      cards.addAll(cardList.map((c) => AacCardDef.fromJson({
            ...c as Map<String, dynamic>,
            'category': category,
          })));
    }
    _starterCache = List.unmodifiable(cards);
    return _starterCache!;
  }

  /// Starter vocabulary + parent-created custom cards, combined.
  Future<List<AacCardDef>> loadAllCards() async {
    final starter = await loadStarterVocabulary();
    final custom = await AacCustomCardStore.instance.getAll();
    return [...starter, ...custom];
  }

  Future<List<AacCardDef>> loadCategory(AacCategory category) async {
    final all = await loadAllCards();
    return all.where((c) => c.category == category).toList();
  }

  /// Cards unlocked at [maxTier] (inclusive) — see `AacLevel.cardCeiling`
  /// in aac_progression.dart for how a level maps to a tier ceiling. Custom
  /// cards are always included regardless of tier: a parent adding one is
  /// itself a deliberate, explicit unlock.
  Future<List<AacCardDef>> loadUnlocked({required int maxTier}) async {
    final all = await loadAllCards();
    return all.where((c) => c.isCustom || c.difficultyTier <= maxTier).toList();
  }
}
