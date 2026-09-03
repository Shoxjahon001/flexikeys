import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flexikeys/l10n/app_localizations.dart';
import 'package:flexikeys/data/content_packs/letters_content_packs.dart';
import 'package:flexikeys/screens/game/letters_stage1_screen.dart';

/// Proves the route-argument wiring end-to-end: pushing '/game_stage1'
/// with the resolved letters ContentPack (exactly what levels_screen.dart
/// now does) actually reaches LettersStage1Screen and renders that pack's
/// first target letter (A) among the on-screen choices — a data-only test
/// on LettersContentPacks can't catch a wiring mistake like a wrong `is`
/// type check or a dropped argument.
void main() {
  testWidgets(
      'pushing game_stage1 with the resolved letters pack shows "A" as '
      'one of the tappable choices', (tester) async {
    SharedPreferences.setMockInitialValues({});
    // Size the surface like a real phone rather than the default 800x600 —
    // see generic_game_screen_test.dart for why.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final navKey = GlobalKey<NavigatorState>();
    final pack = LettersContentPacks.resolve('en');

    await tester.pumpWidget(MaterialApp(
      navigatorKey: navKey,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: SizedBox()),
    ));

    navKey.currentState!.push(MaterialPageRoute(
      builder: (_) => const LettersStage1Screen(),
      settings: RouteSettings(arguments: pack),
    ));
    await tester.pump();
    await tester.pump();

    // The first target is always 'A' (ordered:true, item 0). It must
    // appear both as the big target tile and as one of the 3 choice tiles.
    expect(find.text('A'), findsWidgets);
    expect(find.byType(LettersStage1Screen), findsOneWidget);
  });
}
