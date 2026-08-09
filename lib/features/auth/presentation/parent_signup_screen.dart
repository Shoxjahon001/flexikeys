import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../design_system/design_system.dart';
import '../../../services/user_service.dart';
import '../application/auth_controller.dart';
import '../domain/auth_models.dart';

class ParentSignupScreen extends ConsumerStatefulWidget {
  const ParentSignupScreen({super.key});

  @override
  ConsumerState<ParentSignupScreen> createState() => _ParentSignupScreenState();
}

class _ParentSignupScreenState extends ConsumerState<ParentSignupScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _localError;
  String? _language;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _language = args?['language'] as String? ?? _language;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) return;
    if (password.length < 8) {
      setState(() => _localError = 'Password must be at least 8 characters');
      return;
    }
    if (password != _confirmCtrl.text) {
      setState(() => _localError = 'Passwords do not match');
      return;
    }
    setState(() => _localError = null);

    final controller = ref.read(authControllerProvider.notifier);
    final ok = await controller.register(email, password, locale: _language ?? 'en');
    if (!ok || !mounted) return;

    // If this device already has a local guest profile (child played
    // offline before this account existed), adopt it as the account's
    // child instead of sending the parent to an empty picker — the guest's
    // accumulated progress is already queued locally and gets pushed by
    // the sync that selectChild() triggers.
    if (await UserService.isRegistered()) {
      final name = await UserService.getName();
      final age = await UserService.getAge();
      final language = await UserService.getLanguage();
      final child = await controller.createChild(ChildCreateData(
        displayName: name,
        learningLanguage: language,
        uiLanguage: language,
        birthYear: DateTime.now().year - age,
      ));
      if (child != null && mounted) {
        await controller.selectChild(child);
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/main', arguments: {'name': name});
        }
        return;
      }
    }

    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        '/child_picker',
        arguments: {'language': _language},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final error = _localError ?? state.error;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxxl),
            child: FkCard(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Create your account', style: AppTypography.h2),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    "We'll set up your child's profile next.",
                    style: AppTypography.body,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration('Email'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration: _inputDecoration('Password (min 8 characters)'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _confirmCtrl,
                    obscureText: true,
                    decoration: _inputDecoration('Confirm password'),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    // Real adult-facing error, not child failure-framing —
                    // see FkParentGate for the same reasoning.
                    Text(error,
                        style: AppTypography.caption
                            .copyWith(color: AppColors.danger)),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                  FkButton(
                    label: 'Sign up',
                    size: FkButtonSize.adult,
                    loading: state.loading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                    child: Text(
                      'Already have an account? Log in',
                      style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(
                      context,
                      '/register',
                      arguments: {'language': _language},
                    ),
                    child: Text(
                      'Continue without an account',
                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.surfaceMuted,
        border: const OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide.none,
        ),
      );
}
