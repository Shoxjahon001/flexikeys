import 'package:flutter/material.dart';
import 'coloring_item_def.dart';

/// Not const: several shapes below are built with [ellipsePoints], a
/// function call that isn't const-evaluable.
final List<ColoringItemDef> kAnimalsColoringItems = [
  // Mushuk (Cat) ───────────────────────────────────────────────────────────
  ColoringItemDef(label: 'Mushuk', outline: [
    // Head
    ellipsePoints(cx: 0.50, cy: 0.60, rx: 0.27, ry: 0.25, segments: 32),
    // Left ear (outer) + inner crease
    const [Offset(0.30, 0.40), Offset(0.18, 0.10), Offset(0.44, 0.30), Offset(0.30, 0.40)],
    const [Offset(0.30, 0.34), Offset(0.26, 0.18), Offset(0.36, 0.26)],
    // Right ear (outer) + inner crease
    const [Offset(0.70, 0.40), Offset(0.82, 0.10), Offset(0.56, 0.30), Offset(0.70, 0.40)],
    const [Offset(0.70, 0.34), Offset(0.74, 0.18), Offset(0.64, 0.26)],
    // Eyebrows
    const [Offset(0.34, 0.48), Offset(0.40, 0.44), Offset(0.46, 0.47)],
    const [Offset(0.54, 0.47), Offset(0.60, 0.44), Offset(0.66, 0.48)],
    // Eyes
    ellipsePoints(cx: 0.40, cy: 0.58, rx: 0.045, ry: 0.05, segments: 16),
    ellipsePoints(cx: 0.60, cy: 0.58, rx: 0.045, ry: 0.05, segments: 16),
    // Nose
    const [Offset(0.47, 0.66), Offset(0.53, 0.66), Offset(0.50, 0.70), Offset(0.47, 0.66)],
    // Mouth
    const [Offset(0.50, 0.70), Offset(0.50, 0.735), Offset(0.44, 0.775), Offset(0.50, 0.75), Offset(0.56, 0.775)],
    // Whiskers (left)
    const [Offset(0.24, 0.60), Offset(0.05, 0.57)],
    const [Offset(0.24, 0.65), Offset(0.04, 0.65)],
    const [Offset(0.24, 0.70), Offset(0.05, 0.73)],
    // Whiskers (right)
    const [Offset(0.76, 0.60), Offset(0.95, 0.57)],
    const [Offset(0.76, 0.65), Offset(0.96, 0.65)],
    const [Offset(0.76, 0.70), Offset(0.95, 0.73)],
  ]),

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