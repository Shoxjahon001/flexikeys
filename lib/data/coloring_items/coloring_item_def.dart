import 'dart:math';
import 'package:flutter/material.dart';

/// One coloring-book picture for [ColoringScreen] — the child paints freely
/// over a line-art outline with a finger. There is no "correct" color or
/// region-fill accuracy check — the child decides when they're done.
///
/// Two content models are supported side by side:
///  - legacy [outline]: simple closed polylines, normalized 0-1, always
///    drawn as a single stroke width on a forced-square canvas.
///  - [ColoringItemDef.detailed] [elements]: pixel-traced art on the
///    picture's own native canvas size, with per-element paint models
///    ([ColoringElement.ring]/[.fill]/[.stroke]) and stroke widths, smoothed
///    with Catmull-Rom curves. Use this for pixel-accurate reproductions.
class ColoringItemDef {
  /// Spoken by TTS and shown in the instruction text (e.g. 'Olma'). The
  /// default/fallback for every locale without its own [ruLabel].
  final String label;

  /// Russian translation of [label] — see [labelFor].
  final String? ruLabel;

  /// Legacy content: one or more closed polylines, normalized 0-1. Null for
  /// [ColoringItemDef.detailed] items.
  final List<List<Offset>>? outline;

  /// Detailed content: the native pixel size the [elements] coordinates are
  /// authored in. Null for legacy items.
  final Size? canvasSize;

  /// Detailed content: paint elements in back-to-front z-order. Null for
  /// legacy items.
  final List<ColoringElement>? elements;

  bool get isDetailed => elements != null;

  const ColoringItemDef({
    required this.label,
    this.ruLabel,
    required this.outline,
  })  : canvasSize = null,
        elements = null;

  const ColoringItemDef.detailed({
    required this.label,
    this.ruLabel,
    required this.canvasSize,
    required this.elements,
  }) : outline = null;

  /// The label to show/speak for [locale] — [ruLabel] when [locale] is
  /// `'ru'` and set, otherwise [label] (today's behavior, unchanged).
  String labelFor(String locale) =>
      (locale == 'ru' && ruLabel != null) ? ruLabel! : label;
}

/// How a [ColoringElement] is painted. Matches the source-asset paint model
/// so pixel-traced art reproduces exactly:
///  - [ring]: a hollow band between an outer and inner edge path (e.g. a
///    thick double-line contour). Rendered as outer-minus-inner so the
///    interior stays transparent — the child's paint underneath still shows.
///  - [fill]: a solid permanent ink shape (e.g. an eye pupil, a banana tip).
///  - [fillWithHoles]: a solid ink shape with one or more punched-out
///    background-colored holes (e.g. an eye with white highlight dots).
///  - [stroke]: a centerline path drawn with a specific stroke width (e.g. a
///    crease line, a stem, a tick mark).
enum ColoringPaintModel { ring, fill, fillWithHoles, stroke }

class ColoringElement {
  final ColoringPaintModel model;

  /// Outer edge (ring/fill/fillWithHoles) or centerline (stroke), native
  /// pixel space.
  final List<Offset> points;

  /// Inner edge, ring only.
  final List<Offset>? innerPoints;

  /// Punched-out holes, fillWithHoles only.
  final List<List<Offset>> holes;

  /// Stroke only.
  final double strokeWidth;

  /// Whether [points] (and [innerPoints]/[holes]) form closed loops.
  final bool closed;

  /// Catmull-Rom smoothing (default) vs. straight faceted segments. Set to
  /// false for intentionally sharp/hand-drawn zigzags (e.g. sun rays, spiky
  /// crowns) where smoothing would round away the point.
  final bool smooth;

  const ColoringElement.ring({
    required this.points,
    required this.innerPoints,
    this.closed = true,
    this.smooth = true,
  })  : model = ColoringPaintModel.ring,
        holes = const [],
        strokeWidth = 0;

  const ColoringElement.fill({
    required this.points,
    this.closed = true,
    this.smooth = true,
  })  : model = ColoringPaintModel.fill,
        innerPoints = null,
        holes = const [],
        strokeWidth = 0;

  const ColoringElement.fillWithHoles({
    required this.points,
    required this.holes,
    this.closed = true,
    this.smooth = true,
  })  : model = ColoringPaintModel.fillWithHoles,
        innerPoints = null,
        strokeWidth = 0;

  const ColoringElement.stroke({
    required this.points,
    required this.strokeWidth,
    this.closed = false,
    this.smooth = true,
  })  : model = ColoringPaintModel.stroke,
        innerPoints = null,
        holes = const [];
}

/// Catmull-Rom smoothed path through [pts] (native pixel space, already
/// scaled by the caller) — pixel-traced art reads as hand-drawn curves
/// instead of a faceted polyline. Falls back to straight segments for
/// degenerate (<3 point) inputs.
Path smoothPath(List<Offset> pts, {required bool closed}) {
  final path = Path();
  if (pts.isEmpty) return path;
  path.moveTo(pts[0].dx, pts[0].dy);
  if (pts.length < 3) {
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    if (closed) path.close();
    return path;
  }

  final n = pts.length;
  int wrap(int i) => closed ? ((i % n) + n) % n : i.clamp(0, n - 1);
  final segments = closed ? n : n - 1;
  for (int i = 0; i < segments; i++) {
    final p0 = pts[wrap(i - 1)];
    final p1 = pts[wrap(i)];
    final p2 = pts[wrap(i + 1)];
    final p3 = pts[wrap(i + 2)];
    final cp1 = p1 + (p2 - p0) / 6;
    final cp2 = p2 - (p3 - p1) / 6;
    path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
  }
  if (closed) path.close();
  return path;
}

/// Straight-line polyline through [pts] — used instead of [smoothPath] for
/// intentionally sharp/hand-drawn zigzags where curve-smoothing would round
/// away the point (e.g. sun rays, spiky crowns).
Path straightPath(List<Offset> pts, {required bool closed}) {
  final path = Path();
  if (pts.isEmpty) return path;
  path.moveTo(pts[0].dx, pts[0].dy);
  for (final p in pts.skip(1)) {
    path.lineTo(p.dx, p.dy);
  }
  if (closed) path.close();
  return path;
}

/// Renders [pts] via [smoothPath] or [straightPath] depending on [smooth].
Path buildElementPath(List<Offset> pts, {required bool closed, required bool smooth}) =>
    smooth ? smoothPath(pts, closed: closed) : straightPath(pts, closed: closed);

/// Generates a closed rounded-rectangle outline as a point list, native
/// pixel space — used for door sills, window frames, and other boxy details
/// in pixel-traced vehicle art.
List<Offset> roundedRectPoints({
  required double x,
  required double y,
  required double w,
  required double h,
  required double r,
  int cornerSegments = 8,
}) {
  final pts = <Offset>[];
  void arc(double cx, double cy, double startDeg, double endDeg) {
    for (int i = 0; i <= cornerSegments; i++) {
      final t = startDeg + (endDeg - startDeg) * i / cornerSegments;
      final rad = t * pi / 180;
      pts.add(Offset(cx + r * cos(rad), cy + r * sin(rad)));
    }
  }

  arc(x + r, y + r, 180, 270);
  arc(x + w - r, y + r, 270, 360);
  arc(x + w - r, y + h - r, 0, 90);
  arc(x + r, y + h - r, 90, 180);
  return pts;
}

/// Moves every point in [pts] toward (positive [amount]) or away from
/// (negative [amount]) the point list's centroid by a fixed pixel distance.
/// Used to approximate a RING's inner edge from its outer edge (or vice
/// versa) when the source only measured one edge precisely — a uniform
/// synthetic border reads fine at this art's scale.
List<Offset> offsetTowardCentroid(List<Offset> pts, double amount) {
  final cx = pts.map((p) => p.dx).reduce((a, b) => a + b) / pts.length;
  final cy = pts.map((p) => p.dy).reduce((a, b) => a + b) / pts.length;
  final center = Offset(cx, cy);
  return pts.map((p) {
    final dir = center - p;
    final len = dir.distance;
    if (len < 1e-6) return p;
    return p + dir / len * amount;
  }).toList();
}

/// Generates a closed, N-lobed "cloud" silhouette (e.g. a scalloped tree
/// canopy) as a point list, native pixel space — a radius that wobbles
/// sinusoidally around [baseRadius] by ±[lobeAmplitude], [lobeCount] times
/// per revolution, squashed by [rx]/[ry]. Procedural, so it never
/// self-intersects (unlike a hand-typed lobed point list).
List<Offset> scallopedBlobPoints({
  required double cx,
  required double cy,
  required double baseRadius,
  required double lobeAmplitude,
  required int lobeCount,
  double phase = 0,
  double rx = 1,
  double ry = 1,
  int segments = 120,
}) {
  final pts = <Offset>[];
  for (int i = 0; i <= segments; i++) {
    final t = (i / segments) * 2 * pi;
    final r = baseRadius + lobeAmplitude * cos(lobeCount * t + phase);
    final x = cx + r * cos(t) * rx;
    final y = cy + r * sin(t) * ry;
    pts.add(Offset(x, y));
  }
  return pts;
}

/// Samples a quadratic Bezier curve (start [p0], control [p1], end [p2])
/// into a point list — for reproducing a source geometry's
/// `Path.quadraticBezierTo` curves as a [ColoringElement.stroke] (whose
/// points get Catmull-Rom-smoothed through, a different curve family than
/// a true quadratic Bezier; sampling densely here and letting the caller
/// pass `smooth: false` keeps the traced shape faithful to the original
/// curve instead of approximating it a second time).
List<Offset> quadraticBezierPoints(Offset p0, Offset p1, Offset p2, {int segments = 16}) {
  final pts = <Offset>[];
  for (int i = 0; i <= segments; i++) {
    final t = i / segments;
    final mt = 1 - t;
    final x = mt * mt * p0.dx + 2 * mt * t * p1.dx + t * t * p2.dx;
    final y = mt * mt * p0.dy + 2 * mt * t * p1.dy + t * t * p2.dy;
    pts.add(Offset(x, y));
  }
  return pts;
}

/// Samples a cubic Bezier curve (start [p0], controls [p1]/[p2], end [p3])
/// into a point list — the `Path.cubicTo` counterpart to
/// [quadraticBezierPoints], for reproducing a source geometry's cubic
/// curves. Same rationale: sample densely, pass `smooth: false`.
List<Offset> cubicBezierPoints(Offset p0, Offset p1, Offset p2, Offset p3, {int segments = 16}) {
  final pts = <Offset>[];
  for (int i = 0; i <= segments; i++) {
    final t = i / segments;
    final mt = 1 - t;
    final x = mt * mt * mt * p0.dx +
        3 * mt * mt * t * p1.dx +
        3 * mt * t * t * p2.dx +
        t * t * t * p3.dx;
    final y = mt * mt * mt * p0.dy +
        3 * mt * mt * t * p1.dy +
        3 * mt * t * t * p2.dy +
        t * t * t * p3.dy;
    pts.add(Offset(x, y));
  }
  return pts;
}

/// Chains several curve segments (each already sampled by
/// [quadraticBezierPoints]/[cubicBezierPoints]) into a single continuous
/// point list, dropping each segment's duplicate leading point (it equals
/// the previous segment's trailing point) — for silhouettes traced as one
/// unbroken multi-curve outline (e.g. a body built from several `cubicTo`
/// calls in sequence) rather than as separate disconnected strokes.
List<Offset> chainCurvePoints(List<List<Offset>> segments) {
  final pts = <Offset>[];
  for (final seg in segments) {
    pts.addAll(pts.isEmpty ? seg : seg.skip(1));
  }
  return pts;
}

/// Generates a closed, smooth-reading oval as a point list (normalized 0-1
/// space) — straight-line segments densely spaced enough to read as a
/// rounded curve at typical canvas sizes. Used for petals, leaves, and any
/// other rounded coloring-book shapes instead of hand-computing trig by eye.
List<Offset> ellipsePoints({
  required double cx,
  required double cy,
  required double rx,
  required double ry,
  double rotation = 0,
  int segments = 20,
}) {
  final pts = <Offset>[];
  for (int i = 0; i <= segments; i++) {
    final t = (i / segments) * 2 * pi;
    final ex = rx * cos(t);
    final ey = ry * sin(t);
    final x = cx + ex * cos(rotation) - ey * sin(rotation);
    final y = cy + ex * sin(rotation) + ey * cos(rotation);
    pts.add(Offset(x, y));
  }
  return pts;
}