import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flexikeys/l10n/app_localizations.dart';
import 'package:flexikeys/screens/language_screen.dart';
import 'package:flexikeys/screens/register_screen.dart';
import 'package:flexikeys/features/auth/presentation/login_screen.dart';
import 'package:flexikeys/features/auth/presentation/parent_signup_screen.dart';

Widget _app(Map<String, WidgetBuilder> routes) => ProviderScope(
      child: MaterialApp(
        initialRoute: '/language',
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routes: {
          '/language': (_) => const LanguageScreen(),
          ...routes,
        },
      ),
    );

void main() {
  testWidgets(
      'choosing a language now routes to parent signup, not the old register screen',
      (tester) async {
    await tester.pumpWidget(_app({
      '/parent_signup': (_) => const ParentSignupScreen(),
      '/register': (_) => const RegisterScreen(),
    }));

    await tester.tap(find.text('English'));
    // _selectLanguage highlights then navigates after a 300ms delay.
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.byType(ParentSignupScreen), findsOneWidget);
    expect(find.byType(RegisterScreen), findsNothing);
  });

  testWidgets(
      'parent signup rejects a short password without hitting the network',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ParentSignupScreen(),
      ),
    ));

    await tester.enterText(
        find.widgetWithText(TextField, 'Email').first, 'parent@example.com');
    await tester.enterText(
        find.widgetWithText(TextField, 'Password (min 8 characters)'), 'short');
    // FkButton only invokes onPressed after its tap-release scale animation
    // finishes, so settle rather than a single pump.
    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();

    expect(find.text('Password must be at least 8 characters'), findsOneWidget);
  });

  testWidgets('login screen renders email/password fields and a link to signup',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LoginScreen(),
      ),
    ));

    expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
    expect(find.text("Don't have an account? Sign up"), findsOneWidget);
  });

  testWidgets(
      'register screen legacy mode (linkToAccount unset) reaches welcome without any network call',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    // The registration column needs more height than the default 800x600
    // test surface to avoid a RenderFlex overflow that would swallow taps.
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const RegisterScreen(),
        routes: {
          '/welcome': (_) => const Scaffold(body: Text('welcome')),
        },
      ),
    ));

    await tester.enterText(find.widgetWithText(TextField, 'Name...'), 'Alex');
    await tester.enterText(find.widgetWithText(TextField, 'Age...'), '6');
    await tester.tap(find.text('Next'));
    await tester.pump(); // let the SharedPreferences await resolve
    // CloudMascot has a looping idle animation, so pump a bounded duration
    // instead of pumpAndSettle (which would never settle).
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('welcome'), findsOneWidget);
  });
}
