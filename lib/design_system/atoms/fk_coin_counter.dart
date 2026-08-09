library fk_coin_counter;

import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_shadows.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// Animated coin counter — increments smoothly when value changes.
class FkCoinCounter extends StatefulWidget {
  final int value;

  const FkCoinCounter({super.key, required this.value});

  @override
  State<FkCoinCounter> createState() => _FkCoinCounterState();
}

class _FkCoinCounterState extends State<FkCoinCounter>
    with SingleTickerProviderStateMixin {
  late int _displayed;
  late AnimationController _bounce;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _displayed = widget.value;
    _bounce = AnimationController(
      vsync: this,
      duration: AppMotion.fast,
    );
    _bounceAnim = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _bounce, curve: AppMotion.press),
    );
  }

  @override
  void didUpdateWidget(FkCoinCounter old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      setState(() => _displayed = widget.value);
      if (!AppMotion.reduced(context)) {
        _bounce.forward(from: 0).then((_) => _bounce.reverse());
      }
    }
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounceAnim,
      builder: (context, child) => Transform.scale(
        scale: _bounceAnim.value,
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.warning,
          borderRadius: AppRadius.pillAll,
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⭐', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(
              '$_displayed',
              style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
