import 'package:flutter_test/flutter_test.dart';

import 'package:flexikeys/features/parent/domain/parent_models.dart';

void main() {
  group('ChildSummary.fromJson', () {
    test('parses all fields correctly', () {
      final s = ChildSummary.fromJson({
        'child_id': 'abc-123',
        'display_name': 'Alex',
        'today_minutes': 12.5,
        'today_items': 8,
        'streak_days': 3,
        'learning_language': 'en',
        'ui_language': 'en',
      });

      expect(s.childId, 'abc-123');
      expect(s.displayName, 'Alex');
      expect(s.todayMinutes, 12.5);
      expect(s.todayItems, 8);
      expect(s.streakDays, 3);
    });

    test('parses today_minutes from int', () {
      final s = ChildSummary.fromJson({
        'child_id': 'x',
        'display_name': 'Sam',
        'today_minutes': 10,
        'today_items': 5,
        'streak_days': 1,
        'learning_language': 'uz',
        'ui_language': 'uz',
      });
      expect(s.todayMinutes, 10.0);
    });
  });

  group('SkillEntry', () {
    test('isMastered is true when p_known >= 0.8', () {
      const s = SkillEntry(
        skillKey: 'en:letter:a',
        label: 'Letter A',
        pKnown: 0.85,
        attempts: 20,
        correct: 17,
      );
      expect(s.isMastered, isTrue);
      expect(s.isPracticing, isFalse);
      expect(s.isStarting, isFalse);
    });

    test('isPracticing when 0.4 <= p_known < 0.8', () {
      const s = SkillEntry(
        skillKey: 'en:letter:b',
        label: 'Letter B',
        pKnown: 0.55,
        attempts: 10,
        correct: 6,
      );
      expect(s.isMastered, isFalse);
      expect(s.isPracticing, isTrue);
      expect(s.isStarting, isFalse);
    });

    test('isStarting when p_known < 0.4', () {
      const s = SkillEntry(
        skillKey: 'en:letter:c',
        label: 'Letter C',
        pKnown: 0.2,
        attempts: 3,
        correct: 1,
      );
      expect(s.isStarting, isTrue);
      expect(s.isPracticing, isFalse);
    });

    test('fromJson parses correctly', () {
      final s = SkillEntry.fromJson({
        'skill_key': 'uz:letter:a',
        'label': 'Letter A',
        'p_known': 0.72,
        'attempts': 15,
        'correct': 11,
      });
      expect(s.skillKey, 'uz:letter:a');
      expect(s.pKnown, closeTo(0.72, 0.001));
    });
  });

  group('TimeseriesPoint', () {
    test('fromJson parses value and date', () {
      final p = TimeseriesPoint.fromJson({
        'date': '2026-07-01',
        'value': 0.84,
      });
      expect(p.value, closeTo(0.84, 0.001));
      expect(p.date.year, 2026);
      expect(p.date.month, 7);
    });

    test('fromJson handles null value', () {
      final p = TimeseriesPoint.fromJson({'date': '2026-07-01', 'value': null});
      expect(p.value, isNull);
    });
  });

  group('AdaptationFeedItem', () {
    test('fromJson parses sentence and null old_value', () {
      final item = AdaptationFeedItem.fromJson({
        'id': 'id-1',
        'changed_at': '2026-07-10T12:00:00Z',
        'param': 'key_scale',
        'old_value': null,
        'new_value': '1.2',
        'reason_code': 'accuracy_drop',
        'sentence': 'Keys were made a bit larger to be easier to tap.',
      });

      expect(item.sentence, contains('larger'));
      expect(item.oldValue, isNull);
      expect(item.newValue, '1.2');
      expect(item.reasonCode, 'accuracy_drop');
    });
  });

  group('ChatMessage', () {
    test('isUser is true for role=user', () {
      final m = ChatMessage.fromJson({
        'id': 'm1',
        'role': 'user',
        'content': 'Hello',
        'created_at': '2026-07-10T12:00:00Z',
      });
      expect(m.isUser, isTrue);
      expect(m.isAssistant, isFalse);
    });

    test('isAssistant is true for role=assistant', () {
      final m = ChatMessage.fromJson({
        'id': 'm2',
        'role': 'assistant',
        'content': 'Great progress!',
        'created_at': '2026-07-10T12:01:00Z',
      });
      expect(m.isAssistant, isTrue);
      expect(m.isUser, isFalse);
    });
  });

  group('AssistantState', () {
    test('copyWith updates loading flag', () {
      const s = AssistantState();
      final next = s.copyWith(loading: true);
      expect(next.loading, isTrue);
      expect(next.messages, isEmpty);
    });

    test('copyWith preserves existing messages', () {
      final msg = ChatMessage(
        id: '1',
        role: 'user',
        content: 'Hi',
        createdAt: DateTime.now(),
      );
      final s = AssistantState(messages: [msg]);
      final next = s.copyWith(loading: true);
      expect(next.messages, hasLength(1));
      expect(next.loading, isTrue);
    });
  });
}