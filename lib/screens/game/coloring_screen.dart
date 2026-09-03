import 'dart:math';
import 'package:flutter/material.dart';
import '../../design_system/design_system.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/cloud_mascot.dart';
import '../../services/user_service.dart';
import '../../services/tts_service.dart';
import '../../services/sound_service.dart';
import '../../services/progress/progress_repository.dart';
import '../../data/praise_copy.dart';
import '../../data/coloring_items/coloring_item_def.dart';

/// Generic free-paint coloring game — used by the Fruits, Animals, Nature,
/// and Transport coloring tasks. Same design and mechanics everywhere; only
/// the content (items), header title, level-progress slug, and instruction
/// noun differ per caller.
///
/// Unlike [TraceDrawingScreen] this is not accuracy-scored: the child paints
/// freely over the line art with a finger and decides for themselves when
/// they're done (the "Ready" button enables as soon as anything is
/// painted). There is no "correct" color and no failure state.
class ColoringScreen extends StatefulWidget {
  final String title;
  final List<ColoringItemDef> items;
  final String levelSlug;
  final String completionTitle;

  const ColoringScreen({
    super.key,
    required this.title,
    required this.items,
    required this.levelSlug,
    required this.completionTitle,
  });

  @override
  State<ColoringScreen> createState() => _ColoringScreenState();
}

class _PaintStroke {
  final List<Offset> points;
  final Color color;
  _PaintStroke(this.points, this.color);
}

class _ColoringScreenState extends State<ColoringScreen> {
  // ── State ─────────────────────────────────────────────────────────────────

  int _itemIndex = 0;

  final List<_PaintStroke> _strokes = [];
  List<Offset> _current = [];

  bool _checking = false;
  bool _celebrate = false;

  Color _penColor = FkColors.coral;
  Size _canvasSize = const Size(320, 380);

  ColoringItemDef get _def => widget.items[_itemIndex];

  bool get _canFinish =>
      !_checking && (_strokes.isNotEmpty || _current.isNotEmpty);

  String _locale(BuildContext context) =>
      Localizations.localeOf(context).languageCode;

  String _instruction(BuildContext context) => AppLocalizations.of(context)!
      .coloringInstructionFor(_def.labelFor(_locale(context)));

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final locale = _locale(context);
      TtsService.instance.speak(_def.labelFor(locale), locale: locale);
    });
  }

  // ── Painting gestures ─────────────────────────────────────────────────────

  void _onPanStart(DragStartDetails d, Size sz) {
    if (_checking) return;
    setState(() {
      _current = [_toLocal(d.localPosition, sz)];
    });
  }

  void _onPanUpdate(DragUpdateDetails d, Size sz) {
    if (_checking || _current.isEmpty) return;
    final pos = _toLocal(d.localPosition, sz);
    final last = _current.last;
    if ((pos - last).distance < 2.5) return;
    setState(() => _current.add(pos));
  }

  void _onPanEnd(DragEndDetails _, Size sz) {
    if (_current.isEmpty) return;
    setState(() {
      _strokes.add(_PaintStroke(List.of(_current), _penColor));
      _current = [];
    });
  }

  Offset _toLocal(Offset pos, Size sz) =>
      Offset(pos.dx.clamp(0, sz.width), pos.dy.clamp(0, sz.height));

  // ── Actions ───────────────────────────────────────────────────────────────

  void _onClear() {
    setState(() {
      _strokes.clear();
      _current = [];
      _celebrate = false;
      _checking = false;
    });
  }

  Future<void> _onFinish() async {
    if (!_canFinish) return;
    setState(() {
      _checking = true;
      _celebrate = true;
    });

    SoundService.instance.playCorrect();
    TtsService.instance.speakFunny(PraiseCopy.shapeTraced(context),
        locale: _locale(context));
    await UserService.recordAnswer(correct: true);
    await UserService.addStars(1);

    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    if (_itemIndex >= widget.items.length - 1) {
      await UserService.completeLevel(widget.levelSlug);
      ProgressRepository.instance
          .recordLevelCompleteAndSync(widget.levelSlug, stars: 5);
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
        _celebrate = false;
        _checking = false;
      });
      final locale = _locale(context);
      TtsService.instance.speak(_def.labelFor(locale), locale: locale);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final fk = FkPlayTheme.of(context);
    return Scaffold(
      backgroundColor: fk.background,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(fk),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                FkSpacing.sm, FkSpacing.xs, FkSpacing.sm, 0),
            child: FkStepPills(total: widget.items.length, current: _itemIndex),
          ),
          const SizedBox(height: FkSpacing.xs),
          _buildMascot(context, fk),
          const SizedBox(height: FkSpacing.xs),
          // Square canvas — the line-art coordinates are normalized 0-1 in
          // both axes, so a non-square canvas would stretch every shape.
          Expanded(
            child: Center(
              child: AspectRatio(aspectRatio: 1, child: _buildCanvas(fk)),
            ),
          ),
          const SizedBox(height: FkSpacing.xs),
          _buildToolbar(fk),
          const SizedBox(height: FkSpacing.xs),
          _buildActionButton(context, fk),
          const SizedBox(height: FkSpacing.sm),
        ]),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(FkPlayTheme fk) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          FkSpacing.sm, FkSpacing.xs, FkSpacing.sm, 0),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: fk.surface,
              borderRadius: FkRadii.smAll,
              boxShadow: FkElevation.low(fk.ink),
            ),
            child:
                Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: fk.ink),
          ),
        ),
        const SizedBox(width: FkSpacing.xs),
        Flexible(
          child: Text(widget.title,
              overflow: TextOverflow.ellipsis,
              style: FkTextStyles.playHeadline
                  .copyWith(fontSize: 19, color: fk.ink)),
        ),
        const Spacer(),
        Text(
          '${_itemIndex + 1}/${widget.items.length}',
          style: FkTextStyles.playCaption
              .copyWith(fontSize: 15, color: fk.inkSoft),
        ),
      ]),
    );
  }

  // ── Mascot bubble ─────────────────────────────────────────────────────────

  Widget _buildMascot(BuildContext context, FkPlayTheme fk) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FkSpacing.sm),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fk.secondary.withValues(alpha: 0.18),
          ),
          child: const CloudMascot(size: 48, animate: true),
        ),
        const SizedBox(width: FkSpacing.xs),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: fk.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: FkElevation.low(fk.ink),
            ),
            child: Text(
              _instruction(context),
              style:
                  FkTextStyles.playBody.copyWith(fontSize: 15, color: fk.ink),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Canvas ────────────────────────────────────────────────────────────────

  Widget _buildCanvas(FkPlayTheme fk) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FkSpacing.sm),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: fk.surface,
          borderRadius: FkRadii.mdAll,
          boxShadow: FkElevation.medium(fk.ink),
        ),
        child: ClipRRect(
          borderRadius: FkRadii.mdAll,
          child: LayoutBuilder(builder: (_, box) {
            final sz = Size(box.maxWidth, box.maxHeight);
            if (sz != _canvasSize) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _canvasSize = sz);
              });
            }

            if (_def.isDetailed) {
              final native = _def.canvasSize!;
              final scale =
                  min(sz.width / native.width, sz.height / native.height);
              final rendered =
                  Size(native.width * scale, native.height * scale);
              return Center(
                child: SizedBox(
                  width: rendered.width,
                  height: rendered.height,
                  child: GestureDetector(
                    onPanStart: (d) => _onPanStart(d, rendered),
                    onPanUpdate: (d) => _onPanUpdate(d, rendered),
                    onPanEnd: (d) => _onPanEnd(d, rendered),
                    child: CustomPaint(
                      size: rendered,
                      painter: _DetailedColoringPainter(
                        def: _def,
                        strokes: _strokes,
                        current: _current,
                        penColor: _penColor,
                        celebrate: _celebrate,
                        outlineColor: fk.inkSoft,
                        confettiColors: FkColors.playful,
                        scale: scale,
                      ),
                    ),
                  ),
                ),
              );
            }

            return GestureDetector(
              onPanStart: (d) => _onPanStart(d, sz),
              onPanUpdate: (d) => _onPanUpdate(d, sz),
              onPanEnd: (d) => _onPanEnd(d, sz),
              child: CustomPaint(
                size: sz,
                painter: _ColoringPainter(
                  def: _def,
                  strokes: _strokes,
                  current: _current,
                  penColor: _penColor,
                  celebrate: _celebrate,
                  outlineColor: fk.inkSoft,
                  confettiColors: FkColors.playful,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── Toolbar ───────────────────────────────────────────────────────────────

  Widget _buildToolbar(FkPlayTheme fk) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: FkSpacing.sm + FkSpacing.xxs),
      child: Row(children: [
        ...List.generate(FkColors.playful.length, (i) {
          final c = FkColors.playful[i];
          final selected = c == _penColor;
          return GestureDetector(
            onTap: () => setState(() => _penColor = c),
            child: AnimatedContainer(
              duration: FkDurations.fast,
              width: 44,
              height: 44,
              margin: const EdgeInsets.only(right: FkSpacing.xs),
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? Colors.white : Colors.transparent,
                  width: 3,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                            color: c.withValues(alpha: 0.55),
                            blurRadius: 10,
                            spreadRadius: 1)
                      ]
                    : [],
              ),
            ),
          );
        }),

        const Spacer(),

        // Eraser (clears all paint)
        GestureDetector(
          onTap: _onClear,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: fk.surface,
              borderRadius: FkRadii.xsAll,
              boxShadow: FkElevation.low(fk.ink),
            ),
            child: Icon(Icons.edit_off_rounded, size: 22, color: fk.inkSoft),
          ),
        ),
      ]),
    );
  }

  // ── Action button ─────────────────────────────────────────────────────────

  Widget _buildActionButton(BuildContext context, FkPlayTheme fk) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FkSpacing.sm),
      child: GestureDetector(
        onTap: _canFinish ? _onFinish : null,
        child: AnimatedContainer(
          duration: FkDurations.fast,
          height: FkTouchTargets.child,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _canFinish ? fk.primary : fk.disabled,
            borderRadius: FkRadii.smAll,
          ),
          child: Center(
            child: Text(
              AppLocalizations.of(context)!.colorReadyButton,
              style: FkTextStyles.playLabel
                  .copyWith(color: Colors.white, fontSize: 17),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared painter helpers ──────────────────────────────────────────────────

void _paintFreehandStrokes(Canvas canvas, List<_PaintStroke> strokes,
    List<Offset> current, Color penColor) {
  for (final s in strokes) {
    _paintFreehandStroke(canvas, s.points, s.color);
  }
  _paintFreehandStroke(canvas, current, penColor);
}

void _paintFreehandStroke(Canvas canvas, List<Offset> pts, Color color) {
  if (pts.length < 2) {
    if (pts.length == 1) {
      canvas.drawCircle(
          pts[0],
          11,
          Paint()
            ..color = color
            ..style = PaintingStyle.fill);
    }
    return;
  }
  final paint = Paint()
    ..color = color
    ..strokeWidth = 22
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;
  final path = Path()..moveTo(pts[0].dx, pts[0].dy);
  for (int i = 1; i < pts.length - 1; i++) {
    final mid = (pts[i] + pts[i + 1]) / 2;
    path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
  }
  path.lineTo(pts.last.dx, pts.last.dy);
  canvas.drawPath(path, paint);
}

void _paintCelebration(Canvas canvas, Size size, List<Color> confettiColors) {
  final rng = Random(42);
  final p = Paint()..style = PaintingStyle.fill;
  for (int i = 0; i < 24; i++) {
    p.color = confettiColors[i % confettiColors.length].withValues(alpha: 0.7);
    final x = rng.nextDouble() * size.width;
    final y = rng.nextDouble() * size.height * 0.4;
    canvas.drawCircle(Offset(x, y), 4, p);
  }
}

// ── Legacy painter (simple normalized straight-line outline) ───────────────

class _ColoringPainter extends CustomPainter {
  final ColoringItemDef def;
  final List<_PaintStroke> strokes;
  final List<Offset> current;
  final Color penColor;
  final bool celebrate;
  final Color outlineColor;
  final List<Color> confettiColors;

  const _ColoringPainter({
    required this.def,
    required this.strokes,
    required this.current,
    required this.penColor,
    required this.celebrate,
    required this.outlineColor,
    required this.confettiColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintFreehandStrokes(canvas, strokes, current, penColor);
    _drawOutline(canvas, size);
    if (celebrate) _paintCelebration(canvas, size, confettiColors);
  }

  void _drawOutline(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = outlineColor
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final loop in def.outline!) {
      if (loop.length < 2) continue;
      final path = Path()
        ..moveTo(loop[0].dx * size.width, loop[0].dy * size.height);
      for (int i = 1; i < loop.length; i++) {
        path.lineTo(loop[i].dx * size.width, loop[i].dy * size.height);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_ColoringPainter old) => true;
}

// ── Detailed painter (RING/FILL/STROKE, pixel-traced art) ──────────────────

class _DetailedColoringPainter extends CustomPainter {
  final ColoringItemDef def;
  final List<_PaintStroke> strokes;
  final List<Offset> current;
  final Color penColor;
  final bool celebrate;
  final Color outlineColor;
  final List<Color> confettiColors;
  final double scale;

  const _DetailedColoringPainter({
    required this.def,
    required this.strokes,
    required this.current,
    required this.penColor,
    required this.celebrate,
    required this.outlineColor,
    required this.confettiColors,
    required this.scale,
  });

  Offset _s(Offset p) => Offset(p.dx * scale, p.dy * scale);
  List<Offset> _sAll(List<Offset> pts) => pts.map(_s).toList(growable: false);

  @override
  void paint(Canvas canvas, Size size) {
    _paintFreehandStrokes(canvas, strokes, current, penColor);
    for (final el in def.elements!) {
      switch (el.model) {
        case ColoringPaintModel.ring:
          final outer = buildElementPath(_sAll(el.points),
              closed: el.closed, smooth: el.smooth);
          final inner = buildElementPath(_sAll(el.innerPoints!),
              closed: el.closed, smooth: el.smooth);
          // Outer-minus-inner band: reproduces the double-edge contour
          // without filling the interior, so paint underneath stays visible.
          final band = Path.combine(PathOperation.difference, outer, inner);
          canvas.drawPath(
              band,
              Paint()
                ..color = outlineColor
                ..style = PaintingStyle.fill);
          break;
        case ColoringPaintModel.fill:
          final path = buildElementPath(_sAll(el.points),
              closed: el.closed, smooth: el.smooth);
          canvas.drawPath(
              path,
              Paint()
                ..color = outlineColor
                ..style = PaintingStyle.fill);
          break;
        case ColoringPaintModel.fillWithHoles:
          var path = buildElementPath(_sAll(el.points),
              closed: el.closed, smooth: el.smooth);
          for (final hole in el.holes) {
            final holePath = buildElementPath(_sAll(hole),
                closed: el.closed, smooth: el.smooth);
            path = Path.combine(PathOperation.difference, path, holePath);
          }
          canvas.drawPath(
              path,
              Paint()
                ..color = outlineColor
                ..style = PaintingStyle.fill);
          break;
        case ColoringPaintModel.stroke:
          final path = buildElementPath(_sAll(el.points),
              closed: el.closed, smooth: el.smooth);
          canvas.drawPath(
            path,
            Paint()
              ..color = outlineColor
              ..style = PaintingStyle.stroke
              ..strokeWidth = el.strokeWidth * scale
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round,
          );
          break;
      }
    }
    if (celebrate) _paintCelebration(canvas, size, confettiColors);
  }

  @override
  bool shouldRepaint(_DetailedColoringPainter old) => true;
}
