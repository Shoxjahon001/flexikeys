library fk_card;

import 'package:flutter/material.dart';
import '../fk_tokens.dart';
import '../fk_theme.dart';

/// Rounded surface card — 24dp radius, soft shadow, pastel fill.
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
    final fk = FkTheme.of(context);
    final bg = color ?? fk.surface;
    final radius = borderRadius ?? FkRadii.mdAll;

    final content = Container(
      padding: padding ?? const EdgeInsets.all(FkSpacing.sm),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        boxShadow: FkElevation.low(fk.ink),
      ),
      child: child,
    );

    if (onTap == null) return content;

    return GestureDetector(
      onTap: onTap,
      child: content,
    );
  }
}