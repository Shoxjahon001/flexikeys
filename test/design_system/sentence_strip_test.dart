import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flexikeys/design_system/design_system.dart';
import 'package:flexikeys/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: FlexiKeysTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  group('SentenceStrip', () {
    testWidgets('shows placeholder text and disabled controls when empty', (tester) async {
      var speakCalls = 0;
      var clearCalls = 0;
      await tester.pumpWidget(_wrap(SentenceStrip(
        entries: const [],
        onSpeak: () => speakCalls++,
        onClear: () => clearCalls++,
      )));
      expect(find.text('Tap cards to build a sentence'), findsOneWidget);

      final speakButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.volume_up_rounded),
      );
      expect(speakButton.onPressed, isNull);
    });

    testWidgets('renders each entry word and emoji', (tester) async {
      await tester.pumpWidget(_wrap(const SentenceStrip(
        entries: [
          SentenceStripEntry(emoji: '👩', word: 'Mom'),
          SentenceStripEntry(emoji: '💧', word: 'Water'),
        ],
      )));
      expect(find.text('Mom'), findsOneWidget);
      expect(find.text('👩'), findsOneWidget);
      expect(find.text('Water'), findsOneWidget);
      expect(find.text('💧'), findsOneWidget);
    });

    testWidgets('speak and clear fire callbacks when entries exist', (tester) async {
      var speakCalls = 0;
      var clearCalls = 0;
      await tester.pumpWidget(_wrap(SentenceStrip(
        entries: const [SentenceStripEntry(emoji: '👩', word: 'Mom')],
        onSpeak: () => speakCalls++,
        onClear: () => clearCalls++,
      )));
      await tester.tap(find.widgetWithIcon(IconButton, Icons.volume_up_rounded));
      await tester.tap(find.widgetWithIcon(IconButton, Icons.backspace_rounded));
      expect(speakCalls, 1);
      expect(clearCalls, 1);
    });
  });
}
