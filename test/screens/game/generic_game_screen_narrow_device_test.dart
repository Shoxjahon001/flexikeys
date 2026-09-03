import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flexikeys/l10n/app_localizations.dart';
import 'package:flexikeys/data/content_packs/content_pack.dart';
import 'package:flexikeys/screens/game/generic_game_screen.dart';

/// The single hardest case the Phase 3 spec calls out by name: "verify
/// layout on the narrowest supported device with the longest Russian word
/// and the largest key count." ОДИННАДЦАТЬ ("eleven") is simultaneously
/// the longest word across every ru content pack (11 characters — longer
/// than any English word, whose max is PINEAPPLE at 9) AND, via
/// keyCountFor, lands on the largest (10-key) board. 320pt is this task's
/// established narrow-device baseline (Phase 0's investigation; an iPhone
/// SE 1st-gen-class width).
void main() {
  const longestRuWord = ContentPack(
    categoryId: 'numbers',
    locale: 'ru',
    title: 'Числа',
    questionCount: 1,
    ordered: true,
    alphabet: 'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ',
    answerDrivenKeyCount: true,
    items: [
      ContentItem(id: 'ru.numbers.11', display: '11', word: 'ОДИННАДЦАТЬ'),
    ],
  );

  testWidgets(
      'longest ru word (11 chars, 10-key board) on a 320pt-wide device: no '
      'overflow, no clipping, every tile ≥64dp', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navKey,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: SizedBox()),
    ));

    navKey.currentState!.push(MaterialPageRoute(
      builder: (_) => const GenericGameScreen(),
      settings: const RouteSettings(arguments: longestRuWord),
    ));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // No FlutterError (RenderFlex overflow etc.) was recorded during pump.
    expect(tester.takeException(), isNull);

    // ОДИННАДЦАТЬ has 8 unique letters -> keyCountFor(8) == 10.
    final tileFinder = find.byType(AnimatedContainer);
    expect(tileFinder, findsNWidgets(10), reason: 'board must have 10 keys');

    for (var i = 0; i < 10; i++) {
      final size = tester.getSize(tileFinder.at(i));
      expect(size.width, greaterThanOrEqualTo(64.0),
          reason: 'tile $i width ${size.width}');
      expect(size.height, greaterThanOrEqualTo(64.0),
          reason: 'tile $i height ${size.height}');
    }

    // The 11-box answer-slot row must still be fully on-screen (the
    // FittedBox scales it down, never overflows) — every letter of the
    // word must be findable as rendered text, not clipped away.
    for (final letter in 'ОДИННАДЦАТЬ'.split('').toSet()) {
      expect(find.text(letter), findsWidgets, reason: 'letter "$letter"');
    }
  });

  testWidgets(
      'КОРИЧНЕВЫЙ (10 unique letters — zero-distractor edge case) renders '
      'a full 10-key board with no crash and no overflow', (tester) async {
    const pack = ContentPack(
      categoryId: 'colors',
      locale: 'ru',
      title: 'Цвета',
      questionCount: 1,
      alphabet: 'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ',
      answerDrivenKeyCount: true,
      items: [
        ContentItem(id: 'ru.colors.brown', display: 'Коричневый', word: 'КОРИЧНЕВЫЙ'),
      ],
    );
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navKey,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: SizedBox()),
    ));
    navKey.currentState!.push(MaterialPageRoute(
      builder: (_) => const GenericGameScreen(),
      settings: const RouteSettings(arguments: pack),
    ));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    // 10 unique letters, 0 distractors — the board is exactly the word's
    // own letters, nothing more.
    expect(find.byType(AnimatedContainer), findsNWidgets(10));
  });

  testWidgets(
      'regression guard: an en word landing on a 10-key board still uses '
      'the original 5-column layout, not the new ru 4-column one', (tester) async {
    const enWord = ContentPack(
      categoryId: 'colors',
      locale: 'en',
      title: 'Colors',
      questionCount: 1,
      alphabet: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
      // answerDrivenKeyCount defaults to false — this pack never opts in.
      items: [
        ContentItem(id: 'en.colors.orange', display: 'Orange', word: 'ORANGE'),
      ],
    );
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navKey,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: SizedBox()),
    ));
    navKey.currentState!.push(MaterialPageRoute(
      builder: (_) => const GenericGameScreen(),
      settings: const RouteSettings(arguments: enWord),
    ));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    // en's own _gridSize logic (unchanged): with only 1 question, _current
    // is always in the "last third", so target=10, clamped to
    // max(uniqueCount=6, ...) = 10 — still the original position-based
    // path, not keyCountFor.
    final tiles = find.byType(AnimatedContainer);
    expect(tiles, findsNWidgets(10));
    // GridView with 5 columns means row 1 and row 2 each start a new
    // Y-offset every 5 tiles; the 6th tile (index 5) must sit at a new,
    // greater dy than the 1st (index 0) — proof of 5 columns, not 4.
    final firstY = tester.getTopLeft(tiles.at(0)).dy;
    final sixthY = tester.getTopLeft(tiles.at(5)).dy;
    expect(sixthY, greaterThan(firstY));
    final fifthY = tester.getTopLeft(tiles.at(4)).dy;
    expect(fifthY, firstY, reason: 'tile 5 (index 4) must still be on row 1 with 5 columns');
  });

  testWidgets(
      'deterministic shuffle: pushing the exact same ru item twice produces '
      'the identical keyboard tile order both times — a retry/relaunch '
      'must not reshuffle the board', (tester) async {
    const zebraPack = ContentPack(
      categoryId: 'animals',
      locale: 'ru',
      title: 'Животные',
      questionCount: 1,
      alphabet: 'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ',
      answerDrivenKeyCount: true,
      items: [
        ContentItem(id: 'ru.animals.zebra', display: '🦓', word: 'ЗЕБРА'),
      ],
    );

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Future<List<String>> renderAndReadGrid() async {
      SharedPreferences.setMockInitialValues({});
      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(MaterialApp(
        navigatorKey: navKey,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: SizedBox()),
      ));
      navKey.currentState!.push(MaterialPageRoute(
        builder: (_) => const GenericGameScreen(),
        settings: const RouteSettings(arguments: zebraPack),
      ));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final tiles = find.byType(AnimatedContainer);
      final letters = <String>[];
      for (var i = 0; i < tiles.evaluate().length; i++) {
        final textWidget =
            tester.widget<Text>(find.descendant(of: tiles.at(i), matching: find.byType(Text)));
        letters.add(textWidget.data!);
      }
      return letters;
    }

    final first = await renderAndReadGrid();
    final second = await renderAndReadGrid();

    expect(first.length, 8, reason: 'ЗЕБРА has 5 unique letters -> keyCountFor(5) == 8');
    expect(first, second,
        reason: 'the exact same item must shuffle to the exact same board every time');
  });
}
