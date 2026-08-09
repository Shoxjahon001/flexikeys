import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flexikeys/screens/dev/design_gallery_screen.dart';
import 'package:flexikeys/l10n/app_localizations.dart';

void main() {
  testWidgets('DesignGalleryScreen renders light and toggles to dark without error', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: DesignGalleryScreen(),
    ));
    // FkAudioButton runs an infinitely-repeating pulse animation, so
    // pumpAndSettle() would time out — pump a few fixed frames instead.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Dark'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });
}
