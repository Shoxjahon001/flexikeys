library fk_page_indicator;

import 'package:flutter/material.dart';

import '../tokens/app_color_theme.dart';

/// "1 / 8" text indicator beneath the detail-speak screen, or a dot
/// variant for onboarding-style carousels.
class FkPageIndicator extends StatelessWidget {
  final int current;
  final int total;
  final bool dotVariant;

  const FkPageIndicator({
    super.key,
    required this.current,
    required this.total,
    this.dotVariant = false,
  }) : assert(total > 0),
       assert(current >= 1 && current <= total);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (!dotVariant) {
      return Semantics(
        label: 'Page $current of $total',
        child: Text(
          '$current / $total',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textTertiary),
        ),
      );
    }

    return Semantics(
      label: 'Page $current of $total',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= total; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == current ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == current ? colors.primary : colors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
        ],
      ),
    );
  }
}
