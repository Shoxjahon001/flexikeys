import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flexikeys/design_system/design_system.dart';
import 'package:flexikeys/features/aac/data/aac_custom_card_store.dart';
import 'package:flexikeys/features/aac/data/aac_settings_store.dart';
import 'package:flexikeys/features/aac/presentation/aac_card_grid_screen.dart';
import 'package:flexikeys/features/aac/presentation/aac_home_screen.dart';
import 'package:flexikeys/l10n/app_localizations.dart';
import 'package:flexikeys/services/user_service.dart';

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

      // 5 real vocabulary categories (mockup order: Daily/Feelings/Needs/
      // People/Places) + 1 "My Cards" shortcut tile — see aac_home_screen.dart
      // doc comment for why Play isn't one of the 6 anymore.
      expect(find.byType(AacCategoryTile), findsNWidgets(6));
      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Needs'), findsOneWidget);
      expect(find.text('Feelings'), findsOneWidget);
      expect(find.text('People'), findsOneWidget);
      expect(find.text('Places'), findsOneWidget);
      expect(find.text('My Cards'), findsOneWidget);
    });

    testWidgets('tapping a category opens its Card Grid screen',
        (tester) async {
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

    testWidgets('tapping My Cards is parent-gated, not a direct route',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AacHomeScreen(),
      ));
      await _settle(tester);

      await tester.tap(find.text('My Cards'));
      await _settle(tester);

      // Same gate main_shell.dart already uses for Profile — a child must
      // not reach card create/edit/delete directly from Home.
      expect(find.byType(FkParentGate), findsOneWidget);
    });

    testWidgets(
        'title and category chrome follow the UI language, independent of the learning language',
        (tester) async {
      // Learning language stays default (en) while only the UI/interface
      // language changes — the screen title and category folder names are
      // chrome, so they must track the UI language, unlike the vocabulary
      // cards inside each category which stay on the learning language.
      await UserService.setUiLanguage('ru');

      await tester.pumpWidget(const MaterialApp(
        locale: Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AacHomeScreen(),
      ));
      await _settle(tester);

      expect(find.text('Мой голос'), findsOneWidget); // navVoiceTab (title)
      expect(find.text('Повседневные'), findsOneWidget); // Daily
      expect(find.text('Потребности'), findsOneWidget); // Needs
      expect(find.text('Чувства'), findsOneWidget); // Feelings
      expect(find.text('Люди'), findsOneWidget); // People
      expect(find.text('Места'), findsOneWidget); // Places
      expect(find.text('Мои карточки'), findsOneWidget); // My Cards
    });
  });
}
