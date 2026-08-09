library fk_empty_state;

import 'package:flutter/material.dart';

import '../tokens/app_color_theme.dart';
import '../tokens/app_spacing.dart';
import 'fk_primary_button.dart';

/// Illustration + title + description + optional primary action, for empty
/// content states (never a bare "nothing here" text block).
class FkEmptyState extends StatelessWidget {
  final Widget illustration;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const FkEmptyState({
    super.key,
    required this.illustration,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          illustration,
          const SizedBox(height: AppSpacing.xl),
          Text(title, style: textTheme.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.xl),
            FkPrimaryButton(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}
