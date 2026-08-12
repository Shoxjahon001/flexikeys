import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flexikeys/design_system/design_system.dart';
import 'package:flexikeys/features/aac/data/aac_card_repository.dart';
import 'package:flexikeys/features/aac/data/aac_custom_card_store.dart';
import 'package:flexikeys/features/aac/data/aac_milestones_store.dart';
import 'package:flexikeys/features/aac/data/aac_settings_store.dart';
import 'package:flexikeys/features/aac/domain/aac_card_def.dart';
import 'package:flexikeys/features/aac/presentation/aac_sentence_strip_screen.dart';
import 'package:flexikeys/l10n/app_localizations.dart';

/// path_provider has no default test mock either — same "hangs forever
/// with no registered handler" issue as flutter_secure_storage, hit here
/// via TtsService.init()'s getApplicationCacheDirectory() call (the speak
/// flow's TTS fallback, since no bundled audio exists for ad-hoc Sentence
/// Strip word sequences).
class _FakePathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationCachePath() async => '.';
  @override
  Future<String?> getApplicationDocumentsPath() async => '.';
  @override
  Future<String?> getApplicationSupportPath() async => '.';
  @override
  Future<String?> getTemporaryPath() async => '.';
}

// AacCard's idle animation loops forever, so pumpAndSettle() would hang on
// this screen — bounded pumps are used instead.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

const _secureStorageChannel =
    MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AacSettingsStore.instance.resetCacheForTesting();
    AacCustomCardStore.instance.resetCacheForTesting();
    AacMilestonesStore.instance.resetCacheForTesting();

    // flutter_secure_storage has no default test mock — unlike plugins
    // that throw MissingPluginException quickly when unregistered, calls
    // through this channel hang forever with no handler, silently stalling
    // any code path that touches SecureTokenStore (here: the Sentence
    // Strip's speak flow calls AacSentenceComposerService.compose(), which
    // starts with a getActiveChildId() lookup). Returning null for every
    // method matches "no active child session" — the real fallback path.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureStorageChannel, (call) async => null);
    PathProviderPlatform.instance = _FakePathProviderPlatform();
  });

  Future<List<AacCardDef>> loadNeedsCards() async {
    final all = await AacCardRepository.instance.loadStarterVocabulary();
    return all.where((c) => c.category == AacCategory.needs).toList();
  }

  group('AacSentenceStripScreen', () {
    testWidgets('excludes branch cards from the tappable grid', (tester) async {
      final cards = await loadNeedsCards();
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AacSentenceStripScreen(
          category: AacCategory.needs,
          categoryLabel: 'Needs',
          cards: cards,
        ),
      ));
      await _settle(tester);

      // "Food" (ne_food) is a branch card — picking it here can't map to a
      // single word, so it must not appear as a tappable strip-building card.
      expect(find.text('Food'), findsNothing);
      expect(find.text('Water'), findsOneWidget);
    });

    testWidgets('tapping direct cards appends words to the strip, in order', (tester) async {
      final cards = await loadNeedsCards();
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AacSentenceStripScreen(
          category: AacCategory.needs,
          categoryLabel: 'Needs',
          cards: cards,
        ),
      ));
      await _settle(tester);

      await tester.tap(find.text('Water'));
      await tester.pump();
      await tester.tap(find.text('Help'));
      await tester.pump();

      expect(find.byType(SentenceStrip), findsOneWidget);
      final strip = tester.widget<SentenceStrip>(find.byType(SentenceStrip));
      expect(strip.entries.map((e) => e.word).toList(), ['Water', 'Help']);
    });

    testWidgets('clear empties the strip', (tester) async {
      final cards = await loadNeedsCards();
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AacSentenceStripScreen(
          category: AacCategory.needs,
          categoryLabel: 'Needs',
          cards: cards,
        ),
      ));
      await _settle(tester);

      await tester.tap(find.text('Water'));
      await tester.pump();

      await tester.tap(find.widgetWithIcon(IconButton, Icons.backspace_rounded));
      await tester.pump();

      final strip = tester.widget<SentenceStrip>(find.byType(SentenceStrip));
      expect(strip.entries, isEmpty);
    });

    // The full multi-word-speak-triggers-celebration path requires driving
    // AacAudioPlayer's TTS fallback (a real HttpClient request, intercepted
    // by Flutter's test HttpOverrides but still genuine async I/O) to
    // completion, which plain pump()/runAsync() combinations proved
    // unreliable to land deterministically here. The milestone bookkeeping
    // itself (mark-once, persists) is covered directly and reliably by
    // aac_milestones_store_test.dart; this test instead confirms the
    // celebration overlay is actually wired into the screen and starts
    // inactive, which is what a regression here would most likely break.
    testWidgets('renders an inactive celebration overlay by default', (tester) async {
      final cards = await loadNeedsCards();
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AacSentenceStripScreen(
          category: AacCategory.needs,
          categoryLabel: 'Needs',
          cards: cards,
        ),
      ));
      await _settle(tester);

      final starBurst = tester.widget<FkStarBurst>(find.byType(FkStarBurst));
      expect(starBurst.active, isFalse);
    });
  });
}
