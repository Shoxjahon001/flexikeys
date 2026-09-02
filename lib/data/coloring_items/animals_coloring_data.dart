import 'package:flutter/material.dart';
import 'coloring_item_def.dart';

// Mushuk (Cat) — replaces the old hand-tuned normalized-outline cat with a
// faithful trace of a purpose-built 400x400 geometry (head/ears/inner-ear
// creases/eyes/muzzle/nose/mouth/whiskers), native pixel space via
// ColoringItemDef.detailed rather than degrading it into the legacy 0-1
// model. Stroke widths mirror the source geometry's own reference painter
// (CatHeadPainter): 7 for the main silhouette shapes, 4 for fine creases/
// nose, 6 for the mouth, 5 for whiskers. Left as outline-only (no .fill) so
// the child paints every part themselves, matching every other item here.
final ColoringItemDef _mushuk = ColoringItemDef.detailed(
  label: 'Mushuk',
  canvasSize: const Size(400, 400),
  elements: [
    // Head
    ColoringElement.stroke(
      strokeWidth: 7,
      closed: true,
      points: ellipsePoints(cx: 200, cy: 220, rx: 115, ry: 115, segments: 48),
    ),
    // Ears (outer)
    const ColoringElement.stroke(
      strokeWidth: 7,
      closed: true,
      smooth: false,
      points: [Offset(100, 163), Offset(84, 69), Offset(170, 109)],
    ),
    const ColoringElement.stroke(
      strokeWidth: 7,
      closed: true,
      smooth: false,
      points: [Offset(300, 163), Offset(316, 69), Offset(230, 109)],
    ),
    // Ears (inner crease)
    const ColoringElement.stroke(
      strokeWidth: 4,
      closed: true,
      smooth: false,
      points: [Offset(108, 141), Offset(99, 89), Offset(147, 111)],
    ),
    const ColoringElement.stroke(
      strokeWidth: 4,
      closed: true,
      smooth: false,
      points: [Offset(292, 141), Offset(301, 89), Offset(253, 111)],
    ),
    // Eyes
    ColoringElement.stroke(
      strokeWidth: 7,
      closed: true,
      points: ellipsePoints(cx: 155, cy: 200, rx: 22, ry: 22, segments: 24),
    ),
    ColoringElement.stroke(
      strokeWidth: 7,
      closed: true,
      points: ellipsePoints(cx: 245, cy: 200, rx: 22, ry: 22, segments: 24),
    ),
    // Muzzle
    ColoringElement.stroke(
      strokeWidth: 7,
      closed: true,
      points: ellipsePoints(cx: 200, cy: 272, rx: 52, ry: 34, segments: 32),
    ),
    // Nose
    const ColoringElement.stroke(
      strokeWidth: 4,
      closed: true,
      smooth: false,
      points: [Offset(185, 250), Offset(215, 250), Offset(200, 268)],
    ),
    // Mouth — a straight chin line then two curved smile lobes, matching
    // the source's moveTo/lineTo + two quadraticBezierTo subpaths exactly
    // (three disconnected strokes, same pattern as the banana/cherries
    // entries below for multi-part line art).
    const ColoringElement.stroke(
      strokeWidth: 6,
      points: [Offset(200, 268), Offset(200, 284)],
    ),
    ColoringElement.stroke(
      strokeWidth: 6,
      smooth: false,
      points: quadraticBezierPoints(
          const Offset(200, 284), const Offset(182, 302), const Offset(164, 288)),
    ),
    ColoringElement.stroke(
      strokeWidth: 6,
      smooth: false,
      points: quadraticBezierPoints(
          const Offset(200, 284), const Offset(218, 302), const Offset(236, 288)),
    ),
    // Whiskers
    const ColoringElement.stroke(
      strokeWidth: 5,
      points: [Offset(152, 278), Offset(66, 262)],
    ),
    const ColoringElement.stroke(
      strokeWidth: 5,
      points: [Offset(150, 290), Offset(62, 290)],
    ),
    const ColoringElement.stroke(
      strokeWidth: 5,
      points: [Offset(152, 302), Offset(66, 318)],
    ),
    const ColoringElement.stroke(
      strokeWidth: 5,
      points: [Offset(248, 278), Offset(334, 262)],
    ),
    const ColoringElement.stroke(
      strokeWidth: 5,
      points: [Offset(250, 290), Offset(338, 290)],
    ),
    const ColoringElement.stroke(
      strokeWidth: 5,
      points: [Offset(248, 302), Offset(334, 318)],
    ),
  ],
);

/// Not const: several shapes below are built with [ellipsePoints], a
/// function call that isn't const-evaluable.
final List<ColoringItemDef> kAnimalsColoringItems = [
  _mushuk,

  // Quyon (Rabbit) ───────────────────────────────────────────────────────────
  ColoringItemDef(label: 'Quyon', outline: [
    // Head
    ellipsePoints(cx: 0.50, cy: 0.62, rx: 0.24, ry: 0.26, segments: 32),
    // Left ear
    const [
      Offset(0.44, 0.60), Offset(0.40, 0.35), Offset(0.32, 0.15), Offset(0.28, 0.06),
      Offset(0.24, 0.16), Offset(0.26, 0.38), Offset(0.30, 0.58), Offset(0.44, 0.60),
    ],
    // Right ear
    const [
      Offset(0.56, 0.60), Offset(0.60, 0.35), Offset(0.68, 0.15), Offset(0.72, 0.06),
      Offset(0.76, 0.16), Offset(0.74, 0.38), Offset(0.70, 0.58), Offset(0.56, 0.60),
    ],
    // Eyes
    ellipsePoints(cx: 0.40, cy: 0.62, rx: 0.035, ry: 0.04, segments: 16),
    ellipsePoints(cx: 0.60, cy: 0.62, rx: 0.035, ry: 0.04, segments: 16),
    // Nose
    const [Offset(0.47, 0.70), Offset(0.53, 0.70), Offset(0.50, 0.735), Offset(0.47, 0.70)],
    // Mouth
    const [Offset(0.50, 0.735), Offset(0.50, 0.76), Offset(0.45, 0.79), Offset(0.50, 0.77), Offset(0.55, 0.79)],
    // Whiskers (left)
    const [Offset(0.28, 0.64), Offset(0.08, 0.61)],
    const [Offset(0.28, 0.68), Offset(0.06, 0.68)],
    const [Offset(0.28, 0.72), Offset(0.08, 0.76)],
    // Whiskers (right)
    const [Offset(0.72, 0.64), Offset(0.92, 0.61)],
    const [Offset(0.72, 0.68), Offset(0.94, 0.68)],
    const [Offset(0.72, 0.72), Offset(0.92, 0.76)],
  ]),

  // Baliq (Fish) ───────────────────────────────────────────────────────────
  ColoringItemDef(label: 'Baliq', outline: [
    // Body
    ellipsePoints(cx: 0.42, cy: 0.55, rx: 0.26, ry: 0.19, segments: 32),
    // Eye
    ellipsePoints(cx: 0.26, cy: 0.48, rx: 0.032, ry: 0.032, segments: 16),
    // Mouth (small pucker at the front tip)
    const [Offset(0.17, 0.53), Offset(0.20, 0.56), Offset(0.17, 0.59)],
    // Dorsal fin (single clean triangle sail on the back half)
    const [Offset(0.38, 0.38), Offset(0.50, 0.16), Offset(0.60, 0.37), Offset(0.38, 0.38)],
    // Pectoral (side) fin — small, centered on the belly, clear of the mouth
    const [Offset(0.36, 0.64), Offset(0.42, 0.74), Offset(0.28, 0.72), Offset(0.36, 0.64)],
    // Tail fin
    const [
      Offset(0.66, 0.42), Offset(0.88, 0.26), Offset(0.76, 0.55), Offset(0.88, 0.80),
      Offset(0.66, 0.68), Offset(0.66, 0.42),
    ],
  ]),
];