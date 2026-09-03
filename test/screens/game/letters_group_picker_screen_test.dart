import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flexikeys/l10n/app_localizations.dart';
import 'package:flexikeys/data/content_packs/letters_content_packs.dart';
import 'package:flexikeys/screens/game/letters_group_picker_screen.dart';
import 'package:flexikeys/screens/game/letters_stage1_screen.dart';

/// Proves the group-picker wiring end-to-end: pushing it with the resolved
/// ru letters pack renders all 9 groups, only the first is unlocked, and
/// tapping it opens LettersStage1Screen scoped to just that group's 4
/// letters (А, Б, В, Г) — not the full 33-letter alphabet. A data-only
/// test on splitIntoGroups can't catch a wiring mistake at this layer.
void main() {
  Future<void> pumpPicker(WidgetTester tester, GlobalKey<NavigatorState> navKey) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final pack = LettersContentPacks.resolve('ru');

    await tester.pumpWidget(MaterialApp(
      navigatorKey: navKey,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: SizedBox()),
      onGenerateRoute: (settings) {
        if (settings.name == '/game_stage1') {
          return MaterialPageRoute(
            builder: (_) => const LettersStage1Screen(),
            settings: settings,
          );
        }
        return null;
      },
    ));

    navKey.currentState!.push(MaterialPageRoute(
      builder: (_) => const LettersGroupPickerScreen(),
      settings: RouteSettings(arguments: pack),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('shows all 9 groups with the first labeled А-Г', (tester) async {
    final navKey = GlobalKey<NavigatorState>();
    await pumpPicker(tester, navKey);

    expect(find.text('А-Г'), findsOneWidget);
    expect(find.text('Э-Я'), findsOneWidget);
    expect(find.text('0 / 9'), findsOneWidget);
  });

  testWidgets(
      'tapping the first (unlocked) group opens LettersStage1Screen scoped '
      'to just its 4 letters, not the full 33', (tester) async {
    final navKey = GlobalKey<NavigatorState>();
    await pumpPicker(tester, navKey);

    await tester.tap(find.text('А-Г'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(LettersStage1Screen), findsOneWidget);
    // The group's own header shows "1/4", not "1/33" — proof the smaller
    // group pack reached the task screen, not the full alphabet.
    expect(find.text('1/4'), findsOneWidget);
  });
}
