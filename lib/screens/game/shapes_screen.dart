import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cloud_mascot.dart';
import '../../services/user_service.dart';
import '../../services/tts_service.dart';
import '../../services/sound_service.dart';
import '../../services/progress/progress_repository.dart';
import '../../data/praise_copy.dart';

// ── Shape data ─────────────────────────────────────────────────────────────────

class _ShapeConfig {
  final String id;
  final String name;
  final List<Offset> dots; // normalised 0–1 inside inner canvas

  const _ShapeConfig({
    required this.id,
    required this.name,
    required this.dots,
  });
}

const _kShapes = <_ShapeConfig>[
  _ShapeConfig(id: 'square', name: 'Kvadrat', dots: [
    Offset(0.22, 0.22),
    Offset(0.78, 0.22),
    Offset(0.78, 0.78),
    Offset(0.22, 0.78),
  ]),
  _ShapeConfig(id: 'triangle', name: 'Uchburchak', dots: [
    Offset(0.50, 0.14),
    Offset(0.84, 0.84),
    Offset(0.16, 0.84),
  ]),
  _ShapeConfig(id: 'rect', name: "To'rtburchak", dots: [
    Offset(0.14, 0.32),
    Offset(0.86, 0.32),
    Offset(0.86, 0.68),
    Offset(0.14, 0.68),
  ]),
  _ShapeConfig(id: 'diamond', name: 'Romb', dots: [
    Offset(0.50, 0.14),
    Offset(0.86, 0.50),
    Offset(0.50, 0.86),
    Offset(0.14, 0.50),
  ]),
  _ShapeConfig(id: 'pentagon', name: 'Beshburchak', dots: [
    Offset(0.50, 0.13),
    Offset(0.87, 0.42),
    Offset(0.72, 0.86),
    Offset(0.28, 0.86),
    Offset(0.13, 0.42),
  ]),
  _ShapeConfig(id: 'hexagon', name: 'Olti burchak', dots: [
    Offset(0.50, 0.13),
    Offset(0.85, 0.32),
    Offset(0.85, 0.68),
    Offset(0.50, 0.87),
    Offset(0.15, 0.68),
    Offset(0.15, 0.32),
  ]),
];

// ── Screen ─────────────────────────────────────────────────────────────────────

class ShapesScreen extends StatefulWidget {
  const ShapesScreen({super.key});

  @override
  State<ShapesScreen> createState() => _ShapesScreenState();
}

class _ShapesScreenState extends State<ShapesScreen>
    with SingleTickerProviderStateMixin {
  static const int _questionCount = 12;
  static const double _pad = 22.0; // canvas margin so dots aren't clipped
  static const double _snapR = 30.0; // proximity radius to register a dot

  List<_ShapeConfig> _questions = [];
  int _current = 0;
  int _tapped = 0; // dots reached in order
  bool _shapeDone = false;
  int _accuracy = 10; // 0–10, calculated when shape is done

  // Stroke storage: multiple segments (pen-up = new segment)
  final List<List<Offset>> _segments = []; // completed segments
  List<Offset> _stroke = []; // active segment

  // canvas inner size (set in LayoutBuilder)
  double _inner = 200.0;

  // pulse animation for next-dot indicator
  late AnimationController _pulse;
  late Animation<double> _pulseAnim;

  _ShapeConfig get _shape => _questions[_current];

  // pixel position of a dot
  Offset _px(int i) {
    final d = _shape.dots[i];
    return Offset(d.dx * _inner + _pad, d.dy * _inner + _pad);
  }

  // ── Life cycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.4)
        .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
    _initQuestions();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  // ── Setup ───────────────────────────────────────────────────────────────────

  void _initQuestions() {
    final list = <_ShapeConfig>[..._kShapes, ..._kShapes]..shuffle(Random());
    _questions = list.take(_questionCount).toList();
  }

  void _resetShape() {
    _pulse.repeat(reverse: true);
    setState(() {
      _tapped = 0;
      _shapeDone = false;
      _accuracy = 10;
      _segments.clear();
      _stroke = [];
    });
  }

  // ── Drawing ─────────────────────────────────────────────────────────────────

  void _onPanStart(DragStartDetails d) {
    if (_shapeDone) return;
    setState(() {
      _stroke = [d.localPosition];
    });
    _trySnap(d.localPosition);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_shapeDone) return;
    final pos = d.localPosition;
    // Skip points that are too close to the last recorded — reduces memory
    // usage and avoids feeding the painter thousands of near-duplicate points.
    if (_stroke.isNotEmpty && (_stroke.last - pos).distance < 2.5) {
      _trySnap(pos); // still check for dot snap even if we skip the point
      return;
    }
    setState(() => _stroke.add(pos));
    _trySnap(pos);
  }

  void _onPanEnd(DragEndDetails _) {
    if (_shapeDone || _stroke.isEmpty) return;
    setState(() {
      _segments.add(List<Offset>.from(_stroke));
      _stroke = [];
    });
  }

  void _trySnap(Offset pos) {
    if (_shapeDone) return;

    final allVisited = _tapped >= _shape.dots.length;

    if (!allVisited) {
      if ((_px(_tapped) - pos).distance < _snapR) {
        SoundService.instance.playCorrect();
        setState(() => _tapped++);
      }
    } else {
      // all dots visited — must return to dot 0 to close the shape
      if ((_px(0) - pos).distance < _snapR) {
        _pulse.stop();
        if (_stroke.isNotEmpty) {
          _segments.add(List<Offset>.from(_stroke));
          _stroke = [];
        }
        final score = _computeAccuracy();
        setState(() {
          _shapeDone = true;
          _accuracy = score;
        });
        SoundService.instance.playCorrect();
        TtsService.instance.speakFunny(score >= 7
            ? PraiseCopy.shapeTraced(context)
            : AppLocalizations.of(context)!.goodJobKeepGoing);
      }
    }
  }

  // ── Accuracy ────────────────────────────────────────────────────────────────

  int _computeAccuracy() {
    // Collect all drawn points
    final pts = <Offset>[
      for (final seg in _segments) ...seg,
      ..._stroke,
    ];
    if (pts.isEmpty) return 5;

    // Build ideal closed polygon in pixels
    final ideal = _shape.dots
        .map((d) => Offset(d.dx * _inner + _pad, d.dy * _inner + _pad))
        .toList();

    // Average distance of drawn points to the nearest polygon edge
    double total = 0;
    // sample every ~4th point to keep it fast
    int count = 0;
    for (int i = 0; i < pts.length; i += 4) {
      total += _distToPolygon(pts[i], ideal);
      count++;
    }
    if (count == 0) return 10;
    final avg = total / count;

    // Map: 0 px → 10/10, 30 px → 0/10
    return (10 - (avg / 3.0).clamp(0.0, 10.0)).round();
  }

  double _distToPolygon(Offset p, List<Offset> poly) {
    double min = double.infinity;
    for (int i = 0; i < poly.length; i++) {
      final d = _segDist(p, poly[i], poly[(i + 1) % poly.length]);
      if (d < min) min = d;
    }
    return min;
  }

  double _segDist(Offset p, Offset a, Offset b) {
    final dx = b.dx - a.dx, dy = b.dy - a.dy;
    if (dx == 0 && dy == 0) return (p - a).distance;
    final t = ((p.dx - a.dx) * dx + (p.dy - a.dy) * dy) / (dx * dx + dy * dy);
    final tc = t.clamp(0.0, 1.0);
    return (p - Offset(a.dx + tc * dx, a.dy + tc * dy)).distance;
  }

  // ── Navigation ──────────────────────────────────────────────────────────────

  void _advance() {
    if (_current >= _questions.length - 1) {
      _onFinish();
      return;
    }
    setState(() => _current++);
    _resetShape();
  }

  Future<void> _onFinish() async {
    await UserService.addStars(10);
    await UserService.completeLevel('shapes');
    ProgressRepository.instance.recordLevelCompleteAndSync('shapes', stars: 10);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/level_complete',
        arguments: {'starsEarned': 10});
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: appGradientBg,
        child: SafeArea(
          child: Column(
            children: [
              _header(),
              _progressBar(),
              const SizedBox(height: 8),
              _mascot(),
              const SizedBox(height: 8),
              _card(),
              if (_shapeDone) ...[
                const SizedBox(height: 12),
                _scoreRow(),
              ],
              const Spacer(),
              _bottomBtn(),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: Color(0xFF2A2F45)),
            ),
          ),
          const SizedBox(width: 12),
          Text('Shakllar',
              style: GoogleFonts.nunito(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2A2F45))),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(20)),
            child: Text('${_current + 1}/${_questions.length}',
                style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF4A90F7))),
          ),
        ]),
      );

  Widget _progressBar() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (_current + 1) / _questions.length,
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.5),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4A90F7)),
          ),
        ),
      );

  // ── Mascot ───────────────────────────────────────────────────────────────────

  Widget _mascot() {
    final t = AppLocalizations.of(context)!;
    final allVisited = _tapped >= _shape.dots.length;
    final msg = _shapeDone
        ? (_accuracy >= 7 ? t.shapesPraiseHigh : t.shapesPraiseLow)
        : allVisited
            ? t.shapesCloseInstruction
            : (_tapped == 0
                ? t.shapesStartInstruction
                : t.shapesProgress(_tapped, _shape.dots.length));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const CloudMascot(size: 64, animate: true),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 10,
                    offset: const Offset(0, 3))
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(msg,
                  key: ValueKey(msg),
                  style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2A2F45))),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Card ─────────────────────────────────────────────────────────────────────

  Widget _card() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFDDE3F8), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.09),
                  blurRadius: 20,
                  offset: const Offset(0, 6))
            ],
          ),
          child: Column(children: [
            _cardHeader(),
            const SizedBox(height: 12),
            _canvas(),
            const SizedBox(height: 6),
            Text(
              _shapeDone
                  ? '${_shape.dots.length}/${_shape.dots.length} ${AppLocalizations.of(context)!.shapesDoneStatus}'
                  : AppLocalizations.of(context)!.shapesIdleInstruction,
              style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _shapeDone
                      ? const Color(0xFF22B07D)
                      : const Color(0xFF9099B5)),
            ),
          ]),
        ),
      );

  Widget _cardHeader() => Row(children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF4A90F7),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF4A90F7).withValues(alpha: 0.38),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Center(
              child: CustomPaint(
                  size: const Size(26, 26),
                  painter: _IconPainter(_shape.dots))),
        ),
        const SizedBox(width: 10),
        Text(_shape.name,
            style: GoogleFonts.nunito(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF2A2F45))),
        if (_shapeDone) ...[
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: const Color(0xFFDFF0DB),
                borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.check_rounded,
                  color: Color(0xFF22B07D), size: 14),
              const SizedBox(width: 3),
              Text('Tayyor',
                  style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF22B07D))),
            ]),
          ),
        ],
      ]);

  // ── Canvas ───────────────────────────────────────────────────────────────────

  Widget _canvas() {
    return LayoutBuilder(builder: (_, c) {
      _inner = min(c.maxWidth - _pad * 2, 210.0);
      final total = _inner + _pad * 2;

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Container(
          width: total,
          height: total,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4FF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  (!_shapeDone && (_segments.isNotEmpty || _stroke.isNotEmpty))
                      ? const Color(0xFF4A90F7).withValues(alpha: 0.45)
                      : const Color(0xFFDDE3F8),
              width:
                  (!_shapeDone && (_segments.isNotEmpty || _stroke.isNotEmpty))
                      ? 2
                      : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // painter: ghost + drawn strokes
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _DrawPainter(
                        dots: _shape.dots,
                        segments: _segments,
                        active: _stroke,
                        tapped: _tapped,
                        done: _shapeDone,
                        pad: _pad,
                        inner: _inner,
                      ),
                    ),
                  ),
                ),

                // tiny numbered dot markers (visual only, no interaction)
                ...List.generate(_shape.dots.length, (i) {
                  const r = 9.0; // small visual radius
                  final px = _px(i);
                  final allVisited = _tapped >= _shape.dots.length;
                  final reached = i < _tapped || _shapeDone;
                  // pulse on the next dot to reach; when all visited, pulse dot 0
                  final isNext =
                      !_shapeDone && (allVisited ? i == 0 : i == _tapped);

                  Widget dot = Container(
                    width: r * 2,
                    height: r * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: reached ? const Color(0xFF4A90F7) : Colors.white,
                      border: Border.all(
                        color: const Color(0xFF4A90F7),
                        width: reached ? 0 : 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4A90F7)
                              .withValues(alpha: isNext ? 0.6 : 0.2),
                          blurRadius: isNext ? 12 : 4,
                          spreadRadius: isNext ? 2 : 0,
                        ),
                      ],
                    ),
                    child: Center(
                      child: reached
                          ? const Icon(Icons.check_rounded,
                              size: 10, color: Colors.white)
                          : Text('${i + 1}',
                              style: GoogleFonts.nunito(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF4A90F7),
                                  height: 1)),
                    ),
                  );

                  if (isNext) {
                    dot = ScaleTransition(scale: _pulseAnim, child: dot);
                  }

                  return Positioned(
                    left: px.dx - r,
                    top: px.dy - r,
                    child: IgnorePointer(child: dot),
                  );
                }),
              ],
            ),
          ),
        ),
      );
    });
  }

  // ── Score row ────────────────────────────────────────────────────────────────

  Widget _scoreRow() {
    final stars = _accuracy >= 9 ? 3 : (_accuracy >= 6 ? 2 : 1);
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      for (int s = 0; s < 3; s++)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Text(s < stars ? '⭐' : '☆',
              style: TextStyle(
                  fontSize: s < stars ? 26 : 20,
                  color: s < stars ? null : Colors.grey.shade400)),
        ),
      const SizedBox(width: 10),
      Text('$_accuracy/10',
          style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF2A2F45))),
    ]);
  }

  // ── Bottom button ─────────────────────────────────────────────────────────────

  Widget _bottomBtn() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _shapeDone
            ? GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _advance,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90F7),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color:
                              const Color(0xFF4A90F7).withValues(alpha: 0.42),
                          blurRadius: 16,
                          offset: const Offset(0, 7))
                    ],
                  ),
                  child: Text(
                    _current < _questions.length - 1
                        ? AppLocalizations.of(context)!.shapesNextButton
                        : AppLocalizations.of(context)!.shapesFinishButton,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white),
                  ),
                ),
              )
            : Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD0D8F0)),
                ),
                child: Text(
                    AppLocalizations.of(context)!.shapesDisabledPlaceholder,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF9099B5))),
              ),
      );
}

// ── Painter ────────────────────────────────────────────────────────────────────

class _DrawPainter extends CustomPainter {
  final List<Offset> dots;
  final List<List<Offset>> segments; // completed pen strokes
  final List<Offset> active; // ongoing stroke
  final int tapped;
  final bool done;
  final double pad;
  final double inner;

  _DrawPainter({
    required this.dots,
    required this.segments,
    required this.active,
    required this.tapped,
    required this.done,
    required this.pad,
    required this.inner,
  });

  Offset _px(Offset d) => Offset(d.dx * inner + pad, d.dy * inner + pad);

  @override
  void paint(Canvas canvas, Size size) {
    final pts = dots.map(_px).toList();
    if (pts.isEmpty) return;

    // ── 1. Ghost dashed outline ──────────────────────────────────────────────
    _ghost(canvas, pts);

    // ── 2. Child's actual drawn strokes ─────────────────────────────────────
    final drawPaint = Paint()
      ..color = const Color(0xFF4A90F7)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final seg in [...segments, active]) {
      if (seg.length < 2) continue;
      canvas.drawPath(_smoothPath(seg), drawPaint);
    }
  }

  void _ghost(Canvas canvas, List<Offset> pts) {
    final paint = Paint()
      ..color = const Color(0xFFB8CAFE).withValues(alpha: 0.85)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const dash = 7.0, gap = 5.0;

    final edges = <(Offset, Offset)>[
      for (int i = 0; i < pts.length - 1; i++) (pts[i], pts[i + 1]),
      if (pts.length > 2) (pts.last, pts.first),
    ];

    for (final (a, b) in edges) {
      final dx = b.dx - a.dx;
      final dy = b.dy - a.dy;
      final len = sqrt(dx * dx + dy * dy);
      if (len == 0) continue;
      final ux = dx / len, uy = dy / len;
      double pos = 0;
      bool drawing = true;
      while (pos < len) {
        final end = min(pos + (drawing ? dash : gap), len);
        if (drawing) {
          canvas.drawLine(
            Offset(a.dx + ux * pos, a.dy + uy * pos),
            Offset(a.dx + ux * end, a.dy + uy * end),
            paint,
          );
        }
        pos = end;
        drawing = !drawing;
      }
    }
  }

  // Build a smooth path using midpoint quadratic bezier curves.
  // The child's stroke is preserved as-is (not straightened) — this just
  // removes sharp pixel-level jitter from high-frequency touch events.
  static Path _smoothPath(List<Offset> pts) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    if (pts.length == 2) {
      path.lineTo(pts.last.dx, pts.last.dy);
      return path;
    }
    for (int i = 1; i < pts.length - 1; i++) {
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      path.quadraticBezierTo(p1.dx, p1.dy, mid.dx, mid.dy);
    }
    path.lineTo(pts.last.dx, pts.last.dy);
    return path;
  }

  @override
  bool shouldRepaint(_DrawPainter old) => true;
}

// ── Small icon painter ─────────────────────────────────────────────────────────

class _IconPainter extends CustomPainter {
  final List<Offset> dots;
  const _IconPainter(this.dots);

  @override
  void paint(Canvas canvas, Size size) {
    if (dots.isEmpty) return;
    final p = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(dots.first.dx * size.width, dots.first.dy * size.height);
    for (final d in dots.skip(1)) {
      path.lineTo(d.dx * size.width, d.dy * size.height);
    }
    path.close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_) => false;
}
