import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/user_service.dart';
import '../design_system/design_system.dart';
import '../widgets/cloud_mascot.dart';
import '../widgets/dot_indicator.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen>
    with SingleTickerProviderStateMixin {
  String? _selected;
  late AnimationController _animController;

  // Each language's own native name (autonym) — shown as-is regardless of
  // the currently active interface language, so a speaker of any of the
  // three can always recognize their own language in this picker.
  final List<Map<String, String>> _languages = [
    {'flag': '🇺🇸', 'name': 'English', 'code': 'en'},
    {'flag': '🇷🇺', 'name': 'Русский', 'code': 'ru'},
    {'flag': '🇺🇿', 'name': "O'zbek", 'code': 'uz'},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _selectLanguage(String code) {
    setState(() => _selected = code);
    // Flips the interface language live — the rest of onboarding
    // (RegisterScreen, ParentSignupScreen) renders in it immediately. This
    // is a separate, one-time default for the child's learning language
    // too (see UserService.saveRegistration), but the two stay
    // independently changeable afterward.
    UserService.setUiLanguage(code);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        Navigator.pushNamed(context, '/parent_signup',
            arguments: {'language': code});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xxxl),
            // Smaller cloud on this screen
            const CloudMascot(size: 220),
            const SizedBox(height: AppSpacing.xxl),

            // Title
            Text(
              t.chooseLanguageTitle,
              style: textTheme.headlineLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              t.chooseLanguageSubtitle,
              style: textTheme.bodyLarge?.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxxl),

            // Language buttons
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _languages.length,
                itemBuilder: (context, index) {
                  final lang = _languages[index];
                  final isSelected = _selected == lang['code'];

                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 400 + index * 100),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: GestureDetector(
                        onTap: () => _selectLanguage(lang['code']!),
                        child: AnimatedContainer(
                          duration: AppMotion.fast,
                          curve: AppMotion.transition,
                          height: 70,
                          decoration: BoxDecoration(
                            color: isSelected ? colors.primarySoft : colors.surface,
                            borderRadius: AppRadius.pillAll,
                            border: Border.all(
                              color: isSelected ? colors.primary : colors.border,
                              width: isSelected ? 2 : 1.5,
                            ),
                            boxShadow: isSelected ? AppShadows.soft : null,
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: AppSpacing.xxl),
                              Text(
                                lang['flag']!,
                                style: const TextStyle(fontSize: 32),
                              ),
                              const SizedBox(width: AppSpacing.lg),
                              Text(lang['name']!,
                                  style: textTheme.headlineSmall
                                      ?.copyWith(color: colors.textPrimary)),
                              const Spacer(),
                              if (isSelected)
                                Padding(
                                  padding: const EdgeInsets.only(right: AppSpacing.xl),
                                  child: Icon(
                                    Icons.check_circle_rounded,
                                    color: colors.primary,
                                    size: 26,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const DotIndicator(count: 3, current: 1),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }
}
