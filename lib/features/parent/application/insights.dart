library insights;

import 'package:flutter/material.dart';

import '../domain/parent_models.dart';

/// How an [InsightCard] should read visually — never a literal "bad" tone;
/// per product rules the child/parent experience never frames things as
/// failure, so [attention] still reads as a gentle nudge, not a warning.
enum InsightTone { positive, neutral, attention }

/// One proactively-surfaced observation about a child's practice, shown
/// above the assistant chat. Every field here is derived from data the
/// dashboard already fetches — nothing is invented client-side.
class InsightCard {
  final IconData icon;
  final String headline;
  final String body;
  final InsightTone tone;

  const InsightCard({
    required this.icon,
    required this.headline,
    required this.body,
    required this.tone,
  });
}

/// Builds a short list of insight cards from already-fetched real data
/// ([ChildSummary] from `/parent/children/:id/summary`, accuracy points from
/// `/progress/timeseries`). Pure function — no widget/BuildContext
/// dependency — so it's independently unit-testable and keeps this logic
/// out of the widget tree.
List<InsightCard> buildInsights({
  required ChildSummary summary,
  required List<TimeseriesPoint> accuracyPoints,
}) {
  final insights = <InsightCard>[];

  final delta = weekOverWeekAccuracyDelta(accuracyPoints);
  if (delta != null) {
    final pct = (delta * 100).round();
    if (pct != 0) {
      final up = pct > 0;
      insights.add(InsightCard(
        icon: up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
        headline: up ? 'Accuracy is up $pct% this week' : 'Accuracy dipped ${pct.abs()}% this week',
        body: up
            ? 'Keep up the momentum — recent practice is paying off.'
            : 'A dip happens sometimes — ask the assistant for a few at-home exercises.',
        tone: up ? InsightTone.positive : InsightTone.attention,
      ));
    }
  }

  if (summary.streakDays >= 3) {
    insights.add(InsightCard(
      icon: Icons.local_fire_department_rounded,
      headline: '${summary.streakDays}-day streak',
      body: '${summary.displayName} has practiced ${summary.streakDays} days in a row. Nice work!',
      tone: InsightTone.positive,
    ));
  }

  if (summary.todayItems == 0) {
    insights.add(const InsightCard(
      icon: Icons.schedule_rounded,
      headline: 'No practice yet today',
      body: 'A short 5-minute session keeps the streak going.',
      tone: InsightTone.neutral,
    ));
  }

  return insights;
}

/// Fractional change between the mean of the most recent 7 non-null values
/// and the mean of the 7 before that (e.g. 0.11 == "up 11%"). Returns null
/// when there isn't enough real data on either side to compare responsibly
/// — deliberately never extrapolates from a handful of points.
@visibleForTesting
double? weekOverWeekAccuracyDelta(List<TimeseriesPoint> points) {
  final values = points.where((p) => p.value != null).map((p) => p.value!).toList();
  if (values.length < 8) return null;

  final recent = values.sublist(values.length - 7);
  final priorEnd = values.length - 7;
  final priorStart = (priorEnd - 7).clamp(0, priorEnd);
  final prior = values.sublist(priorStart, priorEnd);
  if (prior.isEmpty) return null;

  final recentMean = recent.reduce((a, b) => a + b) / recent.length;
  final priorMean = prior.reduce((a, b) => a + b) / prior.length;
  if (priorMean == 0) return null;

  return (recentMean - priorMean) / priorMean;
}
