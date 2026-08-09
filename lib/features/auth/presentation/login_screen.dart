import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../design_system/design_system.dart';
import '../application/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) return;

    final ok = await ref.read(authControllerProvider.notifier).login(email, password);
    if (ok && mounted) {
      Navigator.pushReplacementNamed(context, '/child_picker');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

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
                  const Text('Welcome back', style: AppTypography.h2),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Log in to continue your child\'s progress.',
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
                    decoration: _inputDecoration('Password'),
                  ),
                  if (state.error != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    // Real adult-facing error, not child failure-framing —
                    // see FkParentGate for the same reasoning.
                    Text(state.error!,
                        style: AppTypography.caption
                            .copyWith(color: AppColors.danger)),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                  FkButton(
                    label: 'Log in',
                    size: FkButtonSize.adult,
                    loading: state.loading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/parent_signup'),
                    child: Text(
                      "Don't have an account? Sign up",
                      style: AppTypography.body.copyWith(color: AppColors.textPrimary),
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
