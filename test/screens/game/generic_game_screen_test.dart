import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flexikeys/l10n/app_localizations.dart';
import 'package:flexikeys/data/content_packs/spelling_content_packs.dart';
import 'package:flexikeys/screens/game/generic_game_screen.dart';

/// Proves the route-argument wiring end-to-end: pushing '/generic_game'
/// with a resolved ContentPack (exactly what levels_screen.dart now does)
/// actually reaches GenericGameScreen and renders that pack's first word —
/// a data-only test on SpellingContentPacks can't catch a wiring mistake
/// like a wrong `is` type check or a dropped argument.
void main() {
  testWidgets(
      'pushing generic_game with the resolved numbers pack renders its '
      'first question (ONE) and title', (tester) async {
    SharedPreferences.setMockInitialValues({});
    // The default 800x600 test surface is shorter than any real phone and
    // makes this full-screen Column overflow (it fits fine on an actual
    // device's taller, narrower viewport) — size the surface like a real
    // phone instead, per this repo's established test convention.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final navKey = GlobalKey<NavigatorState>();
    final pack = SpellingContentPacks.resolve('numbers', 'en')!;

    await tester.pumpWidget(MaterialApp(
      navigatorKey: navKey,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: SizedBox()),
    ));

    navKey.currentState!.push(MaterialPageRoute(
      builder: (_) => const GenericGameScreen(),
      settings: RouteSettings(arguments: pack),
    ));
    await tester.pump();
    await tester.pump();
    // Flushes _resetWord's 350ms-delayed TTS call so no Timer is left
    // pending when the test tears down.
    await tester.pump(const Duration(milliseconds: 400));

    // "ONE" is ordered:true, so item 0 (numbers.ONE) is always first.
    // Each letter renders twice: once in the word-answer boxes, once as
    // one of its own required tiles in the letter-picker grid below.
    expect(find.text('O'), findsNWidgets(2));
    expect(find.text('N'), findsNWidgets(2));
    expect(find.text('E'), findsNWidgets(2));
    // The digit hint tile shows the display value, "1" — unique on screen
    // (the header's "1 / 15" counter is one interpolated string, not a
    // separate "1" text node).
    expect(find.text('1'), findsOneWidget);
  });
}
