import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flexikeys/design_system/design_system.dart';
import 'package:flexikeys/features/aac/data/aac_custom_card_store.dart';
import 'package:flexikeys/features/aac/data/aac_settings_store.dart';
import 'package:flexikeys/features/aac/presentation/aac_card_grid_screen.dart';
import 'package:flexikeys/features/aac/presentation/aac_home_screen.dart';
import 'package:flexikeys/l10n/app_localizations.dart';

// AacCard's idle animation loops forever (`..repeat(reverse: true)`), so
// pumpAndSettle() would hang on any screen that renders one — bounded pumps
// are used throughout instead of pumpAndSettle().
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

  group('AacHomeScreen', () {
    testWidgets('shows all six category tiles', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AacHomeScreen(),
      ));
      await _settle(tester);

      expect(find.byType(AacCategoryTile), findsNWidgets(6));
      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Needs'), findsOneWidget);
      expect(find.text('Feelings'), findsOneWidget);
      expect(find.text('People'), findsOneWidget);
      expect(find.text('Places'), findsOneWidget);
      expect(find.text('Play'), findsOneWidget);
    });

    testWidgets('tapping a category opens its Card Grid screen', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AacHomeScreen(),
      ));
      await _settle(tester);

      await tester.tap(find.text('Needs'));
      await _settle(tester);

      expect(find.byType(AacCardGridScreen), findsOneWidget);
    });
  });
}
