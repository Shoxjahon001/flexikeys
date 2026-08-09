library aac_progression_store;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/aac_progression.dart';

/// Persists the child's "My Voice" progression level — parent-set from the
/// AAC settings screen (docs/aac_design_system.md Phase 4). The model
/// (`AacProgressionState`) was defined in Phase 1 but never persisted until
/// now; follows the exact same SharedPreferences singleton pattern as
/// `AacSettingsStore` (low-volume, simple mutable state).
class AacProgressionStore {
  AacProgressionStore._();
  static final AacProgressionStore instance = AacProgressionStore._();

  static const _key = 'aac_progression_v1';

  AacProgressionState? _cache;

  Future<AacProgressionState> get() async {
    final cached = _cache;
    if (cached != null) return cached;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      _cache = AacProgressionState(updatedAt: DateTime.now());
      return _cache!;
    }
    _cache = AacProgressionState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    return _cache!;
  }

  /// Parent sets the level directly — always marks [AacProgressionState.manuallySet].
  Future<void> setLevel(AacLevel level) async {
    final current = await get();
    await _save(current.copyWith(
      level: level,
      manuallySet: true,
      updatedAt: DateTime.now(),
    ));
  }

  Future<void> _save(AacProgressionState state) async {
    _cache = state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }

  /// See `AacSettingsStore.resetCacheForTesting` — same rationale.
  void resetCacheForTesting() => _cache = null;
}
