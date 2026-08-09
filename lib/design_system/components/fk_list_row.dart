library fk_list_row;

import 'package:flutter/material.dart';

import '../tokens/app_color_theme.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';

/// Standard settings/list row: 44 rounded thumbnail + [bodyLarge] label +
/// chevron, ≥64dp tall, hairline divider below (owned by the row so callers
/// don't need a separate Divider between items).
class FkListRow extends StatelessWidget {
  final Widget? leading;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool showDivider;

  const FkListRow({
    super.key,
    this.leading,
    required this.label,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showChevron = true,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: onTap != null,
      label: subtitle == null ? label : '$label, $subtitle',
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            border: showDivider
                ? Border(bottom: BorderSide(color: colors.border))
                : null,
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                ClipRRect(
                  borderRadius: AppRadius.smAll,
                  child: SizedBox(width: 44, height: 44, child: leading),
                ),
                const SizedBox(width: AppSpacing.lg),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: textTheme.bodyLarge),
                    if (subtitle != null)
                      Text(subtitle!, style: textTheme.bodySmall),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              if (showChevron && onTap != null)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm),
                  child: Icon(Icons.chevron_right_rounded, color: colors.textTertiary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
