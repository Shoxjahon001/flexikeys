import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flexikeys/design_system/design_system.dart';
import 'package:flexikeys/features/aac/domain/aac_card_def.dart';
import 'package:flexikeys/features/aac/presentation/aac_confirmation_screen.dart';
import 'package:flexikeys/l10n/app_localizations.dart';

// AacConfirmationScreen's loop animation repeats forever, so pumpAndSettle()
// would hang here — bounded pumps are used instead.
Future<void> _settle(WidgetTester tester, {int steps = 6, int msPerStep = 60}) async {
  for (var i = 0; i < steps; i++) {
    await tester.pump(Duration(milliseconds: msPerStep));
  }
}

Widget _hostThatOpensConfirmation() {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AacConfirmationScreen(
                  category: AacCategory.needs,
                  glyph: Text('💧'),
                  sentence: 'I want water.',
                  bundledAudioAsset: null,
                  language: AacLanguage.en,
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AacConfirmationScreen', () {
    testWidgets('shows the sentence text and a replay + close control', (tester) async {
      await tester.pumpWidget(_hostThatOpensConfirmation());
      await tester.tap(find.text('open'));
      await _settle(tester);

      expect(find.byType(AacConfirmationScreen), findsOneWidget);
      expect(find.text('I want water.'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('close button pops back', (tester) async {
      await tester.pumpWidget(_hostThatOpensConfirmation());
      await tester.tap(find.text('open'));
      await _settle(tester);
      expect(find.byType(AacConfirmationScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await _settle(tester, steps: 10, msPerStep: 60);

      expect(find.byType(AacConfirmationScreen), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('auto-dismisses after the spoken sentence finishes', (tester) async {
      await tester.pumpWidget(_hostThatOpensConfirmation());
      await tester.tap(find.text('open'));
      await _settle(tester);
      expect(find.byType(AacConfirmationScreen), findsOneWidget);

      // Past the 2-second post-speech auto-dismiss delay.
      await _settle(tester, steps: 6, msPerStep: 500);

      expect(find.byType(AacConfirmationScreen), findsNothing);
    });
  });
}
