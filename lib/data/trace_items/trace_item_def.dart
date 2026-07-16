import 'package:flutter/material.dart';

/// One traceable item (a letter, digit, or simple object outline) for
/// [TraceDrawingScreen]. Canvas coordinate system: (0,0) = top-left,
/// (1,1) = bottom-right; content sits between y≈0.15 (cap line) and
/// y≈0.87 (baseline), matching the original letters content.
class TraceItemDef {
  /// Spoken by TTS and shown in the instruction text (e.g. 'A', '7', 'Uy').
  final String label;

  /// Normalized 0–1 waypoints visited in order 1..n.
  final List<Offset> dots;

  /// Polyline segments that together form the item's skeleton (the ghost
  /// guide the child traces over).
  final List<List<Offset>> ghost;

  const TraceItemDef({
    required this.label,
    required this.dots,
    required this.ghost,
  });
}