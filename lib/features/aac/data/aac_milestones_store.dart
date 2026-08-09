library aac_milestones_store;

import 'package:shared_preferences/shared_preferences.dart';

/// One-shot "My Voice" milestone flags — Phase 5's calm celebration
/// requirement ("confetti only for milestones, e.g. first sentence").
/// Deliberately tiny: a single boolean today, following the same
/// SharedPreferences singleton pattern as `AacSettingsStore`/
/// `AacProgressionStore` rather than inventing a new storage mechanism for
/// one flag.
class AacMilestonesStore {
  AacMilestonesStore._();
  static final AacMilestonesStore instance = AacMilestonesStore._();

  static const _keyFirstSentence = 'aac_milestone_first_sentence_v1';

  bool? _cache;

  Future<bool> hasCelebratedFirstSentence() async {
    final cached = _cache;
    if (cached != null) return cached;
    final prefs = await SharedPreferences.getInstance();
    _cache = prefs.getBool(_keyFirstSentence) ?? false;
    return _cache!;
  }

  Future<void> markFirstSentenceCelebrated() async {
    _cache = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFirstSentence, true);
  }

  /// See `AacSettingsStore.resetCacheForTesting` — same rationale.
  void resetCacheForTesting() => _cache = null;
}
