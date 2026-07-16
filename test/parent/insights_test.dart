import 'package:flutter_test/flutter_test.dart';

import 'package:flexikeys/features/parent/application/insights.dart';
import 'package:flexikeys/features/parent/domain/parent_models.dart';

ChildSummary _summary({int streakDays = 0, int todayItems = 1}) => ChildSummary(
      childId: 'c1',
      displayName: 'Emma',
      todayMinutes: 5,
      todayItems: todayItems,
      streakDays: streakDays,
      learningLanguage: 'en',
      uiLanguage: 'en',
    );

List<TimeseriesPoint> _points(List<double?> values) => [
      for (int i = 0; i < values.length; i++)
        TimeseriesPoint(date: DateTime(2026, 1, 1 + i), value: values[i]),
    ];

void main() {
  group('weekOverWeekAccuracyDelta', () {
    test('returns null with fewer than 8 non-null values', () {
      final points = _points([0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5]);
      expect(weekOverWeekAccuracyDelta(points), isNull);
    });

    test('computes positive delta when recent week is higher', () {
      // prior 7 mean 0.5, recent 7 mean 0.6 -> +20%
      final points = _points([
        0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, // prior week
        0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, // recent week
      ]);
      final delta = weekOverWeekAccuracyDelta(points);
      expect(delta, isNotNull);
      expect(delta!, closeTo(0.2, 0.001));
    });

    test('computes negative delta when recent week is lower', () {
      final points = _points([
        0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8,
        0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4,
      ]);
      final delta = weekOverWeekAccuracyDelta(points);
      expect(delta, isNotNull);
      expect(delta!, closeTo(-0.5, 0.001));
    });

    test('ignores null-valued days when gathering values', () {
      final points = _points([
        0.5, null, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5,
        0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6,
      ]);
      final delta = weekOverWeekAccuracyDelta(points);
      expect(delta, isNotNull);
    });

    test('returns null for an empty list', () {
      expect(weekOverWeekAccuracyDelta([]), isNull);
    });
  });

  group('buildInsights', () {
    test('emits no accuracy insight without enough timeseries data', () {
      final insights = buildInsights(
        summary: _summary(),
        accuracyPoints: _points([0.5, 0.5, 0.5]),
      );
      expect(insights.any((i) => i.headline.contains('Accuracy')), isFalse);
    });

    test('emits a positive accuracy insight on real improvement', () {
      final points = _points([
        0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5,
        0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7,
      ]);
      final insights = buildInsights(summary: _summary(), accuracyPoints: points);
      final accuracyInsight = insights.firstWhere((i) => i.headline.contains('up'));
      expect(accuracyInsight.tone, InsightTone.positive);
      expect(accuracyInsight.headline, contains('40%')); // (0.7-0.5)/0.5 = 40%
    });

    test('emits a streak insight only when streakDays >= 3', () {
      final withoutStreak = buildInsights(
        summary: _summary(streakDays: 2),
        accuracyPoints: _points([]),
      );
      expect(withoutStreak.any((i) => i.headline.contains('streak')), isFalse);

      final withStreak = buildInsights(
        summary: _summary(streakDays: 5),
        accuracyPoints: _points([]),
      );
      final streakInsight = withStreak.firstWhere((i) => i.headline.contains('streak'));
      expect(streakInsight.headline, '5-day streak');
      expect(streakInsight.tone, InsightTone.positive);
    });

    test('emits a gentle nudge when nothing practiced today', () {
      final insights = buildInsights(
        summary: _summary(todayItems: 0),
        accuracyPoints: _points([]),
      );
      final nudge = insights.firstWhere((i) => i.headline.contains('No practice'));
      expect(nudge.tone, InsightTone.neutral);
    });

    test('returns an empty list when there is nothing meaningful to say', () {
      final insights = buildInsights(
        summary: _summary(streakDays: 1, todayItems: 2),
        accuracyPoints: _points([]),
      );
      expect(insights, isEmpty);
    });
  });
}
