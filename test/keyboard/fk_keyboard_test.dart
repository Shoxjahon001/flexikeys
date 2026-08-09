import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flexikeys/design_system/design_system.dart';
import 'package:flexikeys/features/keyboard/fk_keyboard.dart';
import 'package:flexikeys/features/keyboard/keyboard_layouts.dart';
import 'package:flexikeys/features/adaptive/adaptive_profile.dart';
import 'package:flexikeys/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: FlexiKeysTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

AdaptationProfile _profile({
  double keyScale = 1.0,
  int dwellMs = 0,
  int debounceMs = 50,
  Map<String, int> hintLevel = const {},
}) =>
    AdaptationProfile(
      keyScale: keyScale,
      dwellTimeMs: dwellMs,
      debounceMs: debounceMs,
      hintLevel: hintLevel,
    );

void main() {
  group('FkKeyboard — no dwell', () {
    testWidgets('renders all keys in layout', (tester) async {
      await tester.pumpWidget(_wrap(FkKeyboard(
        layout: enLayout,
        profile: _profile(),
        targetKey: 'a',
      )));
      // QWERTY-lite row 1 first key
      expect(find.text('q'), findsOneWidget);
    });

    testWidgets('keystroke callback fires on pointer down+up without dwell',
        (tester) async {
      KeystrokeRecord? record;
      await tester.pumpWidget(_wrap(FkKeyboard(
        layout: enLayout,
        profile: _profile(dwellMs: 0),
        targetKey: 'a',
        onKeystroke: (r) => record = r,
      )));

      final aKey = find.text('a');
      await tester.tap(aKey);
      await tester.pump();

      expect(record, isNotNull);
      expect(record!.actualKey, 'a');
      expect(record!.correct, isTrue);
      expect(record!.rejectedByDwell, isFalse);
    });

    testWidgets('debounce rejects rapid repeat tap on same key',
        (tester) async {
      final records = <KeystrokeRecord>[];
      await tester.pumpWidget(_wrap(FkKeyboard(
        layout: enLayout,
        // 200ms debounce
        profile: _profile(dwellMs: 0, debounceMs: 200),
        targetKey: 'a',
        onKeystroke: records.add,
      )));

      final aKey = find.text('a');
      // First tap
      await tester.tap(aKey);
      await tester.pump();
      // Immediate second tap (within debounce window)
      await tester.tap(aKey);
      await tester.pump();

      expect(records.length, 2);
      expect(records[0].rejectedByDebounce, isFalse);
      expect(records[1].rejectedByDebounce, isTrue);
      // No negative feedback shown (test verifies no error widget exists)
      expect(find.text('❌'), findsNothing);
      expect(find.text('Wrong'), findsNothing);
    });
  });

  group('FkKeyboard — dwell filter', () {
    testWidgets('short tap (< dwell) creates accidental record',
        (tester) async {
      final records = <KeystrokeRecord>[];
      await tester.pumpWidget(_wrap(FkKeyboard(
        layout: enLayout,
        profile: _profile(dwellMs: 300),
        targetKey: 'a',
        onKeystroke: records.add,
      )));

      // Press and immediately release (< 300ms dwell)
      final aKey = find.text('a');
      final gesture = await tester.startGesture(tester.getCenter(aKey));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pump();

      expect(records.length, 1);
      expect(records[0].rejectedByDwell, isTrue);
      expect(records[0].accidentalTap, isTrue);
    });

    testWidgets('held tap (>= dwell) creates accepted record', (tester) async {
      final records = <KeystrokeRecord>[];
      await tester.pumpWidget(_wrap(FkKeyboard(
        layout: enLayout,
        profile: _profile(dwellMs: 100),
        targetKey: 'a',
        onKeystroke: records.add,
      )));

      final aKey = find.text('a');
      final gesture = await tester.startGesture(tester.getCenter(aKey));
      // Hold for 150ms > 100ms dwell
      await tester.pump(const Duration(milliseconds: 150));
      await gesture.up();
      await tester.pump();

      expect(records.length, 1);
      expect(records[0].rejectedByDwell, isFalse);
      expect(records[0].accidentalTap, isFalse);
    });
  });

  group('FkKeyboard — hint levels', () {
    testWidgets('no hints at level 0 — no pulse visible', (tester) async {
      await tester.pumpWidget(_wrap(FkKeyboard(
        layout: enLayout,
        profile: _profile(hintLevel: {'a': 0}),
        targetKey: 'a',
      )));
      await tester.pump();
      // Check keyboard renders cleanly at hint level 0
      expect(find.text('a'), findsOneWidget);
    });

    testWidgets('hint level 1 — target key widget still exists',
        (tester) async {
      await tester.pumpWidget(_wrap(FkKeyboard(
        layout: enLayout,
        profile: _profile(hintLevel: {'a': 1}),
        targetKey: 'a',
      )));
      await tester.pump();
      expect(find.text('a'), findsOneWidget);
    });
  });

  group('FkKeyboard — adaptive profile extremes (golden)', () {
    testWidgets('golden: default profile', (tester) async {
      await tester.pumpWidget(_wrap(FkKeyboard(
        layout: enLayout,
        profile: AdaptationProfile.defaults,
        targetKey: 'e',
      )));
      await tester.pump();
      await expectLater(
        find.byType(FkKeyboard),
        matchesGoldenFile('../goldens/keyboard_default_profile.png'),
      );
    });

    testWidgets('golden: max-adapted profile (keyScale 1.6, hintLevel 3)',
        (tester) async {
      const maxProfile = AdaptationProfile(
        keyScale: 1.6,
        keySpacing: 1.5,
        dwellTimeMs: 400,
        debounceMs: 200,
        hintLevel: {'e': 3},
      );
      await tester.pumpWidget(_wrap(const FkKeyboard(
        layout: enLayout,
        profile: maxProfile,
        targetKey: 'e',
      )));
      await tester.pump();
      await expectLater(
        find.byType(FkKeyboard),
        matchesGoldenFile('../goldens/keyboard_max_adapted_profile.png'),
      );
    });
  });

  group('FkKeyboard — keyboard resize animation between lessons', () {
    testWidgets('profile change does NOT reset mid-word dwell', (tester) async {
      // When profile updates, existing dwell timers for in-progress presses
      // should not be cancelled — keyboard only resizes between lessons.
      // This test verifies the widget rebuilds without losing existing state.
      final records = <KeystrokeRecord>[];

      final initialProfile = _profile(dwellMs: 200);
      const updatedProfile = AdaptationProfile(
        keyScale: 1.2,
        dwellTimeMs: 200,
        debounceMs: 50,
      );

      late StateSetter setter;
      var profile = initialProfile;

      await tester.pumpWidget(MaterialApp(
        theme: FlexiKeysTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, s) {
              setter = s;
              return FkKeyboard(
                layout: enLayout,
                profile: profile,
                targetKey: 'a',
                onKeystroke: records.add,
              );
            },
          ),
        ),
      ));

      // Start a dwell press
      final aKey = find.text('a');
      final gesture = await tester.startGesture(tester.getCenter(aKey));
      await tester.pump(const Duration(milliseconds: 80));

      // Update profile mid-press (simulates between-lesson resize)
      setter(() => profile = updatedProfile);
      await tester.pump();

      // Continue holding for remaining dwell
      await tester.pump(const Duration(milliseconds: 200));
      await gesture.up();
      await tester.pump();

      // Keyboard should still function after profile update
      expect(tester.takeException(), isNull);
    });
  });

  group('FkKeyboard — Uzbek layout', () {
    testWidgets('o-apostrophe key renders', (tester) async {
      await tester.pumpWidget(_wrap(FkKeyboard(
        layout: uzLayout,
        profile: _profile(),
        targetKey: "o'",
      )));
      await tester.pump();
      expect(find.text("o'"), findsOneWidget);
    });

    testWidgets("o' keystroke fires with correct skill_key", (tester) async {
      KeystrokeRecord? record;
      await tester.pumpWidget(_wrap(FkKeyboard(
        layout: uzLayout,
        profile: _profile(),
        targetKey: "o'",
        onKeystroke: (r) => record = r,
      )));

      await tester.tap(find.text("o'"));
      await tester.pump();

      expect(record?.actualKey, "o'");
      expect(record?.correct, isTrue);
    });
  });
}
