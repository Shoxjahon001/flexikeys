import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flexikeys/design_system/design_system.dart';
import 'package:flexikeys/features/aac/data/aac_custom_card_store.dart';
import 'package:flexikeys/features/aac/data/aac_settings_store.dart';
import 'package:flexikeys/features/aac/domain/aac_card_def.dart';
import 'package:flexikeys/features/aac/presentation/aac_card_grid_screen.dart';
import 'package:flexikeys/features/aac/presentation/aac_confirmation_screen.dart';
import 'package:flexikeys/features/aac/presentation/aac_fringe_screen.dart';
import 'package:flexikeys/l10n/app_localizations.dart';

// AacCard's idle animation loops forever, so pumpAndSettle() would hang on
// this screen — bounded pumps are used instead.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AacSettingsStore.instance.resetCacheForTesting();
    AacCustomCardStore.instance.resetCacheForTesting();
  });

  Widget wrap() => const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AacCardGridScreen(
          category: AacCategory.needs,
          categoryLabel: 'Needs',
          language: AacLanguage.en,
        ),
      );

  group('AacCardGridScreen', () {
    testWidgets('shows at most 6 cards (grid-rule ceiling), lowest tier first', (tester) async {
      await tester.pumpWidget(wrap());
      await _settle(tester);

      expect(find.byType(AacCard).evaluate().length, lessThanOrEqualTo(6));
      // Needs has 7 real cards; tier-1 "Water"/"Help" must always survive the cap.
      expect(find.text('Water'), findsOneWidget);
      expect(find.text('Help'), findsOneWidget);
    });

    testWidgets('tapping a direct card opens the confirmation screen with its sentence',
        (tester) async {
      await tester.pumpWidget(wrap());
      await _settle(tester);

      await tester.tap(find.text('Water'));
      await _settle(tester);

      expect(find.byType(AacConfirmationScreen), findsOneWidget);
      expect(find.text('I want water.'), findsOneWidget);
    });

    testWidgets('tapping a branch card opens the fringe screen', (tester) async {
      await tester.pumpWidget(wrap());
      await _settle(tester);

      await tester.tap(find.text('Food'));
      await _settle(tester);

      expect(find.byType(AacFringeScreen), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
    });
  });
}
