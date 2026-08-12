import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flexikeys/design_system/design_system.dart';
import 'package:flexikeys/features/aac/domain/aac_card_def.dart';
import 'package:flexikeys/features/aac/presentation/aac_confirmation_screen.dart';
import 'package:flexikeys/l10n/app_localizations.dart';

// AacConfirmationScreen's loop animation repeats forever, so pumpAndSettle()
// would hang here — bounded pumps are used instead.
Future<void> _settle(WidgetTester tester, {int steps = 6, int msPerStep = 60}) async {
  for (var i = 0; i < steps; i++) {
    await tester.pump(Duration(milliseconds: msPerStep));
  }
}

/// Same fakes as aac_sentence_strip_screen_test.dart, needed here for the
/// same reason: with bundledAudioAsset null, AacAudioPlayer now tries
/// AacNeuralTtsService before falling back to TtsService, which touches
/// both path_provider (disk cache dir) and — via ApiClient's child-session
/// auth — flutter_secure_storage (reads the child token). Neither has a
/// default test mock; unlike plugins that throw MissingPluginException
/// quickly, calls through these channels hang forever with no handler.
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

const _secureStorageChannel =
    MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

Widget _hostThatOpensConfirmation() {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AacConfirmationScreen(
                  category: AacCategory.needs,
                  glyph: Text('💧'),
                  sentence: 'I want water.',
                  bundledAudioAsset: null,
                  language: AacLanguage.en,
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureStorageChannel, (call) async => null);
    PathProviderPlatform.instance = _FakePathProviderPlatform();
  });

  group('AacConfirmationScreen', () {
    testWidgets('shows the sentence text and a replay + close control', (tester) async {
      await tester.pumpWidget(_hostThatOpensConfirmation());
      await tester.tap(find.text('open'));
      await _settle(tester);

      expect(find.byType(AacConfirmationScreen), findsOneWidget);
      expect(find.text('I want water.'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('close button pops back', (tester) async {
      await tester.pumpWidget(_hostThatOpensConfirmation());
      await tester.tap(find.text('open'));
      await _settle(tester);
      expect(find.byType(AacConfirmationScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await _settle(tester, steps: 10, msPerStep: 60);

      expect(find.byType(AacConfirmationScreen), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('auto-dismisses after the spoken sentence finishes', (tester) async {
      await tester.pumpWidget(_hostThatOpensConfirmation());
      await tester.tap(find.text('open'));
      await _settle(tester);
      expect(find.byType(AacConfirmationScreen), findsOneWidget);

      // Past the 2-second post-speech auto-dismiss delay.
      await _settle(tester, steps: 6, msPerStep: 500);

      expect(find.byType(AacConfirmationScreen), findsNothing);
    });
  });
}
