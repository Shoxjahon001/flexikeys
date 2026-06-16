import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cloud_mascot.dart';

class LevelCompleteScreen extends StatefulWidget {
  const LevelCompleteScreen({super.key});

  @override
  State<LevelCompleteScreen> createState() => _LevelCompleteScreenState();
}

class _LevelCompleteScreenState extends State<LevelCompleteScreen>
    with TickerProviderStateMixin {
  late AnimationController _cloudCtrl;
  late Animation<double> _cloudScale;
  late AnimationController _starsCtrl;
  late Animation<double> _starsFade;
  late Animation<Offset> _starsSlide;
  int _starsEarned = 10;

  @override
  void initState() {
    super.initState();
    _cloudCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _cloudScale = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _cloudCtrl, curve: Curves.elasticOut));

    _starsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _starsFade = CurvedAnimation(parent: _starsCtrl, curve: Curves.easeOut);
    _starsSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _starsCtrl, curve: Curves.easeOut));

    _cloudCtrl.forward();
    Future.delayed(const Duration(milliseconds: 500),
        () => _starsCtrl.forward());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _starsEarned = args['starsEarned'] as int? ?? 10;
    }
  }

  @override
  void dispose() {
    _cloudCtrl.dispose();
    _starsCtrl.dispose();
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
          child: Column(
            children: [
              const SizedBox(height: 48),
              Text(
                'You did it!',
                style: GoogleFonts.nunito(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 32),
              ScaleTransition(
                scale: _cloudScale,
                child: const CloudMascot(size: 340, animate: true),
              ),
              const Spacer(),
              FadeTransition(
                opacity: _starsFade,
                child: SlideTransition(
                  position: _starsSlide,
                  child: Text(
                    '+$_starsEarned⭐',
                    style: GoogleFonts.nunito(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/main', (r) => false);
                  },
                  child: Container(
                    height: 68,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.buttonBlue,
                      borderRadius: BorderRadius.circular(34),
                    ),
                    child: Center(
                      child: Text(
                        'Okay',
                        style: GoogleFonts.nunito(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
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
    );
  }
}
