library fk_loading_indicator;

import 'package:flutter/material.dart';

import '../tokens/app_color_theme.dart';

/// Token-colored spinner — a drop-in replacement for the bare
/// `CircularProgressIndicator()` (default Material purple) scattered across
/// loading branches. [FkSkeleton] remains the preferred loading treatment
/// for content grids/lists; this is for the smaller full-screen/inline
/// spinner cases where a skeleton shape doesn't apply.
class FkLoadingIndicator extends StatelessWidget {
  final double size;
  final double strokeWidth;

  const FkLoadingIndicator({super.key, this.size = 32, this.strokeWidth = 3});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        color: context.colors.primary,
      ),
    );
  }
}