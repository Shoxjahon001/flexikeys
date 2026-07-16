import 'package:flutter_test/flutter_test.dart';

import 'package:flexikeys/features/parent/application/follow_up_suggestions.dart';

void main() {
  group('followUpSuggestions', () {
    test('matches week/summary prompts', () {
      expect(followUpSuggestions('Weekly summary'), contains('Compare to last week'));
    });

    test('matches practice/activity prompts', () {
      expect(followUpSuggestions('Practice suggestions'), contains('Why these activities?'));
    });

    test('matches letter/hard/weak prompts', () {
      expect(followUpSuggestions('Which letters are hardest?'), contains('How can I help at home?'));
    });

    test('matches adaptation/keyboard prompts', () {
      expect(followUpSuggestions('How is the keyboard adapting?'), contains('Why did this change?'));
    });

    test('falls back to a default set for unrecognized prompts', () {
      final result = followUpSuggestions('Tell me a joke');
      expect(result, isNotEmpty);
      expect(result, contains('How is my child doing overall?'));
    });

    test('is case-insensitive', () {
      expect(followUpSuggestions('WEEKLY SUMMARY'), contains('Compare to last week'));
    });
  });
}
