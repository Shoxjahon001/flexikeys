library mascot_renderer;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../fk_tokens.dart';
import '../tokens/app_motion.dart';

/// Mascot expression states.
enum FkExpression {
  happy,
  thinking,
  sleeping,
  celebrating,
  encouraging,
  surprised,
  waving,
}

/// CustomPainter-based mascot renderer.
///
/// Implements the same state-machine API as the planned Rive adapter so it
/// can be swapped without touching feature code. See ADR-005.
///
/// The mascot is a floating cloud with expressive eyes and blush marks.
/// All expressions are pure-Dart drawn shapes — no external assets needed.
class MascotRenderer extends StatefulWidget {
  final FkExpression expression;
  final double size;

  const MascotRenderer({
    super.key,
    this.expression = FkExpression.happy,
    this.size = 160,
  });

  @override
  State<MascotRenderer> createState() => _MascotRendererState();
}

class _MascotRendererState extends State<MascotRenderer>
    with SingleTickerProviderStateMixin {
  late AnimationController _float;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    // 2–3px vertical sine drift, always on (unless reduced motion).
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -2.5, end: 2.5).animate(
      CurvedAnimation(parent: _float, curve: FkCurves.gentle),
    );
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, reduced ? 0 : _floatAnim.value),
        child: child,
      ),
      child: CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _MascotPainter(expression: widget.expression),
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  final FkExpression expression;
  _MascotPainter({required this.expression});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2 + h * 0.05;

    // Body — main cloud blob
    final bodyPaint = Paint()..color = FkColors.cloud;
    final shadowPaint = Paint()
      ..color = FkColors.sky.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + h * 0.06), width: w * 0.7, height: h * 0.15),
      shadowPaint,
    );

    // Main cloud body
    final bodyPath = _cloudPath(cx, cy, w, h);
    canvas.drawPath(bodyPath, bodyPaint);

    // Outline
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = FkColors.sky.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Eyes
    _drawEyes(canvas, cx, cy, w, h);

    // Blush marks
    _drawBlush(canvas, cx, cy, w, h);

    // Expression-specific extras
    switch (expression) {
      case FkExpression.thinking:
        _drawThinkingDots(canvas, cx, cy, w, h);
      case FkExpression.waving:
        _drawWaveHand(canvas, cx, cy, w, h);
      case FkExpression.celebrating:
        _drawCelebrationSparkles(canvas, cx, cy, w, h);
      default:
        break;
    }
  }

  Path _cloudPath(double cx, double cy, double w, double h) {
    final p = Path();
    final r = w * 0.32;
    // Central main blob
    p.addOval(Rect.fromCenter(center: Offset(cx, cy), width: r * 2.1, height: r * 1.7));
    // Left bump
    p.addOval(Rect.fromCenter(center: Offset(cx - r * 0.65, cy - r * 0.1), width: r * 1.3, height: r * 1.2));
    // Right bump
    p.addOval(Rect.fromCenter(center: Offset(cx + r * 0.65, cy - r * 0.1), width: r * 1.3, height: r * 1.2));
    // Top bump
    p.addOval(Rect.fromCenter(center: Offset(cx, cy - r * 0.5), width: r * 1.2, height: r * 1.1));
    return p;
  }

  void _drawEyes(Canvas canvas, double cx, double cy, double w, double h) {
    final r = w * 0.06;
    final lx = cx - w * 0.15;
    final rx = cx + w * 0.15;
    final ey = cy - h * 0.02;

    final eyePaint = Paint()..color = FkColors.ink;

    switch (expression) {
      case FkExpression.sleeping:
        // Closed curved lines
        final p = Paint()
          ..color = FkColors.ink
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        for (final x in [lx, rx]) {
          canvas.drawArc(
            Rect.fromCenter(center: Offset(x, ey), width: r * 2.8, height: r * 1.6),
            0,
            math.pi,
            false,
            p,
          );
        }

      case FkExpression.surprised:
        // Big open circles
        canvas.drawCircle(Offset(lx, ey), r * 1.4, eyePaint);
        canvas.drawCircle(Offset(rx, ey), r * 1.4, eyePaint);
        final whitePaint = Paint()..color = FkColors.cloud;
        canvas.drawCircle(Offset(lx - r * 0.3, ey - r * 0.3), r * 0.5, whitePaint);
        canvas.drawCircle(Offset(rx - r * 0.3, ey - r * 0.3), r * 0.5, whitePaint);

      case FkExpression.thinking:
        // One eye slightly raised, small squint
        canvas.drawOval(Rect.fromCenter(center: Offset(lx, ey), width: r * 1.8, height: r * 1.0), eyePaint);
        canvas.drawOval(Rect.fromCenter(center: Offset(rx, ey - r * 0.3), width: r * 1.8, height: r * 1.0), eyePaint);

      default:
        // Happy round eyes with highlight
        canvas.drawCircle(Offset(lx, ey), r, eyePaint);
        canvas.drawCircle(Offset(rx, ey), r, eyePaint);
        final highlightPaint = Paint()..color = FkColors.cloud.withValues(alpha: 0.7);
        canvas.drawCircle(Offset(lx - r * 0.25, ey - r * 0.25), r * 0.35, highlightPaint);
        canvas.drawCircle(Offset(rx - r * 0.25, ey - r * 0.25), r * 0.35, highlightPaint);
    }
  }

  void _drawBlush(Canvas canvas, double cx, double cy, double w, double h) {
    if (expression == FkExpression.sleeping ||
        expression == FkExpression.thinking) {
      return;
    }

    final blushPaint = Paint()
      ..color = FkColors.peach.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - w * 0.22, cy + h * 0.06), width: w * 0.16, height: h * 0.09),
      blushPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + w * 0.22, cy + h * 0.06), width: w * 0.16, height: h * 0.09),
      blushPaint,
    );
  }

  void _drawThinkingDots(Canvas canvas, double cx, double cy, double w, double h) {
    final paint = Paint()..color = FkColors.lavender;
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(cx + w * 0.38 + i * w * 0.075, cy - h * 0.25 - i * h * 0.05),
        (i + 1) * w * 0.022,
        paint,
      );
    }
  }

  void _drawWaveHand(Canvas canvas, double cx, double cy, double w, double h) {
    final paint = Paint()
      ..color = FkColors.warmYellow
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(cx + w * 0.38, cy - h * 0.1)
      ..quadraticBezierTo(cx + w * 0.52, cy - h * 0.2, cx + w * 0.46, cy - h * 0.32)
      ..quadraticBezierTo(cx + w * 0.40, cy - h * 0.44, cx + w * 0.50, cy - h * 0.38);
    canvas.drawPath(path, paint);
  }

  void _drawCelebrationSparkles(Canvas canvas, double cx, double cy, double w, double h) {
    final colors = [FkColors.warmYellow, FkColors.mint, FkColors.lavender];
    final positions = [
      Offset(cx - w * 0.42, cy - h * 0.38),
      Offset(cx + w * 0.42, cy - h * 0.38),
      Offset(cx, cy - h * 0.52),
    ];

    for (int i = 0; i < positions.length; i++) {
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final r = w * 0.07;
      final pos = positions[i];
      for (int j = 0; j < 4; j++) {
        final angle = j * math.pi / 2;
        canvas.drawLine(
          pos,
          Offset(pos.dx + r * math.cos(angle), pos.dy + r * math.sin(angle)),
          paint,
        );
      }
      canvas.drawCircle(pos, r * 0.3, Paint()..color = colors[i % colors.length]);
    }
  }

  @override
  bool shouldRepaint(_MascotPainter old) => old.expression != expression;
}