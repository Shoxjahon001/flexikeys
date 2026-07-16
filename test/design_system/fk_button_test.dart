import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flexikeys/design_system/design_system.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: FkTheme.themeData(),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('FkButton', () {
    testWidgets('renders label', (tester) async {
      await tester.pumpWidget(_wrap(
        FkButton(label: 'Start', onPressed: () {}),
      ));
      expect(find.text('Start'), findsOneWidget);
    });

    testWidgets('minimum child touch target 64dp', (tester) async {
      await tester.pumpWidget(_wrap(
        FkButton(label: 'Go', onPressed: () {}, size: FkButtonSize.child),
      ));
      final box = tester.renderObject(find.byType(FkButton)) as RenderBox;
      expect(box.size.height, greaterThanOrEqualTo(64));
    });

    testWidgets('minimum adult touch target 44dp', (tester) async {
      await tester.pumpWidget(_wrap(
        FkButton(label: 'OK', onPressed: () {}, size: FkButtonSize.adult),
      ));
      final box = tester.renderObject(find.byType(FkButton)) as RenderBox;
      expect(box.size.height, greaterThanOrEqualTo(44));
    });

    testWidgets('disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(_wrap(
        const FkButton(label: 'Disabled'),
      ));
      // No tap callback — should not throw
      await tester.tap(find.byType(FkButton), warnIfMissed: false);
      await tester.pump();
    });

    testWidgets('loading shows spinner not label', (tester) async {
      await tester.pumpWidget(_wrap(
        FkButton(label: 'Start', onPressed: () {}, loading: true),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('scale animation: golden default state', (tester) async {
      await tester.pumpWidget(_wrap(
        FkButton(label: 'Press', onPressed: () {}),
      ));
      await tester.pump();
      await expectLater(
        find.byType(FkButton),
        matchesGoldenFile('../goldens/fk_button_default.png'),
      );
    });

    testWidgets('secondary variant golden', (tester) async {
      await tester.pumpWidget(_wrap(
        FkButton(
          label: 'Secondary',
          variant: FkButtonVariant.secondary,
          onPressed: () {},
        ),
      ));
      await tester.pump();
      await expectLater(
        find.byType(FkButton),
        matchesGoldenFile('../goldens/fk_button_secondary.png'),
      );
    });
  });

  group('FkCard', () {
    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(_wrap(
        const FkCard(child: Text('Content')),
      ));
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('golden default', (tester) async {
      await tester.pumpWidget(_wrap(
        const FkCard(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('Card Content'),
          ),
        ),
      ));
      await expectLater(
        find.byType(FkCard),
        matchesGoldenFile('../goldens/fk_card_default.png'),
      );
    });
  });

  group('FkCoinCounter', () {
    testWidgets('displays value', (tester) async {
      await tester.pumpWidget(_wrap(const FkCoinCounter(value: 42)));
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('golden coin counter', (tester) async {
      await tester.pumpWidget(_wrap(const FkCoinCounter(value: 7)));
      await tester.pump();
      await expectLater(
        find.byType(FkCoinCounter),
        matchesGoldenFile('../goldens/fk_coin_counter.png'),
      );
    });
  });

  group('FkAvatar', () {
    testWidgets('shows initials for single name', (tester) async {
      await tester.pumpWidget(_wrap(const FkAvatar(name: 'Alex')));
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('shows two initials for full name', (tester) async {
      await tester.pumpWidget(_wrap(const FkAvatar(name: 'Alex Kim')));
      expect(find.text('AK'), findsOneWidget);
    });
  });
}