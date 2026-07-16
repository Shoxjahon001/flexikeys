library parent_provider;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/parent_models.dart';

final _api = ApiClient.instance;

// ── Summary provider ──────────────────────────────────────────────────────────

final childSummaryProvider =
    FutureProvider.family<ChildSummary, String>((ref, childId) async {
  final resp = await _api.get('/parent/children/$childId/summary');
  if (resp.statusCode != 200) throw Exception('summary_error');
  return ChildSummary.fromJson(
    json.decode(resp.body) as Map<String, dynamic>,
  );
});

// ── Skills provider ───────────────────────────────────────────────────────────

typedef SkillsQuery = ({String childId, String language});

final skillsProvider =
    FutureProvider.family<List<SkillEntry>, SkillsQuery>((ref, q) async {
  final resp = await _api.get('/progress/skills?child_id=${q.childId}&language=${q.language}');
  if (resp.statusCode != 200) throw Exception('skills_error');
  final list = json.decode(resp.body) as List<dynamic>;
  return list
      .cast<Map<String, dynamic>>()
      .map(SkillEntry.fromJson)
      .toList();
});

// ── Timeseries provider ───────────────────────────────────────────────────────

typedef TimeseriesQuery = ({String childId, String metric, int rangeDays});

final timeseriesProvider =
    FutureProvider.family<List<TimeseriesPoint>, TimeseriesQuery>((ref, q) async {
  final resp = await _api.get(
    '/progress/timeseries'
    '?child_id=${q.childId}&metric=${q.metric}&range_days=${q.rangeDays}',
  );
  if (resp.statusCode != 200) throw Exception('timeseries_error');
  final list = json.decode(resp.body) as List<dynamic>;
  return list
      .cast<Map<String, dynamic>>()
      .map(TimeseriesPoint.fromJson)
      .toList();
});

// ── Adaptation feed provider ──────────────────────────────────────────────────

typedef AdaptationsQuery = ({String childId, String uiLanguage});

final adaptationsProvider =
    FutureProvider.family<List<AdaptationFeedItem>, AdaptationsQuery>((ref, q) async {
  final resp = await _api.get(
    '/progress/adaptations'
    '?child_id=${q.childId}&ui_language=${q.uiLanguage}&limit=20',
  );
  if (resp.statusCode != 200) throw Exception('adaptations_error');
  final list = json.decode(resp.body) as List<dynamic>;
  return list
      .cast<Map<String, dynamic>>()
      .map(AdaptationFeedItem.fromJson)
      .toList();
});

// ── AI Assistant provider ─────────────────────────────────────────────────────

class AssistantNotifier extends StateNotifier<AssistantState> {
  AssistantNotifier() : super(const AssistantState());

  Future<void> sendMessage({
    required String childId,
    required String message,
    required String uiLanguage,
  }) async {
    // Optimistically add user message
    final userMsg = ChatMessage(
      id: 'tmp-${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      content: message,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      loading: true,
    );

    try {
      final resp = await _api.post(
        '/ai-assistant/chat',
        body: {
          'child_id': childId,
          'message': message,
          'conversation_id': state.conversationId,
          'ui_language': uiLanguage,
        },
      );

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final convId = data['conversation_id'] as String;
        final msgData = data['message'] as Map<String, dynamic>;
        final assistantMsg = ChatMessage.fromJson(msgData);
        state = state.copyWith(
          messages: [...state.messages, assistantMsg],
          loading: false,
          conversationId: convId,
        );
      } else {
        state = state.copyWith(loading: false);
      }
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  void reset() => state = const AssistantState();
}

final assistantProvider =
    StateNotifierProvider<AssistantNotifier, AssistantState>(
  (_) => AssistantNotifier(),
);