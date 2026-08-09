import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flexikeys/features/aac/data/aac_progression_store.dart';
import 'package:flexikeys/features/aac/data/aac_settings_store.dart';
import 'package:flexikeys/features/aac/domain/aac_progression.dart';
import 'package:flexikeys/features/aac/presentation/parent/aac_parent_settings_screen.dart';
import 'package:flexikeys/l10n/app_localizations.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AacSettingsStore.instance.resetCacheForTesting();
    AacProgressionStore.instance.resetCacheForTesting();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    // The full settings list (4 levels + card size row + 3 accessibility
    // switches + conditional slider) exceeds the default 800x600 test
    // surface — use a tall surface so every control is reachable without
    // fighting scroll/offstage finder semantics (see aac_card_manager_
    // screen_test.dart for the same fix and its rationale).
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AacParentSettingsScreen(),
    ));
    await tester.pumpAndSettle();
  }

  group('AacParentSettingsScreen', () {
    testWidgets('shows all four progression levels and accessibility switches', (tester) async {
      await pumpScreen(tester);

      expect(find.textContaining('Level 1'), findsOneWidget);
      expect(find.textContaining('Level 4'), findsOneWidget);
      expect(find.text('Dwell-time activation'), findsOneWidget);
      expect(find.text('High contrast'), findsOneWidget);
      expect(find.text('Reduced motion'), findsOneWidget);
    });

    testWidgets('toggling high contrast persists to AacSettingsStore', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.widgetWithText(SwitchListTile, 'High contrast'));
      await tester.pumpAndSettle();

      final settings = await AacSettingsStore.instance.get();
      expect(settings.highContrast, isTrue);
    });

    testWidgets('enabling dwell-time reveals the duration slider', (tester) async {
      await pumpScreen(tester);

      expect(find.byType(Slider), findsNothing);

      await tester.tap(find.widgetWithText(SwitchListTile, 'Dwell-time activation'));
      await tester.pumpAndSettle();

      expect(find.byType(Slider), findsOneWidget);
      final settings = await AacSettingsStore.instance.get();
      expect(settings.dwellEnabled, isTrue);
    });

    testWidgets('selecting a level persists to AacProgressionStore', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.textContaining('Level 3'));
      await tester.pumpAndSettle();

      final progression = await AacProgressionStore.instance.get();
      expect(progression.level, AacLevel.level3);
      expect(progression.manuallySet, isTrue);
    });

    testWidgets('selecting a card size persists to AacSettingsStore', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('XXL'));
      await tester.pumpAndSettle();

      final settings = await AacSettingsStore.instance.get();
      expect(settings.cardSize, AacCardSizeSetting.xxl);
    });
  });
}
