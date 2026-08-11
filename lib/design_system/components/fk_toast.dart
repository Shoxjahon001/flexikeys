library fk_toast;

import 'package:flutter/material.dart';

import '../tokens/app_color_theme.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';

enum FkToastType { success, error, info }

/// Token-styled [SnackBar] — every toast in the app (save confirmations,
/// "not enough coins", copy-to-clipboard) was a bare default `SnackBar`
/// with no icon/color system. This gives each a type-appropriate icon and
/// tint instead.
abstract final class FkToast {
  static void show(
    BuildContext context,
    String message, {
    FkToastType type = FkToastType.info,
  }) {
    final colors = context.colors;
    final (icon, tint) = switch (type) {
      FkToastType.success => (Icons.check_circle_rounded, colors.success),
      FkToastType.error => (Icons.error_rounded, colors.danger),
      FkToastType.info => (Icons.info_rounded, colors.primary),
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: colors.textPrimary,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          margin: const EdgeInsets.all(AppSpacing.md),
          content: Row(
            children: [
              Icon(icon, color: tint, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: colors.surface),
                ),
              ),
            ],
          ),
        ),
      );
  }
}