import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flexikeys/l10n/app_localizations.dart';
import 'package:flexikeys/data/coloring_items/coloring_item_def.dart';
import 'package:flexikeys/data/trace_items/trace_item_def.dart';
import 'package:flexikeys/screens/game/coloring_screen.dart';
import 'package:flexikeys/screens/game/trace_drawing_screen.dart';
import 'package:flexikeys/screens/game/animals_coloring_screen.dart';
import 'package:flexikeys/screens/game/object_drawing_screen.dart';

/// Proves the actual reported bug is fixed: under a Russian UI locale, the
/// Drawing module showed Uzbek item labels/category titles (e.g. "Raskras':
/// Mushuk!" instead of "Раскрась: Кошка!") because no ContentItem-style
/// locale resolution existed for this module's data and no screen title
/// routed through AppLocalizations. These tests intentionally do NOT await
/// the TTS call itself (see level_audio_player_test.dart's note on why) —
/// only the on-screen text, which is what actually regressed.
void main() {
  Future<void> pumpRu(WidgetTester tester, Widget child) async {
    SharedPreferences.setMockInitialValues({});
    // Wider than the usual 390pt baseline — these screens' header Row has
    // a pre-existing (unrelated to this fix) overflow at 390pt even with
    // a trivial title, which isn't what these tests are checking.
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('ColoringScreen shows the Russian label, not the Uzbek one',
      (tester) async {
    const item = ColoringItemDef(
      label: 'Mushuk',
      ruLabel: 'Кошка',
      outline: [
        [Offset(0.2, 0.2), Offset(0.8, 0.2), Offset(0.8, 0.8), Offset(0.2, 0.8)],
      ],
    );
    await pumpRu(
      tester,
      const ColoringScreen(
        title: 'test',
        items: [item],
        levelSlug: 'test_slug',
        completionTitle: 'done',
      ),
    );

    expect(find.textContaining('Кошка'), findsWidgets);
    expect(find.textContaining('Mushuk'), findsNothing);
  });

  testWidgets('TraceDrawingScreen shows the Russian label, not the Uzbek one',
      (tester) async {
    const item = TraceItemDef(
      label: 'Uy',
      ruLabel: 'Дом',
      dots: [Offset(0.2, 0.2), Offset(0.8, 0.8)],
      ghost: [
        [Offset(0.2, 0.2), Offset(0.8, 0.8)],
      ],
    );
    await pumpRu(
      tester,
      const TraceDrawingScreen(
        title: 'test',
        items: [item],
        levelSlug: 'test_slug',
        completionTitle: 'done',
      ),
    );

    expect(find.textContaining('Дом'), findsWidgets);
    expect(find.textContaining('Uy'), findsNothing);
  });

  testWidgets(
      'AnimalsColoringScreen header title is Russian ("Животные"), not '
      'the hardcoded Uzbek "Hayvonlar"', (tester) async {
    await pumpRu(tester, const AnimalsColoringScreen());
    expect(find.textContaining('Животные'), findsWidgets);
    expect(find.textContaining('Hayvonlar'), findsNothing);
  });

  testWidgets(
      'ObjectDrawingScreen header title is Russian ("Предметы"), not the '
      'hardcoded Uzbek "Narsalar"', (tester) async {
    await pumpRu(tester, const ObjectDrawingScreen());
    expect(find.textContaining('Предметы'), findsWidgets);
    expect(find.textContaining('Narsalar'), findsNothing);
  });
}
