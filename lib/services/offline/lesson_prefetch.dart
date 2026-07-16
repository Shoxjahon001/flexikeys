library lesson_prefetch;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/curriculum/curriculum_models.dart';

/// Prefetches the next two lessons so the child can play fully offline.
///
/// Cached lessons are keyed by `prefetch:{childId}:{language}:{lessonId}`.
/// The prefetch runs after a session ends (when the device is likely online).
/// On lesson load, the controller falls back to the cache if offline.
///
/// Audio/image assets are NOT fetched here (would require large downloads);
/// the app uses graceful degradation (silence + placeholder images offline).
class LessonPrefetchService {
  LessonPrefetchService._();
  static final LessonPrefetchService instance = LessonPrefetchService._();

  static const _prefetchKeyPrefix = 'prefetch_lesson_v1';

  String? _endpointBase;
  String? _authToken;

  void init({required String endpointBase, required String authToken}) {
    _endpointBase = endpointBase;
    _authToken = authToken;
  }

  /// Prefetch the next 2 lesson plans for [childId] + [language].
  /// Called non-awaited at end of session; failures are silent.
  Future<void> prefetchNext({
    required String childId,
    required String language,
  }) async {
    if (_endpointBase == null) return;
    try {
      await _fetchAndCache(childId: childId, language: language, offset: 0);
      await _fetchAndCache(childId: childId, language: language, offset: 1);
    } catch (_) {
      // Offline — silently skip; cached plans stay valid
    }
  }

  /// Return a cached [NextLessonPlan] if available, null otherwise.
  Future<NextLessonPlan?> getCachedPlan({
    required String childId,
    required String language,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey(childId, language, 0));
    if (raw == null) return null;
    try {
      return NextLessonPlan.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  /// Advance the prefetch cache (call after a lesson is completed).
  /// Promotes offset-1 → offset-0 and tries to fetch a new offset-1.
  Future<void> advance({
    required String childId,
    required String language,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final next = prefs.getString(_cacheKey(childId, language, 1));
    if (next != null) {
      await prefs.setString(_cacheKey(childId, language, 0), next);
      await prefs.remove(_cacheKey(childId, language, 1));
    }
    // Fire-and-forget refill
    prefetchNext(childId: childId, language: language);
  }

  Future<void> _fetchAndCache({
    required String childId,
    required String language,
    required int offset,
  }) async {
    final url = Uri.parse(
      '$_endpointBase/curriculum/next?child_id=$childId&lang=$language&offset=$offset',
    );
    final resp = await http
        .get(url, headers: {
          'Authorization': 'Bearer ${_authToken ?? ''}',
          'Accept': 'application/json',
        })
        .timeout(const Duration(seconds: 8));

    if (resp.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey(childId, language, offset), resp.body);
    }
  }

  String _cacheKey(String childId, String language, int offset) =>
      '$_prefetchKeyPrefix:$childId:$language:$offset';

  /// Remove all prefetch cache entries for a child.
  Future<void> clearCache(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs
        .getKeys()
        .where((k) => k.startsWith('$_prefetchKeyPrefix:$childId:'));
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}