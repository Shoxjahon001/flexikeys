import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../design_system/design_system.dart';
import '../application/auth_controller.dart';
import '../domain/auth_models.dart';

/// "Who is playing today?" — large avatar cards, one per child, plus an
/// "add child" tile. Child-facing screen: pastel, large targets, no text
/// entry required from the child.
class ChildPickerScreen extends ConsumerWidget {
  const ChildPickerScreen({super.key});

  Future<void> _select(BuildContext context, WidgetRef ref, ChildProfile child) async {
    final ok = await ref.read(authControllerProvider.notifier).selectChild(child);
    if (ok && context.mounted) {
      Navigator.pushReplacementNamed(context, '/welcome', arguments: {'name': child.displayName});
    }
  }

  void _addChild(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    Navigator.pushNamed(context, '/register', arguments: {
      'linkToAccount': true,
      if (args?['language'] != null) 'language': args!['language'],
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Who is playing today?', style: AppTypography.h1),
              const SizedBox(height: AppSpacing.xxl),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.xxl,
                  crossAxisSpacing: AppSpacing.xxl,
                  children: [
                    for (final child in state.children)
                      _ChildTile(
                        child: child,
                        onTap: () => _select(context, ref, child),
                      ),
                    _AddChildTile(onTap: () => _addChild(context)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChildTile extends StatelessWidget {
  final ChildProfile child;
  final VoidCallback onTap;

  const _ChildTile({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FkCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FkAvatar(name: child.displayName, size: 72),
          const SizedBox(height: AppSpacing.sm),
          Text(
            child.displayName,
            style: AppTypography.h2,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AddChildTile extends StatelessWidget {
  final VoidCallback onTap;

  const _AddChildTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FkCard(
      onTap: onTap,
      color: AppColors.surface.withValues(alpha: 0.6),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_circle_rounded, size: 56, color: AppColors.primary),
          SizedBox(height: AppSpacing.sm),
          Text('Add child', style: AppTypography.h2),
        ],
      ),
    );
  }
}
