import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'design_system/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'screens/splash_screen.dart';
import 'screens/language_screen.dart';
import 'screens/register_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/main_shell.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/parent_signup_screen.dart';
import 'features/auth/presentation/child_picker_screen.dart';
import 'screens/game/letters_stage1_screen.dart';
import 'screens/game/letters_stage2_screen.dart';
import 'screens/game/letters_group_picker_screen.dart';
import 'screens/game/generic_game_screen.dart';
import 'screens/game/good_job_screen.dart';
import 'screens/game/level_complete_screen.dart';
import 'screens/game/shapes_screen.dart';
import 'screens/game/letter_drawing_screen.dart';
import 'screens/game/letter_groups_screen.dart';
import 'screens/game/number_drawing_screen.dart';
import 'screens/game/object_drawing_screen.dart';
import 'screens/game/fruits_coloring_screen.dart';
import 'screens/game/animals_coloring_screen.dart';
import 'screens/game/nature_coloring_screen.dart';
import 'screens/game/transport_coloring_screen.dart';
import 'features/aac/presentation/aac_home_screen.dart';
import 'services/user_service.dart';
import 'services/tts_service.dart';
import 'services/sound_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  final registered = await UserService.isRegistered();
  await UserService.loadNotifiers();
  unawaited(TtsService.instance.init().catchError((_) {}));
  unawaited(SoundService.instance.init().catchError((_) {}));

  runApp(
    // ProviderScope makes all Riverpod providers available (mascot, adaptive state, etc.)
    ProviderScope(
      child: FlexiKeysApp(startRegistered: registered),
    ),
  );
}

class FlexiKeysApp extends StatelessWidget {
  final bool startRegistered;
  const FlexiKeysApp({super.key, required this.startRegistered});

  @override
  Widget build(BuildContext context) {
    // Rebuilds MaterialApp's locale immediately when the interface language
    // changes — from the onboarding picker or the parent dashboard's
    // Display Language setting — same ValueNotifier pattern UserService
    // already uses for starsNotifier/avatarNotifier. This is deliberately
    // separate from the child's learning language (UserService.getLanguage/
    // setLearningLanguage), which drives curriculum/AAC content, not chrome.
    return ValueListenableBuilder<String>(
      valueListenable: UserService.uiLanguageNotifier,
      builder: (context, uiLanguage, _) => MaterialApp(
        title: 'FlexiKeys',
        debugShowCheckedModeBanner: false,
        // FlexiKeysTheme.dark() exists (see design_system/theme/app_theme.dart)
        // but isn't wired as `darkTheme:`/`themeMode:` yet — most screens
        // still read AppColors.* as flat light-mode constants rather than
        // through Theme.of(context), so toggling dark mode wouldn't
        // actually cascade through the app yet. Wiring it live is deferred
        // to whichever later phase makes every screen theme-driven.
        theme: FlexiKeysTheme.light(),
        initialRoute: startRegistered ? '/main' : '/',
        locale: Locale(uiLanguage),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routes: {
          '/': (context) => const SplashScreen(),
          '/language': (context) => const LanguageScreen(),
          '/register': (context) => const RegisterScreen(),
          '/welcome': (context) => const WelcomeScreen(),
          '/main': (context) => const MainShell(),
          '/login': (context) => const LoginScreen(),
          '/parent_signup': (context) => const ParentSignupScreen(),
          '/child_picker': (context) => const ChildPickerScreen(),
          '/game_stage1': (context) => const LettersStage1Screen(),
          '/game_stage2': (context) => const LettersStage2Screen(),
          '/letters_group_picker': (context) =>
              const LettersGroupPickerScreen(),
          '/generic_game': (context) => const GenericGameScreen(),
          '/good_job': (context) => const GoodJobScreen(),
          '/level_complete': (context) => const LevelCompleteScreen(),
          '/shapes_game': (context) => const ShapesScreen(),
          '/letter_drawing_game': (context) => const LetterDrawingScreen(),
          '/letter_groups': (context) => const LetterGroupsScreen(),
          '/number_drawing_game': (context) => const NumberDrawingScreen(),
          '/object_drawing_game': (context) => const ObjectDrawingScreen(),
          '/fruits_coloring_game': (context) => const FruitsColoringScreen(),
          '/animals_coloring_game': (context) => const AnimalsColoringScreen(),
          '/nature_coloring_game': (context) => const NatureColoringScreen(),
          '/transport_coloring_game': (context) =>
              const TransportColoringScreen(),
          // "My Voice" AAC module — reachable from LevelsScreen's top tab
          // switcher (levels_screen.dart); kept as a named route too so it
          // stays directly deep-linkable for QA.
          '/aac_home': (context) => const AacHomeScreen(),
        },
      ),
    );
  }
}
