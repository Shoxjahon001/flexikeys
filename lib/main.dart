import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/language_screen.dart';
import 'screens/register_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/main_shell.dart';
import 'screens/game/letters_stage1_screen.dart';
import 'screens/game/letters_stage2_screen.dart';
import 'screens/game/generic_game_screen.dart';
import 'screens/game/good_job_screen.dart';
import 'screens/game/level_complete_screen.dart';
import 'services/user_service.dart';
import 'services/tts_service.dart';

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
  unawaited(TtsService.instance.init().catchError((_) {}));
  runApp(FlexiKeysApp(startRegistered: registered));
}

class FlexiKeysApp extends StatelessWidget {
  final bool startRegistered;
  const FlexiKeysApp({super.key, required this.startRegistered});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlexiKeys',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: startRegistered ? '/main' : '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/language': (context) => const LanguageScreen(),
        '/register': (context) => const RegisterScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/main': (context) => const MainShell(),
        '/game_stage1': (context) => const LettersStage1Screen(),
        '/game_stage2': (context) => const LettersStage2Screen(),
        '/generic_game': (context) => const GenericGameScreen(),
        '/good_job': (context) => const GoodJobScreen(),
        '/level_complete': (context) => const LevelCompleteScreen(),
      },
    );
  }
}
