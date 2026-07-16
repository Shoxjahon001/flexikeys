library progress_repository;

import 'dart:async';
import 'dart:convert';

import '../../core/network/api_client.dart';
import '../../core/network/secure_token_store.dart';
import 'progress_store.dart';

/// Reconciles the local [ProgressStore] (always the source of truth for
/// gameplay) with the backend's `GET`/`PUT /progress/sync`.
///
/// Network failures are swallowed everywhere here — the app must stay fully
/// playable offline, and a sync failure must never surface to the child.
/// Call [sync] fire-and-forget (`unawaited`) from gameplay code; it is safe
/// to call repeatedly and no-ops while offline, guest, or already syncing.
class ProgressRepository {
  ProgressRepository._();
  static final ProgressRepository instance = ProgressRepository._();

  final ApiClient _api = ApiClient.instance;
  final ProgressStore _store = ProgressStore.instance;
  final SecureTokenStore _tokens = SecureTokenStore.instance;

  bool _syncing = false;

  /// Record a level completion locally (source of truth, works offline) and
  /// kick off a fire-and-forget sync. Call this from game-completion
  /// handlers instead of touching [ProgressStore] and [sync] separately.
  void recordLevelCompleteAndSync(
    String levelSlug, {
    required int stars,
    List<String> completedActivities = const [],
  }) {
    unawaited(() async {
      await _store.recordLevelComplete(
        levelSlug,
        stars: stars,
        completedActivities: completedActivities,
      );
      await sync();
    }());
  }

  Future<void> sync() async {
    if (_syncing) return;
    // No child session yet (guest mode, or parent hasn't picked a child) —
    // nothing to sync against. Local progress stays authoritative.
    if (await _tokens.getActiveChildId() == null) return;

    _syncing = true;
    try {
      final dirty = await _store.dirtyRecords();
      if (dirty.isEmpty) {
        await _pull();
        return;
      }
      final resp = await _api.put(
        '/progress/sync',
        auth: TokenKind.childSession,
        body: dirty.map((r) => r.toApiJson()).toList(),
      );
      if (resp.statusCode != 200) return;
      await _applyServerState(resp.body);
    } catch (_) {
      // Offline or backend unreachable — local state is untouched and will
      // be retried on the next sync trigger.
    } finally {
      _syncing = false;
    }
  }

  Future<void> _pull() async {
    try {
      final resp = await _api.get('/progress/sync', auth: TokenKind.childSession);
      if (resp.statusCode != 200) return;
      await _applyServerState(resp.body);
    } catch (_) {
      // Offline — keep local state as-is.
    }
  }

  Future<void> _applyServerState(String body) async {
    final list = jsonDecode(body) as List<dynamic>;
    final records =
        list.cast<Map<String, dynamic>>().map(LevelProgressRecord.fromJson).toList();
    await _store.mergeFromServer(records);
  }
}