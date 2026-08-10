import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../design_system/design_system.dart';
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
    final t = AppLocalizations.of(context)!;
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.huge),

                // Big greeting text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
                  child: Text(
                    _name.isNotEmpty
                        ? t.greetingWithName(_name)
                        : t.greetingNoName,
                    textAlign: TextAlign.left,
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                ),

                const Spacer(),
                const CloudMascot(size: 320),
                const Spacer(),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                  child: FkPrimaryButton(
                    label: t.startButton,
                    fullWidth: true,
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                        context,
                        '/main',
                        arguments: {'name': _name},
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
