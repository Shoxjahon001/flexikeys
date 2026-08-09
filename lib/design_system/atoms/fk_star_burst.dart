library fk_star_burst;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../fk_tokens.dart';
import '../tokens/app_motion.dart';

/// Calm particle celebration — emits soft pastel particles outward.
/// Disabled entirely when reducedMotion is true.
class FkStarBurst extends StatefulWidget {
  final bool active;
  final double size;
  final int particleCount;

  const FkStarBurst({
    super.key,
    required this.active,
    this.size = 200,
    this.particleCount = 12,
  });

  @override
  State<FkStarBurst> createState() => _FkStarBurstState();
}

class _FkStarBurstState extends State<FkStarBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  final _rng = math.Random(42);

  static const _colors = [
    FkColors.mint,
    FkColors.lavender,
    FkColors.warmYellow,
    FkColors.peach,
    FkColors.sky,
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: FkDurations.slow);
    _anim = CurvedAnimation(parent: _ctrl, curve: FkCurves.standard);
    if (widget.active) _play();
  }

  @override
  void didUpdateWidget(FkStarBurst old) {
    super.didUpdateWidget(old);
    if (!old.active && widget.active) _play();
    if (!widget.active) _ctrl.reset();
  }

  void _play() {
    if (!AppMotion.reduced(context)) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _StarBurstPainter(
            progress: _anim.value,
            count: widget.particleCount,
            rng: _rng,
            colors: _colors,
          ),
        );
      },
    );
  }
}

class _StarBurstPainter extends CustomPainter {
  final double progress;
  final int count;
  final math.Random rng;
  final List<Color> colors;

  _StarBurstPainter({
    required this.progress,
    required this.count,
    required this.rng,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = size.width * 0.45;

    final seededRng = math.Random(42);
    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * math.pi + seededRng.nextDouble() * 0.3;
      final r = maxR * progress * (0.6 + seededRng.nextDouble() * 0.4);
      final opacity = (1 - progress) * 0.9;
      final particleSize = (4 + seededRng.nextDouble() * 6) * (1 - progress * 0.5);

      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(cx + r * math.cos(angle), cy + r * math.sin(angle)),
        particleSize,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarBurstPainter old) => old.progress != progress;
}