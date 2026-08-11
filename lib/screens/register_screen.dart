import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../design_system/design_system.dart';
import '../widgets/cloud_mascot.dart';
import '../widgets/dot_indicator.dart';
import '../services/user_service.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/domain/auth_models.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String _selectedLanguage = 'en';
  // When true, this "kid's name + age" step also creates a real backend
  // child profile (reached from the child picker's "add child" tile).
  // When false, it only writes the local single-child profile (legacy path
  // for installs that predate backend accounts).
  bool _linkToAccount = false;
  bool _submitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _selectedLanguage = args['language'] as String? ?? _selectedLanguage;
      _linkToAccount = args['linkToAccount'] as bool? ?? _linkToAccount;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _onNext() async {
    final t = AppLocalizations.of(context)!;
    if (_nameController.text.trim().isEmpty) {
      _showSnack(t.nameRequiredError);
      return;
    }
    if (_ageController.text.trim().isEmpty) {
      _showSnack(t.ageRequiredError);
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

    if (_linkToAccount) {
      setState(() => _submitting = true);
      final controller = ref.read(authControllerProvider.notifier);
      final child = await controller.createChild(ChildCreateData(
        displayName: name,
        learningLanguage: _selectedLanguage,
        uiLanguage: _selectedLanguage,
        birthYear: DateTime.now().year - age,
      ));
      if (!mounted) return;
      setState(() => _submitting = false);
      if (child == null) {
        _showSnack(t.profileCreateError);
        return;
      }
      await controller.selectChild(child);
      if (!mounted) return;
    }

    Navigator.pushNamed(
      context,
      '/welcome',
      arguments: {'name': name, 'age': age},
    );
  }

  void _showSnack(String msg) => FkToast.show(context, msg, type: FkToastType.error);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: colors.background,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
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
                    const SizedBox(height: AppSpacing.xxxl),
                    const CloudMascot(size: 220),
                    const SizedBox(height: AppSpacing.xl),
                    Text(t.registrationTitle, style: textTheme.headlineLarge),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      t.almostDoneSubtitle,
                      style:
                          textTheme.bodyLarge?.copyWith(color: colors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.huge),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FkTextField(
                            labelText: t.kidNameLabel,
                            hintText: t.kidNameHint,
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          FkTextField(
                            labelText: t.kidAgeLabel,
                            hintText: t.kidAgeHint,
                            controller: _ageController,
                            keyboardType: TextInputType.number,
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
                    const SizedBox(height: AppSpacing.xxxl),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                      child: FkPrimaryButton(
                        label: t.nextButton,
                        fullWidth: true,
                        loading: _submitting,
                        onPressed: _submitting ? null : _onNext,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
