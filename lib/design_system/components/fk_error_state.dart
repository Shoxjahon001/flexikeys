library fk_error_state;

import 'package:flutter/material.dart';

import '../tokens/app_color_theme.dart';
import '../tokens/app_spacing.dart';
import 'fk_secondary_button.dart';

/// Icon + title + description + optional retry action, for a failed
/// `AsyncValue`/load — the parent/teacher-facing counterpart to
/// [FkEmptyState]. Not used in the child gameplay surface: CLAUDE.md's
/// "no failures" rule means the child never sees an error framed
/// negatively, so this is for admin/parent/teacher screens only.
class FkErrorState extends StatelessWidget {
  final String title;
  final String description;
  final String? retryLabel;
  final VoidCallback? onRetry;

  const FkErrorState({
    super.key,
    required this.title,
    required this.description,
    this.retryLabel,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: colors.dangerSoft, shape: BoxShape.circle),
            child: Icon(Icons.error_outline_rounded, color: colors.danger, size: 32),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(title, style: textTheme.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (retryLabel != null && onRetry != null) ...[
            const SizedBox(height: AppSpacing.xl),
            FkSecondaryButton(label: retryLabel!, onPressed: onRetry),
          ],
        ],
      ),
    );
  }
}