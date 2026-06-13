import 'package:flutter/material.dart';

class CloudMascot extends StatefulWidget {
  final double size;
  final bool animate;

  const CloudMascot({super.key, this.size = 160, this.animate = true});

  @override
  State<CloudMascot> createState() => _CloudMascotState();
}

class _CloudMascotState extends State<CloudMascot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget cloud = CustomPaint(
      size: Size(widget.size, widget.size * 0.75),
      painter: const CloudIconPainter(),
    );

    if (!widget.animate) return cloud;

    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _floatAnim.value),
        child: child,
      ),
      child: cloud,
    );
  }
}

/// Public painter so it can also be used for icon generation.
class CloudIconPainter extends CustomPainter {
  final bool withBackground;

  const CloudIconPainter({this.withBackground = false});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    if (withBackground) {
      // Gradient background matching the FlexiKeys logo circle:
      // teal-mint at top-right fading to lavender-blue at bottom-left,
      // with a soft radial highlight in the center.
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF9DD4CA), Color(0xFF9BBAD6)],
          ).createShader(Rect.fromLTWH(0, 0, w, h)),
      );
      // Radial white glow in the center so the cloud "glows"
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(0, 0),
            radius: 0.65,
            colors: [
              Colors.white.withValues(alpha: 0.55),
              Colors.transparent,
            ],
          ).createShader(Rect.fromLTWH(0, 0, w, h)),
      );
    }

    // ── Drop shadow ──────────────────────────────────────────────────────────
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.50, h * 0.97),
          width: w * 0.60,
          height: h * 0.10),
      Paint()
        ..color = const Color(0xFF6B8EF5).withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );

    // ── Left puff — blue-lavender (behind center) ────────────────────────────
    final lc = Offset(w * 0.25, h * 0.70);
    final lr = w * 0.21;
    canvas.drawCircle(
      lc,
      lr,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.4),
          radius: 0.9,
          colors: [Color(0xFFCDD9EF), Color(0xFF9EB8DC)],
        ).createShader(Rect.fromCircle(center: lc, radius: lr)),
    );

    // ── Right puff — sage green (behind center) ──────────────────────────────
    final rc = Offset(w * 0.74, h * 0.62);
    final rr = w * 0.25;
    canvas.drawCircle(
      rc,
      rr,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.4),
          radius: 0.9,
          colors: [Color(0xFFCBE8D8), Color(0xFF98C9B2)],
        ).createShader(Rect.fromCircle(center: rc, radius: rr)),
    );

    // ── Center puff — white-blue (front, carries the face) ───────────────────
    final cc = Offset(w * 0.49, h * 0.44);
    final cr = w * 0.33;
    canvas.drawCircle(
      cc,
      cr,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.45),
          radius: 0.85,
          colors: [Color(0xFFF4F9FF), Color(0xFFCCDFF5)],
        ).createShader(Rect.fromCircle(center: cc, radius: cr)),
    );

    // Soft inner highlight
    canvas.drawCircle(
      Offset(w * 0.38, h * 0.29),
      w * 0.11,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.50)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // ── Eyes ────────────────────────────────────────────────────────────────
    final eyePaint = Paint()..color = const Color(0xFF3A4A5A);
    canvas.drawCircle(Offset(w * 0.41, h * 0.40), w * 0.042, eyePaint);
    canvas.drawCircle(Offset(w * 0.57, h * 0.40), w * 0.042, eyePaint);

    // Eye shines
    final shinePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.425, h * 0.375), w * 0.016, shinePaint);
    canvas.drawCircle(Offset(w * 0.585, h * 0.375), w * 0.016, shinePaint);

    // ── Smile ────────────────────────────────────────────────────────────────
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.40, h * 0.51)
        ..quadraticBezierTo(w * 0.49, h * 0.60, w * 0.58, h * 0.51),
      Paint()
        ..color = const Color(0xFF3A4A5A)
        ..strokeWidth = w * 0.030
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
