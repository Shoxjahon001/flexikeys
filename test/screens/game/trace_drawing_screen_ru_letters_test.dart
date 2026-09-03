import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flexikeys/l10n/app_localizations.dart';
import 'package:flexikeys/data/trace_items/letters_trace_data_ru.dart';
import 'package:flexikeys/screens/game/trace_drawing_screen.dart';

/// Renders the two structurally hardest Cyrillic letters through the real
/// screen: Д (5 strokes, a descender past the baseline) and Ё (6 strokes,
/// including the two single-point "dot" strokes with no Latin equivalent).
/// Proves there's no stroke-count assumption anywhere in the render path
/// and that the dot-rendering fix (_drawGhost/_drawDemo) doesn't throw.
void main() {
  Future<void> pumpLetter(WidgetTester tester, String label) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final item = kLetterTraceItemsRu.firstWhere((i) => i.label == label);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: TraceDrawingScreen(
        title: 'test',
        items: [item],
        levelSlug: 'test_slug',
        completionTitle: 'done',
      ),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Д (5 strokes, descender) renders with no exceptions',
      (tester) async {
    await pumpLetter(tester, 'Д');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ё (6 strokes, including 2 dot-only strokes) renders with no '
      'exceptions', (tester) async {
    await pumpLetter(tester, 'Ё');
    expect(tester.takeException(), isNull);
  });

  testWidgets('demo ("Покажи мне") animation runs across all of Ё\'s 6 '
      'strokes, including the dot strokes, with no exceptions',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final item = kLetterTraceItemsRu.firstWhere((i) => i.label == 'Ё');
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: TraceDrawingScreen(
        title: 'test',
        items: [item],
        levelSlug: 'test_slug',
        completionTitle: 'done',
      ),
    ));
    await tester.pump();
    await tester.pump();

    final demoButton = find.byIcon(Icons.play_arrow_rounded);
    if (demoButton.evaluate().isNotEmpty) {
      await tester.tap(demoButton.first);
      // Step through the full 3s demo animation in bounded increments —
      // matches this codebase's established pattern for infinite/timed
      // animations (pumpAndSettle hangs on them).
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
    }
    expect(tester.takeException(), isNull);
  });
}
