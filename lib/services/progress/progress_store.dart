library progress_store;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// One level's local progress. `dirty` marks a change made on this device
/// that hasn't been confirmed synced to the backend yet.
class LevelProgressRecord {
  final String levelSlug;
  final bool completed;
  final int stars;
  final List<String> completedActivities;
  final DateTime updatedAt;
  final bool dirty;

  const LevelProgressRecord({
    required this.levelSlug,
    required this.completed,
    required this.stars,
    required this.completedActivities,
    required this.updatedAt,
    this.dirty = true,
  });

  LevelProgressRecord copyWith({
    bool? completed,
    int? stars,
    List<String>? completedActivities,
    DateTime? updatedAt,
    bool? dirty,
  }) =>
      LevelProgressRecord(
        levelSlug: levelSlug,
        completed: completed ?? this.completed,
        stars: stars ?? this.stars,
        completedActivities: completedActivities ?? this.completedActivities,
        updatedAt: updatedAt ?? this.updatedAt,
        dirty: dirty ?? this.dirty,
      );

  factory LevelProgressRecord.fromJson(Map<String, dynamic> json) => LevelProgressRecord(
        levelSlug: json['level_slug'] as String,
        completed: json['completed'] as bool,
        stars: json['stars'] as int,
        completedActivities:
            (json['completed_activities'] as List<dynamic>).cast<String>(),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        dirty: json['dirty'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'level_slug': levelSlug,
        'completed': completed,
        'stars': stars,
        'completed_activities': completedActivities,
        'updated_at': updatedAt.toUtc().toIso8601String(),
        'dirty': dirty,
      };

  /// Wire shape for `PUT /progress/sync` — no local-only `dirty` flag.
  Map<String, dynamic> toApiJson() => {
        'level_slug': levelSlug,
        'completed': completed,
        'stars': stars,
        'completed_activities': completedActivities,
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };
}

/// Local, offline-first per-level progress store — the source of truth for
/// gameplay (locked/unlocked, stars, completed activities) regardless of
/// connectivity or whether the child has an account.
///
/// Backed by SharedPreferences as a single JSON blob, matching the pattern
/// already used by `TelemetryService`'s event queue and `SyncService`'s
/// adaptation-profile cache — no new local-storage dependency introduced.
class ProgressStore {
  ProgressStore._();
  static final ProgressStore instance = ProgressStore._();

  static const _key = 'game_progress_v1';

  Future<Map<String, LevelProgressRecord>> _readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (k, v) => MapEntry(k, LevelProgressRecord.fromJson(v as Map<String, dynamic>)),
    );
  }

  Future<void> _writeAll(Map<String, LevelProgressRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = records.map((k, v) => MapEntry(k, v.toJson()));
    await prefs.setString(_key, jsonEncode(encoded));
  }

  Future<List<LevelProgressRecord>> all() async => (await _readAll()).values.toList();

  Future<LevelProgressRecord?> get(String levelSlug) async => (await _readAll())[levelSlug];

  /// Record a level completion locally. Marks the record dirty so it is
  /// picked up by the next sync. Stars are kept at the child's best result;
  /// completed activities accumulate.
  Future<void> recordLevelComplete(
    String levelSlug, {
    required int stars,
    List<String> completedActivities = const [],
  }) async {
    final all = await _readAll();
    final existing = all[levelSlug];
    final mergedActivities = <String>{
      ...?existing?.completedActivities,
      ...completedActivities,
    }.toList();
    all[levelSlug] = LevelProgressRecord(
      levelSlug: levelSlug,
      completed: true,
      stars: stars > (existing?.stars ?? 0) ? stars : (existing?.stars ?? 0),
      completedActivities: mergedActivities,
      updatedAt: DateTime.now().toUtc(),
      dirty: true,
    );
    await _writeAll(all);
  }

  /// Merge rows pulled from (or acknowledged by) the server. A server row
  /// only overwrites the local one if it is at least as new — an in-flight
  /// local change is never clobbered by a pull. Clears `dirty` once local
  /// and server agree.
  Future<void> mergeFromServer(List<LevelProgressRecord> serverRecords) async {
    final all = await _readAll();
    for (final server in serverRecords) {
      final local = all[server.levelSlug];
      if (local == null || !local.updatedAt.isAfter(server.updatedAt)) {
        all[server.levelSlug] = server.copyWith(dirty: false);
      }
    }
    await _writeAll(all);
  }

  Future<List<LevelProgressRecord>> dirtyRecords() async =>
      (await _readAll()).values.where((r) => r.dirty).toList();
}