import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flexikeys/design_system/design_system.dart';
import 'package:flexikeys/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: FlexiKeysTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('AacCard', () {
    testWidgets('renders label and glyph', (tester) async {
      await tester.pumpWidget(_wrap(AacCard(
        category: AacCategory.needs,
        label: 'Water',
        glyph: const Text('💧'),
        onActivate: () {},
      )));
      expect(find.text('Water'), findsOneWidget);
      expect(find.text('💧'), findsOneWidget);
    });

    testWidgets('tap-release calls onActivate', (tester) async {
      var activated = 0;
      await tester.pumpWidget(_wrap(AacCard(
        category: AacCategory.needs,
        label: 'Water',
        glyph: const Text('💧'),
        onActivate: () => activated++,
      )));
      await tester.tap(find.byType(AacCard));
      await tester.pump();
      expect(activated, 1);
    });

    testWidgets('repeated taps within debounce window fire once', (tester) async {
      var activated = 0;
      await tester.pumpWidget(_wrap(AacCard(
        category: AacCategory.needs,
        label: 'Water',
        glyph: const Text('💧'),
        onActivate: () => activated++,
      )));
      await tester.tap(find.byType(AacCard));
      await tester.tap(find.byType(AacCard));
      await tester.pump();
      expect(activated, 1);
    });

    testWidgets('dwell mode: quick tap-release does not activate', (tester) async {
      var activated = 0;
      await tester.pumpWidget(_wrap(AacCard(
        category: AacCategory.needs,
        label: 'Water',
        glyph: const Text('💧'),
        dwellEnabled: true,
        dwellDuration: const Duration(milliseconds: 600),
        onActivate: () => activated++,
      )));
      await tester.tap(find.byType(AacCard));
      await tester.pump(const Duration(milliseconds: 100));
      expect(activated, 0);
    });

    testWidgets('dwell mode: holding past dwellDuration activates', (tester) async {
      var activated = 0;
      await tester.pumpWidget(_wrap(AacCard(
        category: AacCategory.needs,
        label: 'Water',
        glyph: const Text('💧'),
        dwellEnabled: true,
        dwellDuration: const Duration(milliseconds: 300),
        onActivate: () => activated++,
      )));
      final gesture = await tester.startGesture(tester.getCenter(find.byType(AacCard)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(activated, 1);
      await gesture.up();
    });

    testWidgets('honors explicit size', (tester) async {
      await tester.pumpWidget(_wrap(AacCard(
        category: AacCategory.needs,
        label: 'Water',
        glyph: const Text('💧'),
        size: 140,
        onActivate: () {},
      )));
      final box = tester.renderObject(find.byType(AacCard)) as RenderBox;
      expect(box.size.width, 140);
      expect(box.size.height, 140);
    });
  });
}
