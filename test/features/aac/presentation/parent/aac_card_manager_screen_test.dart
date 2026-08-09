import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flexikeys/design_system/design_system.dart';
import 'package:flexikeys/features/aac/data/aac_custom_card_store.dart';
import 'package:flexikeys/features/aac/domain/aac_card_def.dart';
import 'package:flexikeys/features/aac/presentation/parent/aac_card_manager_screen.dart';
import 'package:flexikeys/l10n/app_localizations.dart';

Widget _wrap() => const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AacCardManagerScreen(),
    );

AacCardDef _sampleCard({Map<AacLanguage, String> audioAsset = const {}}) => AacCardDef(
      id: 'custom_1',
      category: AacCategory.people,
      kind: AacCardKind.direct,
      label: const {AacLanguage.en: 'Rex'},
      sentenceTemplate: const {AacLanguage.en: 'Rex'},
      animationAsset: '',
      audioAsset: audioAsset,
      difficultyTier: 1,
      isCustom: true,
    );

// AacCard's idle animation loops forever, so pumpAndSettle() would hang on
// the live preview — bounded pumps are used instead.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AacCustomCardStore.instance.resetCacheForTesting();
  });

  group('AacCardManagerScreen', () {
    testWidgets('shows the empty state when there are no custom cards', (tester) async {
      await tester.pumpWidget(_wrap());
      await _settle(tester);

      expect(find.textContaining('No custom cards yet'), findsOneWidget);
    });

    testWidgets('adding a card with a label and category shows it in the list', (tester) async {
      // The form (photo picker + label + chips + live preview) is taller
      // than the default 800x600 test surface once the preview appears —
      // widgets scrolled past a ListView's viewport are excluded by
      // flutter_test's default finders. Use a tall surface so the whole
      // form fits without scrolling.
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrap());
      await _settle(tester);

      await tester.tap(find.text('Add card'));
      await _settle(tester);

      await tester.enterText(find.byType(TextField), 'Rex');
      await _settle(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, 'play'));
      await _settle(tester);

      // Invoked directly rather than via tester.tap(): FkButton's own
      // tap-scale animation defers the onPressed call until that animation
      // completes, and the combination with this form's height (it can
      // exceed the default test surface once the live preview appears)
      // made gesture-based taps unreliable here. Calling onPressed directly
      // still exercises the real save logic without depending on gesture/
      // animation/scroll timing.
      final saveButton = tester.widget<FkButton>(find.widgetWithText(FkButton, 'Add card'));
      saveButton.onPressed!();
      // Generous settle: the pop transition + AacCustomCardStore.add() +
      // _load() (another SharedPreferences round trip) chain needs more
      // pumped time than the default _settle() budget to fully resolve.
      for (var i = 0; i < 4; i++) {
        await _settle(tester);
      }

      expect(find.text('Rex'), findsOneWidget);
      expect(find.text('play'), findsOneWidget);

      final saved = await AacCustomCardStore.instance.getAll();
      expect(saved, hasLength(1));
      expect(saved.first.isCustom, isTrue);
      // A parent-typed label isn't translated per language — it must
      // display/speak correctly no matter which learning language is
      // active, so the form saves it under all three, not just whichever
      // was active when the card was created.
      for (final lang in AacLanguage.values) {
        expect(saved.first.label[lang], 'Rex');
        expect(saved.first.sentenceTemplate[lang], 'Rex');
      }
    });

    testWidgets('deleting a card removes it after confirmation', (tester) async {
      await AacCustomCardStore.instance.add(_sampleCard());

      await tester.pumpWidget(_wrap());
      await _settle(tester);

      expect(find.text('Rex'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await _settle(tester);
      await tester.tap(find.text('Remove'));
      await _settle(tester);

      expect(find.text('Rex'), findsNothing);
      final saved = await AacCustomCardStore.instance.getAll();
      expect(saved, isEmpty);
    });

    testWidgets('a new card form offers to record a voice, none set yet', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrap());
      await _settle(tester);

      await tester.tap(find.text('Add card'));
      await _settle(tester);

      expect(find.text('Record voice'), findsOneWidget);
      expect(find.text('Voice recorded'), findsNothing);
    });

    testWidgets('editing a card with a recorded voice shows the recorded state', (tester) async {
      await AacCustomCardStore.instance.add(
        _sampleCard(audioAsset: const {AacLanguage.en: '/fake/path/rex.m4a'}),
      );

      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrap());
      await _settle(tester);

      await tester.tap(find.byIcon(Icons.edit_rounded));
      await _settle(tester);

      expect(find.text('Voice recorded'), findsOneWidget);
      expect(find.text('Record voice'), findsNothing);
    });
  });
}
