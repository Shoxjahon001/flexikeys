library drawing_controller;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/drawing_models.dart';
import '../../../services/telemetry/telemetry_service.dart';

/// State for the drawing canvas.
class DrawingState {
  final DrawingMode mode;
  final List<List<DrawPoint>> strokes; // each entry = one finger drag
  final List<DrawPoint> currentStroke;
  final int nextDotIndex; // for connect-the-dots
  final List<ConnectDot> dots; // for connect-the-dots
  final List<List<double>> connectedLines; // [x1,y1,x2,y2] normalised
  final bool traceComplete;
  final String? brushColor;
  final double brushSize;

  const DrawingState({
    this.mode = DrawingMode.freePaint,
    this.strokes = const [],
    this.currentStroke = const [],
    this.nextDotIndex = 0,
    this.dots = const [],
    this.connectedLines = const [],
    this.traceComplete = false,
    this.brushColor,
    this.brushSize = 12,
  });

  DrawingState copyWith({
    DrawingMode? mode,
    List<List<DrawPoint>>? strokes,
    List<DrawPoint>? currentStroke,
    int? nextDotIndex,
    List<ConnectDot>? dots,
    List<List<double>>? connectedLines,
    bool? traceComplete,
    String? brushColor,
    double? brushSize,
  }) {
    return DrawingState(
      mode: mode ?? this.mode,
      strokes: strokes ?? this.strokes,
      currentStroke: currentStroke ?? this.currentStroke,
      nextDotIndex: nextDotIndex ?? this.nextDotIndex,
      dots: dots ?? this.dots,
      connectedLines: connectedLines ?? this.connectedLines,
      traceComplete: traceComplete ?? this.traceComplete,
      brushColor: brushColor ?? this.brushColor,
      brushSize: brushSize ?? this.brushSize,
    );
  }
}

/// Controller for the drawing canvas.
class DrawingController extends StateNotifier<DrawingState> {
  DrawingController() : super(const DrawingState());

  TracePath? _currentTracePath;
  double _traceTolerance = 0.15;
  String? _skillKey;
  void Function(TraceEvaluation)? onTraceComplete;
  void Function(int dotNumber)? onDotConnected;

  // ── Setup ──────────────────────────────────────────────────────────────────

  void setMode(
    DrawingMode mode, {
    TracePath? tracePath,
    double traceTolerance = 0.15,
    List<ConnectDot>? dots,
    String? skillKey,
  }) {
    _currentTracePath = tracePath;
    _traceTolerance = traceTolerance;
    _skillKey = skillKey;
    state = DrawingState(
      mode: mode,
      dots: dots ?? const [],
    );
  }

  void setBrushColor(String hexColor) {
    state = state.copyWith(brushColor: hexColor);
  }

  void setBrushSize(double size) {
    state = state.copyWith(brushSize: size);
  }

  // ── Gesture handlers ──────────────────────────────────────────────────────

  void onPointerDown(Offset position, Size canvasSize) {
    final pt = _makePoint(position, canvasSize);

    if (state.mode == DrawingMode.connectDots) {
      _handleDotTap(pt, canvasSize);
      return;
    }

    state = state.copyWith(currentStroke: [pt]);
  }

  void onPointerMove(Offset position, Size canvasSize) {
    if (state.mode == DrawingMode.connectDots) return;
    if (state.currentStroke.isEmpty) return;

    final pt = _makePoint(position, canvasSize);

    if (state.mode == DrawingMode.maze) {
      // Maze wall check — if hitting wall, bounce (don't advance)
      // Simplified: for now accept all movement; real collision
      // would test segment intersection with MazeWall list.
      state = state.copyWith(
        currentStroke: [...state.currentStroke, pt],
      );
    } else {
      state = state.copyWith(
        currentStroke: [...state.currentStroke, pt],
      );
    }

    // Emit trace_point telemetry
    TelemetryService.instance.enqueue({
      'occurred_at': DateTime.now().toIso8601String(),
      'payload': {
        'event_type': 'trace_point',
        'x': pt.x,
        'y': pt.y,
        'pressure': pt.pressure,
        'skill_key': _skillKey,
      },
    });
  }

  void onPointerUp(Offset position, Size canvasSize) {
    if (state.mode == DrawingMode.connectDots) return;
    if (state.currentStroke.isEmpty) return;

    final completed = List<DrawPoint>.from(state.currentStroke);
    final newStrokes = [...state.strokes, completed];

    state = state.copyWith(
      strokes: newStrokes,
      currentStroke: [],
    );

    // Evaluate trace on stroke complete
    if (state.mode == DrawingMode.tracing && _currentTracePath != null) {
      final eval = TraceEvaluator.evaluate(
        userStroke: completed,
        reference: _currentTracePath!,
        tolerance: _traceTolerance,
      );
      if (eval.passed) {
        state = state.copyWith(traceComplete: true);
        onTraceComplete?.call(eval);
      }
    }
  }

  // ── Connect-the-dots ──────────────────────────────────────────────────────

  void _handleDotTap(DrawPoint pt, Size canvasSize) {
    if (state.nextDotIndex >= state.dots.length) return;

    final targetDot = state.dots[state.nextDotIndex];
    final targetOffset = targetDot.toOffset(canvasSize);

    const tapRadius = 40.0; // pixels
    final dx = pt.x * canvasSize.width - targetOffset.dx;
    final dy = pt.y * canvasSize.height - targetOffset.dy;
    final dist = math.sqrt(dx * dx + dy * dy);

    if (dist <= tapRadius) {
      // Correct dot tapped
      final updatedDots = List<ConnectDot>.from(state.dots);
      updatedDots[state.nextDotIndex] = ConnectDot(
        number: targetDot.number,
        x: targetDot.x,
        y: targetDot.y,
        connected: true,
      );

      List<List<double>> newLines = List.from(state.connectedLines);
      if (state.nextDotIndex > 0) {
        final prev = state.dots[state.nextDotIndex - 1];
        newLines = [
          ...newLines,
          [prev.x, prev.y, targetDot.x, targetDot.y],
        ];
      }

      state = state.copyWith(
        dots: updatedDots,
        nextDotIndex: state.nextDotIndex + 1,
        connectedLines: newLines,
      );
      onDotConnected?.call(targetDot.number);
    }
    // Wrong dot: simply does nothing — no error, no reset
  }

  DrawPoint _makePoint(Offset position, Size canvasSize) {
    return DrawPoint(
      x: canvasSize.width > 0 ? position.dx / canvasSize.width : 0,
      y: canvasSize.height > 0 ? position.dy / canvasSize.height : 0,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  void clear() {
    state = DrawingState(mode: state.mode, brushColor: state.brushColor, brushSize: state.brushSize);
  }
}

final drawingControllerProvider =
    StateNotifierProvider<DrawingController, DrawingState>(
  (_) => DrawingController(),
);