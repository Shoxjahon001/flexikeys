import 'package:flutter_test/flutter_test.dart';

import 'package:flexikeys/features/parent/application/follow_up_suggestions.dart';
import 'package:flexikeys/l10n/app_localizations_en.dart';
import 'package:flexikeys/l10n/app_localizations_uz.dart';

final _t = AppLocalizationsEn();

void main() {
  group('followUpSuggestions', () {
    test('matches week/summary prompts', () {
      expect(followUpSuggestions(_t, 'Weekly summary'),
          contains(_t.followUpCompareLastWeek));
    });

    test('matches practice/activity prompts', () {
      expect(followUpSuggestions(_t, 'Practice suggestions'),
          contains(_t.followUpWhyActivities));
    });

    test('matches letter/hard/weak prompts', () {
      expect(followUpSuggestions(_t, 'Which letters are hardest?'),
          contains(_t.followUpHowHelpAtHome));
    });

    test('matches adaptation/keyboard prompts', () {
      expect(followUpSuggestions(_t, 'How is the keyboard adapting?'),
          contains(_t.followUpWhyChanged));
    });

    test('falls back to a default set for unrecognized prompts', () {
      final result = followUpSuggestions(_t, 'Tell me a joke');
      expect(result, isNotEmpty);
      expect(result, contains(_t.followUpHowChildOverall));
    });

    test('is case-insensitive', () {
      expect(followUpSuggestions(_t, 'WEEKLY SUMMARY'),
          contains(_t.followUpCompareLastWeek));
    });

    test('matches Uzbek-localized chip prompts too', () {
      final tUz = AppLocalizationsUz();
      expect(
        followUpSuggestions(tUz, tUz.promptWeeklySummary),
        contains(tUz.followUpCompareLastWeek),
      );
    });
  });
}
