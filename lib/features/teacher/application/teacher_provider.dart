library teacher_provider;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/teacher_models.dart';

final _api = ApiClient.instance;

// ── Providers ─────────────────────────────────────────────────────────────────

final classListProvider = FutureProvider.autoDispose<List<ClassItem>>((ref) async {
  final resp = await _api.get('/teacher/classes');
  if (resp.statusCode != 200) throw Exception('Failed to load classes');
  final data = jsonDecode(resp.body) as List<dynamic>;
  return data.map((e) => ClassItem.fromJson(e as Map<String, dynamic>)).toList();
});

final classAnalyticsProvider =
    FutureProvider.autoDispose.family<ClassAnalytics, String>((ref, classId) async {
  final resp = await _api.get('/teacher/classes/$classId/analytics');
  if (resp.statusCode != 200) throw Exception('Failed to load class analytics');
  return ClassAnalytics.fromJson(
    jsonDecode(resp.body) as Map<String, dynamic>,
  );
});

final assignmentsProvider =
    FutureProvider.autoDispose.family<List<Assignment>, String>((ref, classId) async {
  final resp = await _api.get('/teacher/classes/$classId/assignments');
  if (resp.statusCode != 200) throw Exception('Failed to load assignments');
  final data = jsonDecode(resp.body) as List<dynamic>;
  return data.map((e) => Assignment.fromJson(e as Map<String, dynamic>)).toList();
});

// ── Assignment composer state ─────────────────────────────────────────────────

class AssignmentDraft {
  final String? levelId;
  final String? lessonId;
  final DateTime? dueAt;
  final String? instructions;
  final bool submitting;
  final String? errorMessage;

  const AssignmentDraft({
    this.levelId,
    this.lessonId,
    this.dueAt,
    this.instructions,
    this.submitting = false,
    this.errorMessage,
  });

  AssignmentDraft copyWith({
    String? levelId,
    String? lessonId,
    DateTime? dueAt,
    String? instructions,
    bool? submitting,
    String? errorMessage,
  }) =>
      AssignmentDraft(
        levelId: levelId ?? this.levelId,
        lessonId: lessonId ?? this.lessonId,
        dueAt: dueAt ?? this.dueAt,
        instructions: instructions ?? this.instructions,
        submitting: submitting ?? this.submitting,
        errorMessage: errorMessage,
      );
}

class AssignmentNotifier extends StateNotifier<AssignmentDraft> {
  AssignmentNotifier() : super(const AssignmentDraft());

  void setInstructions(String v) => state = state.copyWith(instructions: v);
  void setDueAt(DateTime? v) => state = state.copyWith(dueAt: v);

  Future<Assignment?> submit(String classId) async {
    state = state.copyWith(submitting: true, errorMessage: null);
    try {
      final resp = await _api.post(
        '/teacher/classes/$classId/assignments',
        body: {
          if (state.levelId != null) 'level_id': state.levelId,
          if (state.lessonId != null) 'lesson_id': state.lessonId,
          if (state.dueAt != null) 'due_at': state.dueAt!.toIso8601String(),
          if (state.instructions != null && state.instructions!.isNotEmpty)
            'instructions': state.instructions,
        },
      );
      if (resp.statusCode == 201) {
        state = const AssignmentDraft();
        return Assignment.fromJson(
          jsonDecode(resp.body) as Map<String, dynamic>,
        );
      }
      state = state.copyWith(
        submitting: false,
        errorMessage: 'Failed to create assignment.',
      );
      return null;
    } catch (_) {
      state = state.copyWith(
        submitting: false,
        errorMessage: 'Network error. Please try again.',
      );
      return null;
    }
  }

  void reset() => state = const AssignmentDraft();
}

final assignmentComposerProvider =
    StateNotifierProvider.autoDispose<AssignmentNotifier, AssignmentDraft>(
  (_) => AssignmentNotifier(),
);