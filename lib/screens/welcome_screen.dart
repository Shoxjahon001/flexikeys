import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/cloud_mascot.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  String _name = '';

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _name = args['name'] as String? ?? '';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: appGradientBg,
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                children: [
                  const SizedBox(height: 48),

                  // Big greeting text
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _name.isNotEmpty
                          ? 'Hi! $_name\nlet\'s play\nwith letters!'
                          : 'Let\'s play\nwith letters!',
                      textAlign: TextAlign.left,
                      style: GoogleFonts.nunito(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark,
                        height: 1.15,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Cloud mascot
                  const CloudMascot(size: 200),

                  const Spacer(),

                  // Start button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(
                          context,
                          '/main',
                          arguments: {'name': _name},
                        );
                      },
                      child: Container(
                        height: 68,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(34),
                        ),
                        child: Center(
                          child: Text(
                            'Start',
                            style: GoogleFonts.nunito(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
