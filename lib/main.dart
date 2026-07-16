import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'design_system/fk_theme.dart';
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
    return MaterialApp(
      title: 'FlexiKeys',
      debugShowCheckedModeBanner: false,
      // FkTheme replaces the old AppTheme — design tokens are now canonical
      theme: FkTheme.themeData(),
      initialRoute: startRegistered ? '/main' : '/',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('uz'),
        Locale('ru'),
      ],
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
        '/transport_coloring_game': (context) => const TransportColoringScreen(),
      },
    );
  }
}