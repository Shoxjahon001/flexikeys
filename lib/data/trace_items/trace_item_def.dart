import 'package:flutter/material.dart';

/// One traceable item (a letter, digit, or simple object outline) for
/// [TraceDrawingScreen]. Canvas coordinate system: (0,0) = top-left,
/// (1,1) = bottom-right; content sits between y≈0.15 (cap line) and
/// y≈0.87 (baseline), matching the original letters content.
class TraceItemDef {
  /// Spoken by TTS and shown in the instruction text (e.g. 'A', '7', 'Uy').
  /// The default/fallback for every locale without its own [ruLabel] — for
  /// letters and digits this is locale-independent (a fine-motor tracing
  /// exercise over universal glyph shapes, not curriculum vocabulary), so
  /// no translation is needed there.
  final String label;

  /// Russian translation of [label], for items whose label is a real word
  /// (objects) rather than a universal glyph (letters/digits, which have
  /// no [ruLabel] and fall back to [label] via [labelFor]).
  final String? ruLabel;

  /// Normalized 0–1 waypoints visited in order 1..n.
  final List<Offset> dots;

  /// Polyline segments that together form the item's skeleton (the ghost
  /// guide the child traces over).
  final List<List<Offset>> ghost;

  const TraceItemDef({
    required this.label,
    this.ruLabel,
    required this.dots,
    required this.ghost,
  });

  /// The label to show/speak for [locale] — [ruLabel] when [locale] is
  /// `'ru'` and set, otherwise [label] (today's behavior, unchanged).
  String labelFor(String locale) =>
      (locale == 'ru' && ruLabel != null) ? ruLabel! : label;
}