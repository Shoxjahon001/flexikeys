library fk_step_container;

import 'package:flutter/material.dart';

import '../tokens/app_color_theme.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';

/// Numbered step block for multi-step forms (e.g. Create Card): muted
/// surface, badge with the step number, title, slot for the step's content.
class FkStepContainer extends StatelessWidget {
  final int stepNumber;
  final String title;
  final Widget child;

  const FkStepContainer({
    super.key,
    required this.stepNumber,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: AppRadius.lgAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
                child: Text(
                  '$stepNumber',
                  style: textTheme.labelLarge?.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(title, style: textTheme.headlineSmall)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}
