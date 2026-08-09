import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flexikeys/design_system/aac/aac_theme.dart';
import 'package:flexikeys/features/aac/domain/aac_card_def.dart';
import 'package:flexikeys/features/aac/presentation/aac_glyphs.dart';
import 'package:flexikeys/l10n/app_localizations.dart';

AacCardDef _card({String? customPhotoPath}) => AacCardDef(
      id: 'ne_water',
      category: AacCategory.needs,
      kind: AacCardKind.direct,
      label: const {AacLanguage.en: 'Water'},
      sentenceTemplate: const {AacLanguage.en: 'I want water.'},
      animationAsset: '',
      audioAsset: const {},
      customPhotoPath: customPhotoPath,
      difficultyTier: 1,
    );

void main() {
  group('glyphForCard', () {
    testWidgets('returns the emoji glyph when there is no custom photo', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: glyphForCard(_card()),
      ));
      expect(find.text('💧'), findsOneWidget); // ne_water's mapped emoji
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('returns an Image.file when a custom photo path is set', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: glyphForCard(_card(customPhotoPath: '/tmp/does-not-exist.jpg')),
        ),
      );
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('💧'), findsNothing);
    });
  });
}
