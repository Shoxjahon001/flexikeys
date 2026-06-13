import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/cloud_mascot.dart';
import '../widgets/dot_indicator.dart';
import '../services/user_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  bool _nameActive = false;
  bool _ageActive = false;
  String _selectedLanguage = 'en';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _selectedLanguage = args['language'] as String? ?? 'en';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _onNext() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnack("Please enter kid's name");
      return;
    }
    if (_ageController.text.trim().isEmpty) {
      _showSnack("Please enter kid's age");
      return;
    }
    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text.trim()) ?? 5;
    await UserService.saveRegistration(
      name: name,
      age: age,
      language: _selectedLanguage,
    );
    if (!mounted) return;
    Navigator.pushNamed(
      context,
      '/welcome',
      arguments: {'name': name, 'age': age},
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.nunito()),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Container(
          decoration: appGradientBg,
          child: SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      const CloudMascot(size: 140),
                      const SizedBox(height: 20),
                      Text(
                        'Registration',
                        style: GoogleFonts.nunito(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'almost done',
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          color: AppTheme.textMedium,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Kid's name",
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textMedium,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _nameController,
                              hint: 'Name...',
                              isActive: _nameActive,
                              onFocusChange: (v) =>
                                  setState(() => _nameActive = v),
                              inputType: TextInputType.name,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              "Kid's age",
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textMedium,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _ageController,
                              hint: 'Age...',
                              isActive: _ageActive,
                              onFocusChange: (v) =>
                                  setState(() => _ageActive = v),
                              inputType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(2),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const DotIndicator(count: 3, current: 2),
                      const SizedBox(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: GestureDetector(
                          onTap: _onNext,
                          child: Container(
                            height: 68,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(34),
                            ),
                            child: Center(
                              child: Text(
                                'Next',
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
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool isActive,
    required Function(bool) onFocusChange,
    TextInputType? inputType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Focus(
      onFocusChange: onFocusChange,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.cardActive
              : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isActive
                ? AppTheme.primary
                : AppTheme.textDark.withValues(alpha: 0.15),
            width: isActive ? 2 : 1.5,
          ),
        ),
        child: TextField(
          controller: controller,
          keyboardType: inputType,
          inputFormatters: inputFormatters,
          style: GoogleFonts.nunito(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.nunito(
              fontSize: 17,
              color: AppTheme.textMedium.withValues(alpha: 0.5),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 18,
            ),
          ),
        ),
      ),
    );
  }
}
