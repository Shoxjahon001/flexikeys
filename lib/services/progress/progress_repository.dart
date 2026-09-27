library progress_repository;

import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/network/secure_token_store.dart';
import '../user_service.dart';
import 'progress_store.dart';

/// Reconciles the local [ProgressStore] (always the source of truth for
/// gameplay) with Supabase's `child_task_progress` table.
///
/// Network failures are swallowed everywhere here — the app must stay fully
/// playable offline, and a sync failure must never surface to the child.
/// Call [sync] fire-and-forget (`unawaited`) from gameplay code; it is safe
/// to call repeatedly and no-ops while offline, guest, or already syncing.
class ProgressRepository {
  ProgressRepository._();
  static final ProgressRepository instance = ProgressRepository._();

  final sb.SupabaseClient _client = sb.Supabase.instance.client;
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
    final childId = await _tokens.getActiveChildId();
    if (childId == null) return;

    _syncing = true;
    try {
      final dirty = await _store.dirtyRecords();
      if (dirty.isNotEmpty) {
        await _push(childId, dirty);
      }
      await _pull(childId);
    } catch (_) {
      // Offline or Supabase unreachable — local state is untouched and will
      // be retried on the next sync trigger.
    } finally {
      _syncing = false;
    }
  }

  Future<void> _push(String childId, List<LevelProgressRecord> dirty) async {
    final rows = dirty
        .map((r) => {
              'child_id': childId,
              'task_slug': r.levelSlug,
              'completed': r.completed,
              'stars': r.stars,
              'completed_activities': r.completedActivities,
              'completed_at': r.completed ? r.updatedAt.toUtc().toIso8601String() : null,
              'updated_at': r.updatedAt.toUtc().toIso8601String(),
            })
        .toList();
    await _client.from('child_task_progress').upsert(rows, onConflict: 'child_id,task_slug');
  }

  Future<void> _pull(String childId) async {
    final rows = await _client.from('child_task_progress').select().eq('child_id', childId);
    final records = (rows as List<dynamic>).cast<Map<String, dynamic>>().map((row) {
      return LevelProgressRecord(
        levelSlug: row['task_slug'] as String,
        completed: row['completed'] as bool,
        stars: row['stars'] as int,
        completedActivities: (row['completed_activities'] as List<dynamic>).cast<String>(),
        updatedAt: DateTime.parse(row['updated_at'] as String),
        dirty: false,
      );
    }).toList();
    await _store.mergeFromServer(records);
    // Mirror completed levels into UserService's flag-list too, so
    // LevelsScreen (which reads UserService.getCompletedLevels(), not
    // ProgressStore) reflects progress pulled from another device / after
    // re-login without needing its own Supabase wiring.
    for (final r in records.where((r) => r.completed)) {
      await UserService.completeLevel(r.levelSlug);
    }
  }
}
