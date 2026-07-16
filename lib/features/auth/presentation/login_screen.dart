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
    final fk = FkTheme.of(context);
    final state = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: fk.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(FkSpacing.lg),
            child: FkCard(
              padding: const EdgeInsets.all(FkSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Welcome back', style: FkTextStyles.adultHeadline.copyWith(color: fk.ink)),
                  const SizedBox(height: FkSpacing.xs),
                  const Text(
                    'Log in to continue your child\'s progress.',
                    style: FkTextStyles.adultBody,
                  ),
                  const SizedBox(height: FkSpacing.md),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration(fk, 'Email'),
                  ),
                  const SizedBox(height: FkSpacing.sm),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration: _inputDecoration(fk, 'Password'),
                  ),
                  if (state.error != null) ...[
                    const SizedBox(height: FkSpacing.xs),
                    Text(state.error!, style: FkTextStyles.adultCaption.copyWith(color: fk.attention)),
                  ],
                  const SizedBox(height: FkSpacing.md),
                  FkButton(
                    label: 'Log in',
                    size: FkButtonSize.adult,
                    loading: state.loading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: FkSpacing.sm),
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/parent_signup'),
                    child: Text(
                      "Don't have an account? Sign up",
                      style: FkTextStyles.adultBody.copyWith(color: fk.ink),
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

  InputDecoration _inputDecoration(FkTheme fk, String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: fk.surface,
        border: const OutlineInputBorder(
          borderRadius: FkRadii.mdAll,
          borderSide: BorderSide.none,
        ),
      );
}
