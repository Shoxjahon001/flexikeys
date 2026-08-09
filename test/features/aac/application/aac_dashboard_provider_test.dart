import 'package:flutter_test/flutter_test.dart';

import 'package:flexikeys/features/aac/application/aac_dashboard_provider.dart';

void main() {
  group('AacStatsResult.fromJson', () {
    test('parses today and trend arrays matching the backend contract', () {
      final result = AacStatsResult.fromJson({
        'today': [
          {'card_id': 'ne_water', 'category': 'needs', 'count': 12},
          {'card_id': 'fe_happy', 'category': 'feelings', 'count': 5},
        ],
        'trend': [
          {'date': '2026-07-20', 'category': 'needs', 'count': 4},
        ],
      });

      expect(result.today, hasLength(2));
      expect(result.today[0].cardId, 'ne_water');
      expect(result.today[0].count, 12);
      expect(result.trend, hasLength(1));
      expect(result.trend[0].category, 'needs');
      expect(result.trend[0].date, DateTime.parse('2026-07-20'));
    });

    test('parses empty arrays', () {
      final result = AacStatsResult.fromJson({'today': [], 'trend': []});
      expect(result.today, isEmpty);
      expect(result.trend, isEmpty);
    });
  });

  group('AacInsightsResult.fromJson', () {
    test('parses insights with a disclaimer', () {
      final result = AacInsightsResult.fromJson({
        'insights': [
          {
            'category': 'feelings',
            'headline': "'Feelings' selected more than usual",
            'body': 'Over the last 3 days...',
            'tone': 'attention',
          },
        ],
        'disclaimer': "Please note: I'm an educational assistant...",
      });

      expect(result.insights, hasLength(1));
      expect(result.insights[0].tone, 'attention');
      expect(result.disclaimer, isNotNull);
    });

    test('parses a null disclaimer when no attention-tone insight exists', () {
      final result = AacInsightsResult.fromJson({
        'insights': <Map<String, dynamic>>[],
        'disclaimer': null,
      });
      expect(result.insights, isEmpty);
      expect(result.disclaimer, isNull);
    });
  });
}
