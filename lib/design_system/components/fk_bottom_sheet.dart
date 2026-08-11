library fk_bottom_sheet;

import 'package:flutter/material.dart';

import '../tokens/app_color_theme.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';

/// Token-styled shell for [showModalBottomSheet] — drag handle, rounded top
/// corners, consistent padding/title. The one existing bottom sheet in the
/// app (AAC card manager's photo-source picker) was plain `ListTile`s with
/// no shared chrome; this gives every future sheet the same frame.
class FkBottomSheet extends StatelessWidget {
  final String? title;
  final Widget child;

  const FkBottomSheet({super.key, this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: AppRadius.pillAll,
                ),
              ),
            ),
            if (title != null) ...[
              Text(title!, style: textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.md),
            ],
            child,
          ],
        ),
      ),
    );
  }

  /// Shows [child] wrapped in the sheet's shell.
  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    required Widget child,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => FkBottomSheet(title: title, child: child),
    );
  }
}