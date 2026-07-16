library drawing_canvas;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/fk_tokens.dart';
import '../application/drawing_controller.dart';
import '../domain/drawing_models.dart';

/// Full-featured drawing canvas supporting all five drawing modes.
///
/// Input flows through the same dwell/debounce-aware gesture pipeline
/// as FkKeyboard — each pointer event emits telemetry via DrawingController.
class DrawingCanvas extends ConsumerStatefulWidget {
  final DrawingMode mode;
  final TracePath? tracePath;
  final List<ConnectDot> dots;
  final double traceTolerance;
  final String language;
  final String? skillKey;
  final void Function(TraceEvaluation)? onTraceComplete;
  final void Function(int dotNumber)? onDotConnected;

  const DrawingCanvas({
    super.key,
    required this.mode,
    this.tracePath,
    this.dots = const [],
    this.traceTolerance = 0.15,
    this.language = 'en',
    this.skillKey,
    this.onTraceComplete,
    this.onDotConnected,
  });

  @override
  ConsumerState<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends ConsumerState<DrawingCanvas> {
  late Size _canvasSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(drawingControllerProvider.notifier);
      controller.onTraceComplete = widget.onTraceComplete;
      controller.onDotConnected = widget.onDotConnected;
      controller.setMode(
        widget.mode,
        tracePath: widget.tracePath,
        traceTolerance: widget.traceTolerance,
        dots: widget.dots,
        skillKey: widget.skillKey,
      );
    });
  }

  @override
  void didUpdateWidget(DrawingCanvas old) {
    super.didUpdateWidget(old);
    if (old.mode != widget.mode || old.skillKey != widget.skillKey) {
      ref.read(drawingControllerProvider.notifier).setMode(
            widget.mode,
            tracePath: widget.tracePath,
            traceTolerance: widget.traceTolerance,
            dots: widget.dots,
            skillKey: widget.skillKey,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final drawState = ref.watch(drawingControllerProvider);

    return LayoutBuilder(builder: (context, constraints) {
      _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
      return Listener(
        onPointerDown: (e) => ref
            .read(drawingControllerProvider.notifier)
            .onPointerDown(e.localPosition, _canvasSize),
        onPointerMove: (e) => ref
            .read(drawingControllerProvider.notifier)
            .onPointerMove(e.localPosition, _canvasSize),
        onPointerUp: (e) => ref
            .read(drawingControllerProvider.notifier)
            .onPointerUp(e.localPosition, _canvasSize),
        child: CustomPaint(
          size: Size.infinite,
          painter: _DrawingPainter(
            state: drawState,
            canvasSize: _canvasSize,
            mode: widget.mode,
            tracePath: widget.tracePath,
          ),
        ),
      );
    });
  }
}

class _DrawingPainter extends CustomPainter {
  final DrawingState state;
  final Size canvasSize;
  final DrawingMode mode;
  final TracePath? tracePath;

  _DrawingPainter({
    required this.state,
    required this.canvasSize,
    required this.mode,
    this.tracePath,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = FkColors.cloud,
    );

    // Draw completed strokes
    for (final stroke in state.strokes) {
      _drawStroke(canvas, stroke, size);
    }

    // Draw current in-progress stroke
    if (state.currentStroke.isNotEmpty) {
      _drawStroke(canvas, state.currentStroke, size);
    }

    // Mode-specific overlays
    switch (mode) {
      case DrawingMode.tracing:
        _drawTracePath(canvas, size);
      case DrawingMode.connectDots:
        _drawDots(canvas, size);
        _drawConnectedLines(canvas, size);
      case DrawingMode.maze:
        _drawMazeBoundary(canvas, size);
      default:
        break;
    }
  }

  void _drawStroke(Canvas canvas, List<DrawPoint> pts, Size size) {
    if (pts.length < 2) return;

    final color = state.brushColor != null
        ? _parseHex(state.brushColor!)
        : FkColors.sky;

    final paint = Paint()
      ..color = color
      ..strokeWidth = state.brushSize
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(pts[0].x * size.width, pts[0].y * size.height);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].x * size.width, pts[i].y * size.height);
    }
    canvas.drawPath(path, paint);
  }

  void _drawTracePath(Canvas canvas, Size size) {
    if (tracePath == null || tracePath!.points.isEmpty) return;

    final ghostPaint = Paint()
      ..color = FkColors.lavender.withValues(alpha: 0.4)
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final pts = tracePath!.points;
    path.moveTo(pts[0][0] * size.width, pts[0][1] * size.height);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i][0] * size.width, pts[i][1] * size.height);
    }
    canvas.drawPath(path, ghostPaint);

    // Guide dot at the start
    if (!state.traceComplete) {
      final firstPt = pts[0];
      canvas.drawCircle(
        Offset(firstPt[0] * size.width, firstPt[1] * size.height),
        12,
        Paint()..color = FkColors.mint,
      );
    }
  }

  void _drawDots(Canvas canvas, Size size) {
    final numPaint = TextPainter(textDirection: TextDirection.ltr);

    for (final dot in state.dots) {
      final center = Offset(dot.x * size.width, dot.y * size.height);
      canvas.drawCircle(
        center,
        20,
        Paint()
          ..color = dot.connected ? FkColors.mint : FkColors.lavender,
      );

      numPaint.text = TextSpan(
        text: '${dot.number}',
        style: FkTextStyles.childBody.copyWith(color: FkColors.cloud),
      );
      numPaint.layout();
      numPaint.paint(
        canvas,
        center - Offset(numPaint.width / 2, numPaint.height / 2),
      );
    }
  }

  void _drawConnectedLines(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = FkColors.sky
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (final seg in state.connectedLines) {
      canvas.drawLine(
        Offset(seg[0] * size.width, seg[1] * size.height),
        Offset(seg[2] * size.width, seg[3] * size.height),
        linePaint,
      );
    }
  }

  void _drawMazeBoundary(Canvas canvas, Size size) {
    // Placeholder simple border maze
    final wallPaint = Paint()
      ..color = FkColors.lavender
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;

    final margin = size.width * 0.1;
    canvas.drawRect(
      Rect.fromLTRB(margin, margin, size.width - margin, size.height - margin),
      wallPaint,
    );
  }

  Color _parseHex(String hex) {
    final h = hex.replaceAll('#', '');
    if (h.length == 6) {
      return Color(int.parse('FF$h', radix: 16));
    }
    return FkColors.sky;
  }

  @override
  bool shouldRepaint(_DrawingPainter old) =>
      old.state != state ||
      old.canvasSize != canvasSize ||
      old.mode != mode;
}

/// Drawing toolbar — brush colors and sizes.
class DrawingToolbar extends StatelessWidget {
  final DrawingState state;
  final void Function(String) onColorSelected;
  final void Function(double) onSizeSelected;
  final VoidCallback onClear;

  static const _palette = [
    '#A8D8EA', // sky
    '#B8E6C9', // mint
    '#FFE7A0', // yellow
    '#D9D2F0', // lavender
    '#FFD9C7', // peach
    '#4A5568', // ink
  ];

  const DrawingToolbar({
    super.key,
    required this.state,
    required this.onColorSelected,
    required this.onSizeSelected,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: FkSpacing.sm),
      color: FkColors.cloud,
      child: Row(
        children: [
          // Colors
          for (final hex in _palette)
            GestureDetector(
              onTap: () => onColorSelected(hex),
              child: Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: _hexToColor(hex),
                  shape: BoxShape.circle,
                  border: state.brushColor == hex
                      ? Border.all(color: FkColors.ink, width: 2)
                      : null,
                ),
              ),
            ),
          const Spacer(),
          // Brush sizes
          for (final size in [8.0, 14.0, 20.0])
            GestureDetector(
              onTap: () => onSizeSelected(size),
              child: Container(
                width: size.clamp(24, 40),
                height: size.clamp(24, 40),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: FkColors.ink.withValues(
                    alpha: state.brushSize == size ? 0.8 : 0.3,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          const SizedBox(width: FkSpacing.sm),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: onClear,
            color: FkColors.inkSoft,
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}