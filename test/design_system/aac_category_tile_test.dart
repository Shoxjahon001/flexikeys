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
  group('AacCategoryTile', () {
    testWidgets('renders label and glyph', (tester) async {
      await tester.pumpWidget(_wrap(AacCategoryTile(
        category: AacCategory.play,
        label: 'Play',
        glyph: const Text('🧸'),
        onTap: () {},
      )));
      expect(find.text('Play'), findsOneWidget);
      expect(find.text('🧸'), findsOneWidget);
    });

    testWidgets('tap calls onTap', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(_wrap(AacCategoryTile(
        category: AacCategory.play,
        label: 'Play',
        glyph: const Text('🧸'),
        onTap: () => tapped++,
      )));
      await tester.tap(find.byType(AacCategoryTile));
      await tester.pump();
      expect(tapped, 1);
    });

    testWidgets('highContrast adds a visible border', (tester) async {
      await tester.pumpWidget(_wrap(AacCategoryTile(
        category: AacCategory.play,
        label: 'Play',
        glyph: const Text('🧸'),
        highContrast: true,
        onTap: () {},
      )));
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
    });
  });
}
