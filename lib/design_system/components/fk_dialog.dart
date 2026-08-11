library fk_dialog;

import 'package:flutter/material.dart';

import '../tokens/app_color_theme.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import 'fk_primary_button.dart';
import 'fk_secondary_button.dart';

/// Token-styled shell for [AlertDialog] content — every dialog in the app
/// (delete confirm, sign-out confirm, name entry, ...) was hand-rolling its
/// own `AlertDialog(shape: ...)` with copy-pasted styling; this centralizes
/// it so shape/spacing/typography only need to change in one place.
class FkDialog extends StatelessWidget {
  final String title;
  final String? message;
  final Widget? content;
  final List<Widget> actions;

  const FkDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
      title: Text(title, style: textTheme.headlineSmall),
      content: content ??
          (message != null
              ? Text(
                  message!,
                  style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
                )
              : null),
      actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      actions: actions,
    );
  }

  /// Two-button confirm/cancel dialog, resolving `true` on confirm, `false`
  /// (or `null` if dismissed) otherwise. [isDestructive] renders the confirm
  /// button in [AppColorTheme.danger] instead of the primary brand color
  /// (delete/sign-out style actions) — this is a parent/adult-surface
  /// affordance only, never shown to the child (CLAUDE.md's "no failures"
  /// rule governs the child experience, not parent confirmation UX).
  static Future<bool?> confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => FkDialog(
        title: title,
        message: message,
        actions: [
          FkSecondaryButton(
            label: cancelLabel,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          const SizedBox(width: AppSpacing.sm),
          FkPrimaryButton(
            label: confirmLabel,
            color: isDestructive ? dialogContext.colors.danger : null,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
  }
}