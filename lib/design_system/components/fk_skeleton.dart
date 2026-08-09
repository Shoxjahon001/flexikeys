library fk_skeleton;

import 'package:flutter/material.dart';

import '../tokens/app_color_theme.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_radius.dart';

/// Shimmer placeholder matching a real card's shape — used instead of a
/// bare spinner on any content screen (loading grids, lists, cards).
class FkSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const FkSkeleton({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = AppRadius.mdAll,
  });

  /// Convenience: a skeleton shaped like [FkContentCard].
  factory FkSkeleton.contentCard() => const FkSkeleton(height: 168, borderRadius: AppRadius.mdAll);

  @override
  State<FkSkeleton> createState() => _FkSkeletonState();
}

class _FkSkeletonState extends State<FkSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.slow * 3,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (AppMotion.reduced(context)) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(color: colors.surfaceMuted, borderRadius: widget.borderRadius),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            final t = _controller.value;
            return LinearGradient(
              begin: Alignment(-1 - t * 2, 0),
              end: Alignment(1 - t * 2, 0),
              colors: [
                colors.surfaceMuted,
                colors.border,
                colors.surfaceMuted,
              ],
              stops: const [0.35, 0.5, 0.65],
            ).createShader(bounds);
          },
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(color: colors.surfaceMuted, borderRadius: widget.borderRadius),
          ),
        );
      },
    );
  }
}
