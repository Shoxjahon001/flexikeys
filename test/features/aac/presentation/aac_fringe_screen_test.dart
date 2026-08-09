import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flexikeys/features/aac/data/aac_card_repository.dart';
import 'package:flexikeys/features/aac/data/aac_custom_card_store.dart';
import 'package:flexikeys/features/aac/data/aac_settings_store.dart';
import 'package:flexikeys/features/aac/domain/aac_card_def.dart';
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

  Future<AacCardDef> loadFoodCard() async {
    final cards = await AacCardRepository.instance.loadStarterVocabulary();
    return cards.firstWhere((c) => c.id == 'ne_food');
  }

  group('AacFringeScreen', () {
    testWidgets('shows every fringe option for the branch card', (tester) async {
      final card = await loadFoodCard();
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AacFringeScreen(card: card, language: AacLanguage.en),
      ));
      await _settle(tester);

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Bread'), findsOneWidget);
      expect(find.text('Rice'), findsOneWidget);
    });

    testWidgets('picking an option speaks the completed sentence', (tester) async {
      final card = await loadFoodCard();
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AacFringeScreen(card: card, language: AacLanguage.en),
      ));
      await _settle(tester);

      await tester.tap(find.text('Banana'));
      await _settle(tester);

      expect(find.byType(AacConfirmationScreen), findsOneWidget);
      expect(find.text('I want banana.'), findsOneWidget);
    });
  });
}
