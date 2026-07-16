library fk_coin_counter;

import 'package:flutter/material.dart';
import '../fk_tokens.dart';
import '../fk_theme.dart';

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
      duration: FkDurations.fast,
    );
    _bounceAnim = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _bounce, curve: FkCurves.spring),
    );
  }

  @override
  void didUpdateWidget(FkCoinCounter old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      setState(() => _displayed = widget.value);
      if (!FkTheme.reducedMotion(context)) {
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
    final fk = FkTheme.of(context);
    return AnimatedBuilder(
      animation: _bounceAnim,
      builder: (context, child) => Transform.scale(
        scale: _bounceAnim.value,
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: FkSpacing.sm,
          vertical: FkSpacing.xs / 2,
        ),
        decoration: BoxDecoration(
          color: fk.attention,
          borderRadius: FkRadii.pillAll,
          boxShadow: FkElevation.low(fk.ink),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⭐', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(
              '$_displayed',
              style: FkTextStyles.childLabel.copyWith(color: fk.ink),
            ),
          ],
        ),
      ),
    );
  }
}