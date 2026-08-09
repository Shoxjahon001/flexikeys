library fk_side_nav;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/app_color_theme.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import 'fk_bottom_nav.dart' show FkBottomNavItem;

/// Tablet/landscape sidebar counterpart to [FkBottomNav]: icon + label
/// rows, active = a soft primary pill, optional profile card pinned at the
/// bottom.
class FkSideNav extends StatelessWidget {
  final List<FkBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Widget? profileCard;

  const FkSideNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.profileCard,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: context.colors.surface,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
                children: [
                  for (var i = 0; i < items.length; i++) _buildRow(context, i),
                ],
              ),
            ),
            if (profileCard != null)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: profileCard,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, int index) {
    final item = items[index];
    final active = index == currentIndex;
    final colors = context.colors;
    final color = active ? colors.primary : colors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Semantics(
        button: true,
        selected: active,
        label: item.label,
        child: Material(
          color: active ? colors.primarySoft : Colors.transparent,
          borderRadius: AppRadius.smAll,
          child: InkWell(
            borderRadius: AppRadius.smAll,
            onTap: () {
              if (!active) HapticFeedback.selectionClick();
              onTap(index);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
              child: Row(
                children: [
                  Icon(active ? item.filledIcon : item.icon, color: color, size: 22),
                  const SizedBox(width: AppSpacing.md),
                  Text(item.label,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: color)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
