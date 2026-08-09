library aac_dashboard_provider;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

final _api = ApiClient.instance;

// ── Models (mirror backend/src/flexikeys/modules/aac/schemas.py) ──────────────

class AacTodayCardStat {
  final String cardId;
  final String category;
  final int count;

  const AacTodayCardStat({
    required this.cardId,
    required this.category,
    required this.count,
  });

  factory AacTodayCardStat.fromJson(Map<String, dynamic> json) => AacTodayCardStat(
        cardId: json['card_id'] as String,
        category: json['category'] as String,
        count: json['count'] as int,
      );
}

class AacTrendPoint {
  final DateTime date;
  final String category;
  final int count;

  const AacTrendPoint({
    required this.date,
    required this.category,
    required this.count,
  });

  factory AacTrendPoint.fromJson(Map<String, dynamic> json) => AacTrendPoint(
        date: DateTime.parse(json['date'] as String),
        category: json['category'] as String,
        count: json['count'] as int,
      );
}

class AacStatsResult {
  final List<AacTodayCardStat> today;
  final List<AacTrendPoint> trend;

  const AacStatsResult({required this.today, required this.trend});

  factory AacStatsResult.fromJson(Map<String, dynamic> json) => AacStatsResult(
        today: (json['today'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(AacTodayCardStat.fromJson)
            .toList(),
        trend: (json['trend'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(AacTrendPoint.fromJson)
            .toList(),
      );
}

class AacInsight {
  final String category;
  final String headline;
  final String body;
  final String tone; // "positive" | "neutral" | "attention"

  const AacInsight({
    required this.category,
    required this.headline,
    required this.body,
    required this.tone,
  });

  factory AacInsight.fromJson(Map<String, dynamic> json) => AacInsight(
        category: json['category'] as String,
        headline: json['headline'] as String,
        body: json['body'] as String,
        tone: json['tone'] as String,
      );
}

class AacInsightsResult {
  final List<AacInsight> insights;
  final String? disclaimer;

  const AacInsightsResult({required this.insights, required this.disclaimer});

  factory AacInsightsResult.fromJson(Map<String, dynamic> json) => AacInsightsResult(
        insights: (json['insights'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(AacInsight.fromJson)
            .toList(),
        disclaimer: json['disclaimer'] as String?,
      );
}

// ── Providers ───────────────────────────────────────────────────────────────

final aacStatsProvider =
    FutureProvider.family<AacStatsResult, String>((ref, childId) async {
  final resp = await _api.get('/aac/stats?child_id=$childId');
  if (resp.statusCode != 200) throw Exception('aac_stats_error');
  return AacStatsResult.fromJson(json.decode(resp.body) as Map<String, dynamic>);
});

final aacInsightsProvider =
    FutureProvider.family<AacInsightsResult, String>((ref, childId) async {
  final resp = await _api.get('/aac/insights?child_id=$childId');
  if (resp.statusCode != 200) throw Exception('aac_insights_error');
  return AacInsightsResult.fromJson(json.decode(resp.body) as Map<String, dynamic>);
});
