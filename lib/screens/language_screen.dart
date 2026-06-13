import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
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

  final List<Map<String, String>> _languages = [
    {'flag': '🇺🇸', 'name': 'English', 'code': 'en'},
    {'flag': '🇷🇺', 'name': 'Русский', 'code': 'ru'},
    {'flag': '🇺🇿', 'name': 'Ōzbek', 'code': 'uz'},
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
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        Navigator.pushNamed(context, '/register',
            arguments: {'language': code});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: appGradientBg,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 32),
              // Smaller cloud on this screen
              const CloudMascot(size: 140),
              const SizedBox(height: 24),

              // Title
              Text(
                'Choose Your Language',
                style: GoogleFonts.nunito(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Select language to start',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  color: AppTheme.textMedium,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 36),

              // Language buttons
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
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
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GestureDetector(
                          onTap: () => _selectLanguage(lang['code']!),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 70,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.cardActive
                                  : Colors.white.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(35),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primary
                                    : AppTheme.textDark.withValues(alpha: 0.15),
                                width: isSelected ? 2 : 1.5,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.primary.withValues(alpha: 0.2),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      )
                                    ]
                                  : [],
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 24),
                                Text(
                                  lang['flag']!,
                                  style: const TextStyle(fontSize: 32),
                                ),
                                const SizedBox(width: 20),
                                Text(
                                  lang['name']!,
                                  style: GoogleFonts.nunito(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                const Spacer(),
                                if (isSelected)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 20),
                                    child: Icon(
                                      Icons.check_circle_rounded,
                                      color: AppTheme.primary,
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
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
