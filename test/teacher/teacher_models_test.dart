import 'package:flutter_test/flutter_test.dart';

import 'package:flexikeys/features/teacher/domain/teacher_models.dart';

void main() {
  group('ClassItem.fromJson', () {
    test('parses all fields', () {
      final item = ClassItem.fromJson({
        'id': 'cls-1',
        'name': 'Bluebirds',
        'join_code': 'ABC123',
        'student_count': 8,
        'created_at': '2026-07-01T10:00:00Z',
      });
      expect(item.id, 'cls-1');
      expect(item.name, 'Bluebirds');
      expect(item.joinCode, 'ABC123');
      expect(item.studentCount, 8);
      expect(item.createdAt.year, 2026);
    });

    test('parses student_count from int', () {
      final item = ClassItem.fromJson({
        'id': 'cls-2',
        'name': 'Room A',
        'join_code': 'XYZ000',
        'student_count': 0,
        'created_at': '2026-07-01T10:00:00Z',
      });
      expect(item.studentCount, 0);
    });
  });

  group('StudentSummary.fromJson', () {
    test('parses all fields', () {
      final s = StudentSummary.fromJson({
        'child_id': 'child-1',
        'display_name': 'Alex',
        'mastery_score': 0.75,
        'last_active': '2026-07-10T12:00:00Z',
        'needs_attention': false,
        'skills_needing_practice': [],
      });
      expect(s.childId, 'child-1');
      expect(s.displayName, 'Alex');
      expect(s.masteryScore, closeTo(0.75, 0.001));
      expect(s.needsAttention, isFalse);
      expect(s.lastActive, isNotNull);
    });

    test('handles null last_active', () {
      final s = StudentSummary.fromJson({
        'child_id': 'child-2',
        'display_name': 'Sam',
        'mastery_score': 0.3,
        'last_active': null,
        'needs_attention': true,
        'skills_needing_practice': ['Letter Z'],
      });
      expect(s.lastActive, isNull);
      expect(s.needsAttention, isTrue);
      expect(s.skillsNeedingPractice, contains('Letter Z'));
    });

    test('masteryLabel returns correct label for mastered', () {
      const s = StudentSummary(
        childId: 'c1',
        displayName: 'Jo',
        masteryScore: 0.85,
        needsAttention: false,
      );
      expect(s.masteryLabel, 'On track');
    });

    test('masteryLabel returns correct label for practising', () {
      const s = StudentSummary(
        childId: 'c2',
        displayName: 'Kim',
        masteryScore: 0.55,
        needsAttention: false,
      );
      expect(s.masteryLabel, 'Practising');
    });

    test('masteryLabel returns correct label for getting started', () {
      const s = StudentSummary(
        childId: 'c3',
        displayName: 'Lee',
        masteryScore: 0.2,
        needsAttention: true,
      );
      expect(s.masteryLabel, 'Getting started');
    });
  });

  group('ClassAnalytics.fromJson', () {
    test('parses analytics with students', () {
      final a = ClassAnalytics.fromJson({
        'class_id': 'cls-1',
        'class_name': 'Bluebirds',
        'student_count': 2,
        'avg_mastery': 0.6,
        'needs_attention_count': 1,
        'student_summaries': [
          {
            'child_id': 'c1',
            'display_name': 'Alex',
            'mastery_score': 0.8,
            'last_active': null,
            'needs_attention': false,
            'skills_needing_practice': [],
          },
          {
            'child_id': 'c2',
            'display_name': 'Sam',
            'mastery_score': 0.4,
            'last_active': null,
            'needs_attention': true,
            'skills_needing_practice': ['Letter Z'],
          },
        ],
      });
      expect(a.classId, 'cls-1');
      expect(a.studentCount, 2);
      expect(a.avgMastery, closeTo(0.6, 0.001));
      expect(a.needsAttentionCount, 1);
      expect(a.studentSummaries, hasLength(2));
    });

    test('parses empty student list', () {
      final a = ClassAnalytics.fromJson({
        'class_id': 'cls-2',
        'class_name': 'Empty',
        'student_count': 0,
        'avg_mastery': 0.0,
        'needs_attention_count': 0,
        'student_summaries': [],
      });
      expect(a.studentSummaries, isEmpty);
    });
  });

  group('Assignment.fromJson', () {
    test('parses all fields', () {
      final a = Assignment.fromJson({
        'id': 'asgn-1',
        'class_id': 'cls-1',
        'level_id': null,
        'lesson_id': null,
        'due_at': '2026-07-20T00:00:00Z',
        'instructions': 'Practice letters A-E',
        'created_at': '2026-07-10T12:00:00Z',
      });
      expect(a.id, 'asgn-1');
      expect(a.instructions, 'Practice letters A-E');
      expect(a.dueAt, isNotNull);
      expect(a.dueAt!.year, 2026);
    });

    test('handles null optional fields', () {
      final a = Assignment.fromJson({
        'id': 'asgn-2',
        'class_id': 'cls-1',
        'level_id': null,
        'lesson_id': null,
        'due_at': null,
        'instructions': null,
        'created_at': '2026-07-10T12:00:00Z',
      });
      expect(a.dueAt, isNull);
      expect(a.instructions, isNull);
    });
  });

  group('StudentSummary no PII', () {
    test('fromJson does not expose email or parent data', () {
      // Even if the backend accidentally returns extra fields, the model
      // does not parse or expose them. Verify the model class has no such fields.
      const s = StudentSummary(
        childId: 'c1',
        displayName: 'Alex',
        masteryScore: 0.7,
        needsAttention: false,
      );
      // These fields must not exist on the model
      expect(() => (s as dynamic).email, throwsNoSuchMethodError);
      expect(() => (s as dynamic).parentEmail, throwsNoSuchMethodError);
      expect(() => (s as dynamic).parentId, throwsNoSuchMethodError);
    });
  });
}