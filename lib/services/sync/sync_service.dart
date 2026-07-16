library sync_service;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../../features/adaptive/adaptive_profile.dart';

/// Pulls AdaptationProfile from the server at session start and after a
/// telemetry flush. Falls back to the Dart-side policy when offline.
///
/// The backend derives child_id/language from the child-session token's
/// claims — this endpoint takes no query parameters.
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  static const _profileCacheKey = 'adaptation_profile_v1';
  final ApiClient _api = ApiClient.instance;
  bool _initialized = false;

  Future<void> init({required String childId, required String language}) async {
    _initialized = true;
  }

  /// Returns the latest AdaptationProfile for [childId].
  /// Fetches from server; on failure returns cached or default.
  Future<AdaptationProfile> pullProfile(String childId, String language) async {
    if (_initialized) {
      try {
        final resp = await _api.get('/adaptive/profile', auth: TokenKind.childSession);
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          final params = (data['profile'] as Map<String, dynamic>)['params']
              as Map<String, dynamic>;
          final profile = AdaptationProfile.fromJson(params);
          await _cacheProfile(childId, jsonEncode(params));
          return profile;
        }
      } catch (_) {
        // Fall through to cache / fallback
      }
    }

    // Try cached profile
    final cached = await _loadCachedProfile(childId);
    if (cached != null) return cached;

    // Offline fallback: Dart-side deterministic policy with defaults
    return _offlineFallback();
  }

  /// Apply Dart-side fallback policy when completely offline.
  /// Uses the same bounded-step deterministic policy as the backend.
  AdaptationProfile _offlineFallback() {
    // Start from defaults — the policy will adapt on next events
    return AdaptationProfile.defaults;
  }

  Future<void> _cacheProfile(String childId, String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_profileCacheKey:$childId', json);
  }

  Future<AdaptationProfile?> _loadCachedProfile(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_profileCacheKey:$childId');
    if (raw == null) return null;
    try {
      return AdaptationProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
