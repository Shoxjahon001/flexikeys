import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../design_system/design_system.dart';
import '../widgets/cloud_mascot.dart';
import '../widgets/dot_indicator.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnim;
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Stack(
          children: [
            FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    const Center(child: CloudMascot(size: 320)),
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      'FlexiKeys',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      t.splashTagline,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(color: colors.primary),
                    ),
                    const Spacer(),
                    const DotIndicator(count: 3, current: 0),
                    const SizedBox(height: 90),
                  ],
                ),
              ),
            ),

            // Bottom Go! button
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: FkPrimaryButton(
                  label: t.goButton,
                  fullWidth: true,
                  leadingIcon: const Icon(Icons.play_circle_filled_rounded),
                  onPressed: () => Navigator.pushNamed(context, '/language'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
