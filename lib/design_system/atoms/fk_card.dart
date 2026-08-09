library fk_card;

import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_shadows.dart';
import '../tokens/app_spacing.dart';

/// Rounded surface card — 20dp radius (AppRadius.lg), soft shadow, white
/// fill by default. Will likely split into `FkContentCard`/`FkCategoryCard`
/// per the component-library spec in a later phase; kept as one generic
/// atom for now since this phase is tokens only, not new components.
class FkCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const FkCard({
    super.key,
    required this.child,
    this.color,
    this.padding,
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppColors.surface;
    final radius = borderRadius ?? AppRadius.lgAll;

    final content = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        boxShadow: AppShadows.soft,
      ),
      // FkCard paints its own background via BoxDecoration, not Material —
      // without this, a ListTile/SwitchListTile (or anything else that
      // paints via the nearest Material ancestor) placed inside throws a
      // "background color or ink splashes may be invisible" framework
      // assertion and renders without ink feedback. `transparency` keeps
      // FkCard's own background exactly as before; only descendants that
      // need a Material now have one to paint into.
      child: Material(
        type: MaterialType.transparency,
        child: child,
      ),
    );

    if (onTap == null) return content;

    return GestureDetector(
      onTap: onTap,
      child: content,
    );
  }
}
