library telemetry_service;

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';

/// Append-only telemetry event queue backed by SharedPreferences.
///
/// Events are batched (max 500 or 15 s) and flushed to the backend with
/// exponential back-off. Each batch carries a stable `batch_id` (a UUID, in
/// the JSON body) so the server can deduplicate retries.
///
/// STUB #5: Replace SharedPreferences backing with Drift table
///   (append-only `telemetry_events` table) for true durability.
///   See issue #telemetry-drift-backing.
///
/// COPPA: events contain only pseudonymous child_id (UUID), never PII.
class TelemetryService {
  TelemetryService._();
  static final TelemetryService instance = TelemetryService._();

  static const _queueKey = 'telemetry_queue_v1';
  static const _maxBatch = 500;
  static const _flushInterval = Duration(seconds: 15);
  static const _maxRetries = 5;

  final ApiClient _api = ApiClient.instance;
  Timer? _flushTimer;
  bool _flushing = false;
  String? _sessionId;

  /// Call once per child session start. Opens a real backend session via
  /// `POST /sessions` and starts the periodic flush timer.
  Future<void> init({required String childId, required String language}) async {
    _flushTimer?.cancel();
    _sessionId = null;
    try {
      final resp = await _api.post(
        '/sessions',
        auth: TokenKind.childSession,
        body: {'child_id': childId, 'language': language},
      );
      if (resp.statusCode == 201) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        _sessionId = data['id'] as String;
      }
    } catch (_) {
      // Offline at session start — events queue locally until a session
      // is available on a later init() call.
    }
    _flushTimer = Timer.periodic(_flushInterval, (_) => _flush());
  }

  /// Enqueue a single telemetry event map.
  Future<void> enqueue(Map<String, dynamic> event) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_queueKey);
    final List<dynamic> queue = raw != null ? jsonDecode(raw) as List<dynamic> : [];
    queue.add(event);
    await prefs.setString(_queueKey, jsonEncode(queue));

    if (queue.length >= _maxBatch) {
      unawaited(_flush());
    }
  }

  /// Flush pending events. Idempotent — noop if already flushing or no events.
  Future<void> flush() => _flush();

  Future<void> _flush() async {
    if (_flushing || _sessionId == null) return;
    _flushing = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_queueKey);
      if (raw == null || raw == '[]') return;

      final List<dynamic> queue = jsonDecode(raw) as List<dynamic>;
      if (queue.isEmpty) return;

      final batch = queue.take(_maxBatch).toList();
      final batchId = _uuidV4();

      bool sent = false;
      int delay = 2;
      for (int attempt = 0; attempt < _maxRetries && !sent; attempt++) {
        try {
          final resp = await _api.post(
            '/sessions/$_sessionId/events',
            auth: TokenKind.childSession,
            body: {'batch_id': batchId, 'events': batch},
          );
          if (resp.statusCode >= 200 && resp.statusCode < 300) {
            sent = true;
          } else if (resp.statusCode >= 400 && resp.statusCode < 500) {
            // Client error — don't retry
            sent = true;
          }
        } catch (_) {
          // Network error — retry with back-off
          await Future.delayed(Duration(seconds: delay));
          delay = (delay * 2).clamp(2, 60);
        }
      }

      if (sent) {
        // Remove flushed events from queue
        final remaining = queue.skip(batch.length).toList();
        await prefs.setString(_queueKey, jsonEncode(remaining));
      }
    } finally {
      _flushing = false;
    }
  }

  String _uuidV4() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int start, int end) => bytes
        .sublist(start, end)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  }

  Future<void> dispose() async {
    _flushTimer?.cancel();
    await _flush();
    _sessionId = null;
  }
}
