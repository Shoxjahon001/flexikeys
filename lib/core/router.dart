library fk_router;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/language_screen.dart';
import '../screens/register_screen.dart';
import '../screens/welcome_screen.dart';
import '../screens/main_shell.dart';
import '../screens/dev/design_gallery_screen.dart';
import '../screens/game/letters_stage1_screen.dart';
import '../screens/game/letters_stage2_screen.dart';
import '../screens/game/generic_game_screen.dart';
import '../screens/game/good_job_screen.dart';
import '../screens/game/level_complete_screen.dart';
import '../screens/game/shapes_screen.dart';
import '../screens/game/letter_drawing_screen.dart';

/// Child shell — home world-map → level → lesson player.
/// Parent and teacher shells are role-gated (Phase 03 auth, extended in Phase 07+).
///
/// Transitions: soft fade+slide (no hard cuts per design spec).
GoRouter buildRouter({required bool startRegistered}) {
  return GoRouter(
    initialLocation: startRegistered ? '/home' : '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => _fade(state, const SplashScreen()),
      ),
      GoRoute(
        path: '/language',
        pageBuilder: (context, state) => _slide(state, const LanguageScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => _slide(state, const RegisterScreen()),
      ),
      GoRoute(
        path: '/welcome',
        pageBuilder: (context, state) => _slide(state, const WelcomeScreen()),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShellWrapper(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => _fade(state, const MainShell()),
          ),
        ],
      ),
      // Game routes — keep existing materialRoutes for compatibility during migration
      GoRoute(
        path: '/game_stage1',
        pageBuilder: (context, state) => _slide(state, const LettersStage1Screen()),
      ),
      GoRoute(
        path: '/game_stage2',
        pageBuilder: (context, state) => _slide(state, const LettersStage2Screen()),
      ),
      GoRoute(
        path: '/generic_game',
        pageBuilder: (context, state) => _slide(state, const GenericGameScreen()),
      ),
      GoRoute(
        path: '/good_job',
        pageBuilder: (context, state) => _slide(state, const GoodJobScreen()),
      ),
      GoRoute(
        path: '/level_complete',
        pageBuilder: (context, state) => _slide(state, const LevelCompleteScreen()),
      ),
      GoRoute(
        path: '/shapes_game',
        pageBuilder: (context, state) => _slide(state, const ShapesScreen()),
      ),
      GoRoute(
        path: '/letter_drawing_game',
        pageBuilder: (context, state) => _slide(state, const LetterDrawingScreen()),
      ),
      // Dev-only visual QA surface (light/dark component preview) — never
      // registered in release builds, and not linked from any in-app nav.
      if (kDebugMode)
        GoRoute(
          path: '/design-gallery',
          pageBuilder: (context, state) => _fade(state, const DesignGalleryScreen()),
        ),
    ],
  );
}

/// Soft fade transition — no hard cuts.
CustomTransitionPage<void> _fade(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, _, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        child: child,
      );
    },
  );
}

/// Soft fade+slide transition.
CustomTransitionPage<void> _slide(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, _, child) {
      final slide = Tween<Offset>(
        begin: const Offset(0.05, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}

/// Thin wrapper that provides MainShell's scaffold with the ShellRoute child.
class MainShellWrapper extends StatelessWidget {
  final Widget child;
  const MainShellWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}