library aac_event_repository;

import 'dart:async';
import 'dart:math';

import 'package:drift/drift.dart';

import '../../../core/network/api_client.dart';
import '../../../design_system/aac/aac_theme.dart';
import '../../../services/local_db/app_database.dart';
import '../domain/aac_card_def.dart';

/// Append-only local log of every "My Voice" card tap, backed by
/// [AppDatabase]'s `AacEvents` drift table.
///
/// Deliberately mirrors `TelemetryService`'s
/// (lib/services/telemetry/telemetry_service.dart) flush/retry/back-off
/// shape closely — same batch size, same flush interval, same exponential
/// back-off, same "4xx = drop, don't retry" rule — so the two systems
/// behave predictably alike for anyone maintaining both. They differ only
/// in how the pending queue is persisted: TelemetryService still uses the
/// SharedPreferences JSON-blob pattern (and documents that as a stub gap
/// for its own volume); AAC events use a real embedded database from day
/// one because tap volume is much higher than session-level telemetry (see
/// AppDatabase's doc comment for the full reasoning).
///
/// **Backend contract (not yet implemented — Phase 1 defines the shape,
/// implementation is a follow-up):** `POST /aac/events` with body
/// `{child_id, batch_id, events: [{card_id, category, sentence_spoken,
/// language, tapped_at}]}`, auth via child-session token (matching
/// TelemetryService's `/sessions/:id/events`). A batch_id lets the server
/// deduplicate retried batches.
class AacEventRepository {
  AacEventRepository._();
  static final AacEventRepository instance = AacEventRepository._();

  static const _maxBatch = 500;
  static const _flushInterval = Duration(seconds: 15);
  static const _maxRetries = 5;

  final ApiClient _api = ApiClient.instance;
  final AppDatabase _db = AppDatabase.instance;
  Timer? _flushTimer;
  bool _flushing = false;
  String? _childId;

  /// Call once per child session start.
  void init({required String childId}) {
    _childId = childId;
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(_flushInterval, (_) => flush());
  }

  /// Log one card tap. Never throws — a failed local write must never block
  /// the child's confirmation overlay or voice playback, which is why this
  /// swallows its own errors rather than letting the UI await/handle them.
  Future<void> logTap({
    required AacCardDef card,
    required AacCategory category,
    required String sentenceSpoken,
    required AacLanguage language,
  }) async {
    try {
      await _db.into(_db.aacEvents).insert(
            AacEventsCompanion.insert(
              cardId: card.id,
              category: category.name,
              sentenceSpoken: sentenceSpoken,
              language: language.code,
              tappedAt: DateTime.now(),
            ),
          );
    } catch (_) {
      return; // local write failed — nothing to flush-trigger on
    }

    final pending = await (_db.selectOnly(_db.aacEvents)
          ..addColumns([_db.aacEvents.id.count()])
          ..where(_db.aacEvents.synced.equals(false)))
        .map((row) => row.read(_db.aacEvents.id.count()) ?? 0)
        .getSingle();
    if (pending >= _maxBatch) unawaited(flush());
  }

  /// Flush pending events. Idempotent — no-op if already flushing, no
  /// active child session, or nothing pending.
  Future<void> flush() async {
    if (_flushing || _childId == null) return;
    _flushing = true;

    try {
      final query = _db.select(_db.aacEvents)
        ..where((t) => t.synced.equals(false))
        ..orderBy([(t) => OrderingTerm.asc(t.tappedAt)])
        ..limit(_maxBatch);
      final batch = await query.get();
      if (batch.isEmpty) return;

      final batchId = _uuidV4();
      final payload = batch
          .map((e) => {
                'card_id': e.cardId,
                'category': e.category,
                'sentence_spoken': e.sentenceSpoken,
                'language': e.language,
                'tapped_at': e.tappedAt.toIso8601String(),
              })
          .toList();

      bool sent = false;
      int delay = 2;
      for (int attempt = 0; attempt < _maxRetries && !sent; attempt++) {
        try {
          final resp = await _api.post(
            '/aac/events',
            auth: TokenKind.childSession,
            body: {'child_id': _childId, 'batch_id': batchId, 'events': payload},
          );
          if (resp.statusCode >= 200 && resp.statusCode < 300) {
            sent = true;
          } else if (resp.statusCode >= 400 && resp.statusCode < 500) {
            sent = true; // client error — don't retry, matches TelemetryService
          }
        } catch (_) {
          await Future.delayed(Duration(seconds: delay));
          delay = (delay * 2).clamp(2, 60);
        }
      }

      if (sent) {
        final ids = batch.map((e) => e.id).toList();
        await (_db.update(_db.aacEvents)..where((t) => t.id.isIn(ids)))
            .write(const AacEventsCompanion(synced: Value(true)));
      }
    } finally {
      _flushing = false;
    }
  }

  /// Best-effort cleanup of already-*synced* events older than [olderThan]
  /// — keeps the local table from growing forever. Unsynced rows are never
  /// touched here, so a prune can never silently lose an event that hasn't
  /// reached the backend yet.
  Future<void> pruneSynced({Duration olderThan = const Duration(days: 30)}) async {
    final cutoff = DateTime.now().subtract(olderThan);
    await (_db.delete(_db.aacEvents)
          ..where((t) => t.synced.equals(true) & t.tappedAt.isSmallerThanValue(cutoff)))
        .go();
  }

  String _uuidV4() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int start, int end) =>
        bytes.sublist(start, end).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  }

  Future<void> dispose() async {
    _flushTimer?.cancel();
    await flush();
    _childId = null;
  }
}
