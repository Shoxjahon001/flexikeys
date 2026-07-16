import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/cloud_mascot.dart';
import '../../services/user_service.dart';
import '../../services/tts_service.dart';
import '../../services/sound_service.dart';
import '../../services/progress/progress_repository.dart';
import '../../data/praise_copy.dart';
import '../../data/trace_items/trace_item_def.dart';

/// Generic dot-to-dot tracing game — used by the Letters, Numbers, and
/// Objects drawing tasks. Same design and mechanics everywhere; only the
/// content (items), header title, level-progress slug, and the noun used in
/// the spoken/written instruction differ per caller.
class TraceDrawingScreen extends StatefulWidget {
  final String title;
  final List<TraceItemDef> items;
  final String levelSlug;
  final String instructionNoun;
  final String completionTitle;

  const TraceDrawingScreen({
    super.key,
    required this.title,
    required this.items,
    required this.levelSlug,
    required this.instructionNoun,
    required this.completionTitle,
  });

  @override
  State<TraceDrawingScreen> createState() => _TraceDrawingScreenState();
}

class _TraceDrawingScreenState extends State<TraceDrawingScreen>
    with TickerProviderStateMixin {

  // ── State ─────────────────────────────────────────────────────────────────

  int _itemIndex = 0;

  // Completed strokes (List of stroke-points) + active stroke in progress
  final List<List<Offset>> _strokes = [];
  List<Offset>             _current = [];

  int  _tapped   = 0;
  bool _checking = false;
  bool _celebrate = false;

  Color _penColor = const Color(0xFF4A90D9);
  Size  _canvasSize = const Size(320, 380);

  // ── Animations ────────────────────────────────────────────────────────────

  late final AnimationController _pulseCtrl;
  late final Animation<double>   _pulseAnim;

  late final AnimationController _demoCtrl;
  late final Animation<double>   _demoAnim;
  bool _isDemoPlaying = false;

  // ── Convenience ───────────────────────────────────────────────────────────

  static const double _snapR = 30.0;

  TraceItemDef get _def => widget.items[_itemIndex];

  /// The child can check their drawing once they've drawn something — they
  /// don't have to land every dot precisely to avoid getting stuck.
  bool get _canCheck =>
      !_checking && (_strokes.isNotEmpty || _current.isNotEmpty);

  String get _instruction {
    final seq = List.generate(_def.dots.length, (i) => '${i + 1}').join(' → ');
    return 'Nuqtalarni $seq tartibda ulab, ${_def.label} ${widget.instructionNoun} chiz!';
  }

  static const List<Color> _palette = [
    Color(0xFF4A90D9),
    Color(0xFFE0567B),
    Color(0xFF4CAF50),
    Color(0xFFFFC107),
  ];

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _demoCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _demoAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _demoCtrl, curve: Curves.easeInOut),
    )..addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        setState(() => _isDemoPlaying = false);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      TtsService.instance.speak(_def.label);
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _demoCtrl.dispose();
    super.dispose();
  }

  // ── Drawing gestures ──────────────────────────────────────────────────────

  void _onPanStart(DragStartDetails d, Size sz) {
    if (_checking || _isDemoPlaying) return;
    setState(() {
      _current = [_toLocal(d.localPosition, sz)];
    });
  }

  void _onPanUpdate(DragUpdateDetails d, Size sz) {
    if (_checking || _isDemoPlaying || _current.isEmpty) return;
    final pos = _toLocal(d.localPosition, sz);
    final last = _current.last;
    if ((pos - last).distance < 2.5) return;
    _trySnap(pos, sz);
    setState(() => _current.add(pos));
  }

  void _onPanEnd(DragEndDetails _, Size sz) {
    if (_current.isEmpty) return;
    setState(() {
      _strokes.add(List.of(_current));
      _current = [];
    });
  }

  Offset _toLocal(Offset pos, Size sz) =>
      Offset(pos.dx.clamp(0, sz.width), pos.dy.clamp(0, sz.height));

  void _trySnap(Offset pos, Size sz) {
    if (_checking) return;
    final nextIdx = _tapped;
    if (nextIdx >= _def.dots.length) return;
    final target = _px(_def.dots[nextIdx], sz);
    if ((target - pos).distance < _snapR) {
      SoundService.instance.playCorrect();
      setState(() => _tapped++);
    }
  }

  Offset _px(Offset norm, Size sz) => Offset(norm.dx * sz.width, norm.dy * sz.height);

  // ── Actions ───────────────────────────────────────────────────────────────

  void _onReset() {
    _demoCtrl.stop();
    setState(() {
      _strokes.clear();
      _current = [];
      _tapped  = 0;
      _celebrate = false;
      _checking = false;
      _isDemoPlaying = false;
    });
  }

  void _onDemo() {
    _onReset();
    setState(() => _isDemoPlaying = true);
    _demoCtrl.forward(from: 0.0);
  }

  Future<void> _onCheck(Size canvasSize) async {
    if (!_canCheck) return;
    final score = _computeAccuracy(canvasSize);
    setState(() {
      _checking = true;
      _celebrate = true;
    });

    SoundService.instance.playCorrect();
    final praise = score >= 7 ? PraiseCopy.letterTraced : 'Good job! Keep it up!';
    TtsService.instance.speakFunny(praise);
    await UserService.recordAnswer(correct: true);
    await UserService.addStars(1);

    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    if (_itemIndex >= widget.items.length - 1) {
      await UserService.completeLevel(widget.levelSlug);
      ProgressRepository.instance.recordLevelCompleteAndSync(widget.levelSlug, stars: 5);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/level_complete', arguments: {
        'starsEarned': 5,
        'title': widget.completionTitle,
      });
    } else {
      setState(() {
        _itemIndex++;
        _strokes.clear();
        _current = [];
        _tapped   = 0;
        _celebrate = false;
        _checking = false;
        _isDemoPlaying = false;
      });
      TtsService.instance.speak(_def.label);
    }
  }

  double _computeAccuracy(Size sz) {
    // Sample every 3rd drawn point, measure to nearest ghost edge, map 0-30px → 10-0 score
    final allPts = [..._strokes.expand((s) => s), ..._current];
    if (allPts.isEmpty) return 0;

    final ghostPxPaths = _def.ghost.map((path) =>
      path.map((p) => _px(p, sz)).toList()
    ).toList();

    double sumDist = 0;
    int count = 0;
    for (int i = 0; i < allPts.length; i += 3) {
      double minD = double.infinity;
      for (final path in ghostPxPaths) {
        for (int j = 0; j < path.length - 1; j++) {
          minD = min(minD, _ptSegDist(allPts[i], path[j], path[j + 1]));
        }
      }
      sumDist += minD.clamp(0, 40);
      count++;
    }
    if (count == 0) return 10;
    final avg = sumDist / count;
    return ((1 - avg / 40) * 10).clamp(0, 10);
  }

  double _ptSegDist(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (len2 == 0) return (p - a).distance;
    final t = ((p - a).dx * ab.dx + (p - a).dy * ab.dy) / len2;
    final proj = a + ab * t.clamp(0.0, 1.0);
    return (p - proj).distance;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8ECFA),
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          _buildProgressBar(),
          const SizedBox(height: 10),
          _buildMascot(),
          const SizedBox(height: 10),
          Expanded(child: _buildCanvas()),
          const SizedBox(height: 10),
          _buildToolbar(),
          const SizedBox(height: 10),
          _buildActionButtons(),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF2A2F45)),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          widget.title,
          style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF2A2F45)),
        ),
        const Spacer(),
        Text(
          '${_itemIndex + 1}/${widget.items.length}',
          style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF6B7186)),
        ),
      ]),
    );
  }

  // ── Progress bar ──────────────────────────────────────────────────────────

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: (_itemIndex + (_tapped / _def.dots.length.clamp(1, 99))) / widget.items.length,
          minHeight: 6,
          backgroundColor: Colors.white.withValues(alpha: 0.5),
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4A90D9)),
        ),
      ),
    );
  }

  // ── Mascot bubble ─────────────────────────────────────────────────────────

  Widget _buildMascot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.6),
          ),
          child: const CloudMascot(size: 48, animate: true),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Text(
              _instruction,
              style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF2A2F45)),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Canvas ────────────────────────────────────────────────────────────────

  Widget _buildCanvas() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LayoutBuilder(builder: (_, box) {
            final sz = Size(box.maxWidth, box.maxHeight);
            // Keep canvas size up-to-date for accuracy computation
            if (sz != _canvasSize) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _canvasSize = sz);
              });
            }
            return GestureDetector(
              onPanStart:  (d) => _onPanStart(d, sz),
              onPanUpdate: (d) => _onPanUpdate(d, sz),
              onPanEnd:    (d) => _onPanEnd(d, sz),
              child: AnimatedBuilder(
                animation: Listenable.merge([_pulseAnim, _demoAnim]),
                builder: (_, __) => CustomPaint(
                  size: sz,
                  painter: _TracePainter(
                    def:        _def,
                    strokes:    _strokes,
                    current:    _current,
                    tapped:     _tapped,
                    celebrate:  _celebrate,
                    penColor:   _penColor,
                    pulse:      _pulseAnim.value,
                    demoValue:  _isDemoPlaying ? _demoAnim.value : -1,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── Toolbar ───────────────────────────────────────────────────────────────

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        // Color swatches
        ...List.generate(_palette.length, (i) {
          final c = _palette[i];
          final selected = c == _penColor;
          return GestureDetector(
            onTap: () => setState(() => _penColor = c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 36, height: 36,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? Colors.white : Colors.transparent,
                  width: 3,
                ),
                boxShadow: selected ? [BoxShadow(color: c.withValues(alpha: 0.55), blurRadius: 10, spreadRadius: 1)] : [],
              ),
            ),
          );
        }),

        // Divider
        Container(width: 1.5, height: 28, color: const Color(0xFFCDD5E8), margin: const EdgeInsets.symmetric(horizontal: 6)),

        // Eraser (clears all strokes)
        GestureDetector(
          onTap: _onReset,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: const Icon(Icons.edit_off_rounded, size: 20, color: Color(0xFF6B7186)),
          ),
        ),
        const SizedBox(width: 8),
        // Reset / undo last stroke
        GestureDetector(
          onTap: () {
            if (_strokes.isNotEmpty) {
              setState(() {
                _strokes.removeLast();
                // Roll back tapped count to a safe value — recalculate from remaining strokes
                // Simpler: just reset tapped to 0 so child re-confirms progress
                _tapped  = 0;
                _celebrate = false;
                _checking = false;
              });
            }
          },
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF6B7186)),
          ),
        ),
      ]),
    );
  }

  // ── Action buttons ────────────────────────────────────────────────────────

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        // Ko'rsatib ber
        Expanded(
          child: GestureDetector(
            onTap: _isDemoPlaying ? null : _onDemo,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFCDD5E8), width: 1.5),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(
                  "Ko'rsatib ber",
                  style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF2A2F45)),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.play_arrow_rounded, color: Color(0xFF4A90D9), size: 20),
              ]),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Tekshirish — enabled once the child has drawn something; they
        // don't have to land every dot to avoid getting stuck.
        Expanded(
          child: GestureDetector(
            onTap: _canCheck ? () => _onCheck(_canvasSize) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 50,
              decoration: BoxDecoration(
                color: _canCheck ? const Color(0xFF4A90D9) : const Color(0xFFBEC5D8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  'Tekshirish',
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Painter ───────────────────────────────────────────────────────────────────

class _TracePainter extends CustomPainter {
  final TraceItemDef def;
  final List<List<Offset>> strokes;
  final List<Offset> current;
  final int tapped;
  final bool celebrate;
  final Color penColor;
  final double pulse;   // 0–1, for dot pulsing
  final double demoValue; // -1 = not playing; 0–1 = animation progress

  const _TracePainter({
    required this.def,
    required this.strokes,
    required this.current,
    required this.tapped,
    required this.celebrate,
    required this.penColor,
    required this.pulse,
    required this.demoValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawRuledLines(canvas, size);
    _drawGhost(canvas, size);
    if (demoValue >= 0) {
      _drawDemo(canvas, size);
    } else {
      _drawStrokes(canvas, size);
      _drawDots(canvas, size);
    }
    if (celebrate) _drawCelebration(canvas, size);
  }

  // ── Ruled notebook lines ─────────────────────────────────────────────────

  void _drawRuledLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD0D8EE)
      ..strokeWidth = 1.0;

    // Top solid (cap line) — content starts here
    final y1 = size.height * 0.18;
    canvas.drawLine(Offset(0, y1), Offset(size.width, y1), paint);

    // Middle dashed (midline reference)
    final y2 = size.height * 0.58;
    final dashPaint = Paint()
      ..color = const Color(0xFFD0D8EE)
      ..strokeWidth = 1.0;
    _drawDashedLine(canvas, Offset(0, y2), Offset(size.width, y2), dashPaint, 6, 6);

    // Bottom solid (baseline)
    final y3 = size.height * 0.90;
    canvas.drawLine(Offset(0, y3), Offset(size.width, y3), paint);
  }

  void _drawDashedLine(Canvas c, Offset a, Offset b, Paint p, double dash, double gap) {
    final dir = (b - a) / (b - a).distance;
    double dist = 0;
    final total = (b - a).distance;
    bool drawing = true;
    while (dist < total) {
      final seg = drawing ? dash : gap;
      final end = min(dist + seg, total);
      if (drawing) c.drawLine(a + dir * dist, a + dir * end, p);
      dist = end;
      drawing = !drawing;
    }
  }

  // ── Ghost outline ────────────────────────────────────────────────────────

  void _drawGhost(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC2CFEE)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final path in def.ghost) {
      if (path.length < 2) continue;
      final pts = path.map((p) => Offset(p.dx * size.width, p.dy * size.height)).toList();
      _drawDottedPath(canvas, pts, paint, 4.5, 7);
    }
  }

  void _drawDottedPath(Canvas c, List<Offset> pts, Paint p, double dotR, double gap) {
    final dotPaint = Paint()..color = p.color..style = PaintingStyle.fill;
    double dist = 0;
    double nextDot = 0;
    for (int i = 0; i < pts.length - 1; i++) {
      final seg = pts[i + 1] - pts[i];
      final len = seg.distance;
      if (len == 0) continue;
      final dir = seg / len;
      double walked = 0;
      while (walked < len) {
        if (dist >= nextDot) {
          c.drawCircle(pts[i] + dir * walked, dotR / 2, dotPaint);
          nextDot += gap;
        }
        final step = min(nextDot - dist, len - walked);
        walked += step;
        dist   += step;
      }
    }
  }

  // ── Drawn strokes ────────────────────────────────────────────────────────

  void _drawStrokes(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = penColor
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in [...strokes, current]) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke[0].dx, stroke[0].dy);
      for (int i = 1; i < stroke.length - 1; i++) {
        final mid = (stroke[i] + stroke[i + 1]) / 2;
        path.quadraticBezierTo(stroke[i].dx, stroke[i].dy, mid.dx, mid.dy);
      }
      path.lineTo(stroke.last.dx, stroke.last.dy);
      canvas.drawPath(path, paint);
    }

    // Draw single-point strokes as dots
    for (final stroke in [...strokes, current]) {
      if (stroke.length == 1) {
        canvas.drawCircle(stroke[0], 3, paint);
      }
    }
  }

  // ── Demo animation ────────────────────────────────────────────────────────

  void _drawDemo(Canvas canvas, Size size) {
    // Flatten all ghost paths into a single ordered list
    final flat = <(Offset, bool)>[];
    for (final path in def.ghost) {
      for (int i = 0; i < path.length; i++) {
        flat.add((Offset(path[i].dx * size.width, path[i].dy * size.height), i == 0));
      }
    }
    if (flat.length < 2) return;

    // Map demoValue 0-1 → 0..flat.length-1
    final progress = demoValue * (flat.length - 1);
    final fullIdx  = progress.floor().clamp(0, flat.length - 2);
    final frac     = progress - fullIdx;

    final paint = Paint()
      ..color = penColor
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Draw all fully-completed segments
    Path? path;
    for (int i = 0; i < fullIdx; i++) {
      final (pt, isNew) = flat[i];
      final (ptNext, nextIsNew) = flat[i + 1];
      if (isNew || path == null) {
        path = Path()..moveTo(pt.dx, pt.dy);
      }
      if (!nextIsNew) {
        path.lineTo(ptNext.dx, ptNext.dy);
      } else {
        canvas.drawPath(path, paint);
        path = null;
      }
    }
    if (path != null) canvas.drawPath(path, paint);

    // Partial current segment
    final (curPt, curIsNew) = flat[fullIdx];
    final (nxtPt, nxtIsNew) = flat[fullIdx + 1];
    if (!nxtIsNew) {
      final partialEnd = curPt + (nxtPt - curPt) * frac;
      canvas.drawLine(curPt, partialEnd, paint);
      // Moving pencil tip
      canvas.drawCircle(partialEnd, 7,
        Paint()..color = penColor.withValues(alpha: 0.35)..style = PaintingStyle.fill);
      canvas.drawCircle(partialEnd, 4, Paint()..color = penColor..style = PaintingStyle.fill);
    }
  }

  // ── Dots ─────────────────────────────────────────────────────────────────

  void _drawDots(Canvas canvas, Size size) {
    for (int i = 0; i < def.dots.length; i++) {
      final px = Offset(def.dots[i].dx * size.width, def.dots[i].dy * size.height);
      if (i < tapped) {
        _drawVisitedDot(canvas, px);
      } else if (i == tapped) {
        _drawCurrentDot(canvas, px, i + 1);
      } else {
        _drawFutureDot(canvas, px, i + 1);
      }
    }
  }

  void _drawVisitedDot(Canvas canvas, Offset center) {
    // Green filled circle
    canvas.drawCircle(center, 14, Paint()..color = const Color(0xFF4CAF50)..style = PaintingStyle.fill);
    // White checkmark
    final p = Paint()..color = Colors.white..strokeWidth = 2.5..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(center.dx - 5, center.dy)
      ..lineTo(center.dx - 1, center.dy + 4)
      ..lineTo(center.dx + 6, center.dy - 5);
    canvas.drawPath(path, p);
  }

  void _drawCurrentDot(Canvas canvas, Offset center, int num) {
    // Pulsing outer ring
    final ringR = 14 + 10 * pulse;
    canvas.drawCircle(center, ringR,
      Paint()..color = const Color(0xFFFF8C42).withValues(alpha: (0.35 * (1 - pulse)))..style = PaintingStyle.fill);
    // Orange filled circle
    canvas.drawCircle(center, 14, Paint()..color = const Color(0xFFFF8C42)..style = PaintingStyle.fill);
    // Number
    _drawNumber(canvas, center, num, Colors.white);
    // Pencil emoji below
    final tp = TextPainter(
      text: const TextSpan(text: '✏️', style: TextStyle(fontSize: 14)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center + Offset(-tp.width / 2, 18));
  }

  void _drawFutureDot(Canvas canvas, Offset center, int num) {
    canvas.drawCircle(center, 14, Paint()..color = const Color(0xFFBEC5D8)..style = PaintingStyle.fill);
    _drawNumber(canvas, center, num, Colors.white);
  }

  void _drawNumber(Canvas canvas, Offset center, int num, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: '$num',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: color,
          fontFamily: 'Nunito',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  // ── Celebration overlay ───────────────────────────────────────────────────

  void _drawCelebration(Canvas canvas, Size size) {
    final rng = Random(42);
    final confettiColors = [
      const Color(0xFF4A90D9), const Color(0xFFE0567B),
      const Color(0xFF4CAF50), const Color(0xFFFFC107), const Color(0xFF9C27B0),
    ];
    final p = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 24; i++) {
      p.color = confettiColors[i % confettiColors.length].withValues(alpha: 0.7);
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height * 0.4;
      canvas.drawCircle(Offset(x, y), 4, p);
    }
  }

  @override
  bool shouldRepaint(_TracePainter old) => true;
}