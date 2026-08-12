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

  // AacCardGridScreen no longer takes `language` as a constructor param —
  // it follows the app's UI language (Localizations.localeOf), so tests
  // set that via MaterialApp's `locale` instead.
  Widget wrap() => const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AacCardGridScreen(
          category: AacCategory.needs,
          categoryLabel: 'Needs',
        ),
      );

  group('AacCardGridScreen', () {
    testWidgets('shows every card in the category — no per-screen cap', (tester) async {
      await tester.pumpWidget(wrap());
      await _settle(tester);

      // Needs has 7 real built-in cards; the old 6-card ceiling used to
      // hide one (and risked hiding an existing card whenever a new one
      // was added) — all of them must be present now, scrollable instead
      // of capped.
      expect(find.byType(AacCard).evaluate().length, 7);
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

    testWidgets('adding a new custom card never hides an existing one',
        (tester) async {
      // A custom card is always tier 1 (aac_card_manager_screen.dart's
      // _save()) — under the old sort-by-tier-then-take(6) behavior, a new
      // tier-1 card could push an existing card out of the visible set.
      await AacCustomCardStore.instance.add(const AacCardDef(
        id: 'custom_test_card',
        category: AacCategory.needs,
        kind: AacCardKind.direct,
        label: {AacLanguage.en: 'Brand New Card'},
        sentenceTemplate: {AacLanguage.en: 'I want brand new card.'},
        animationAsset: '',
        audioAsset: {},
        difficultyTier: 1,
        isCustom: true,
      ));

      await tester.pumpWidget(wrap());
      await _settle(tester);

      // All 7 original built-in cards are still there, plus the new one.
      expect(find.byType(AacCard).evaluate().length, 8);
      expect(find.text('Water'), findsOneWidget);
      expect(find.text('Help'), findsOneWidget);
      expect(find.text('Brand New Card'), findsOneWidget);
    });

    testWidgets('card labels switch language live if the UI language changes while open',
        (tester) async {
      await tester.pumpWidget(wrap());
      await _settle(tester);
      expect(find.text('Water'), findsOneWidget);

      await tester.pumpWidget(const MaterialApp(
        locale: Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AacCardGridScreen(
          category: AacCategory.needs,
          categoryLabel: 'Needs',
        ),
      ));
      await _settle(tester);

      expect(find.text('Water'), findsNothing);
      expect(find.text('Вода'), findsOneWidget);
    });
  });
}
