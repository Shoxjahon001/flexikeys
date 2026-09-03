import 'dart:math';
import 'package:flutter/material.dart';
import 'coloring_item_def.dart';

// Gul's petals/leaves are generated ellipses (see ellipsePoints) rather than
// hand-typed polygon corners, so they read as properly rounded shapes. Each
// petal's near edge just touches the center circle rather than crossing
// through the opposite petal, so the middle reads as a clean junction
// instead of a tangled knot.
final ColoringItemDef _gul = ColoringItemDef(label: 'Gul', ruLabel: 'Цветок', outline: [
  // 4 petals in a plus arrangement, each just touching the center circle.
  ellipsePoints(cx: 0.50, cy: 0.325, rx: 0.085, ry: 0.115), // top
  ellipsePoints(cx: 0.675, cy: 0.50, rx: 0.115, ry: 0.085), // right
  ellipsePoints(cx: 0.50, cy: 0.675, rx: 0.085, ry: 0.115), // bottom
  ellipsePoints(cx: 0.325, cy: 0.50, rx: 0.115, ry: 0.085), // left
  // Flower center
  ellipsePoints(cx: 0.50, cy: 0.50, rx: 0.06, ry: 0.06),
  // Stem — starts below the bottom petal
  [const Offset(0.50, 0.79), const Offset(0.50, 0.92)],
  // Two small leaves angled off the stem
  ellipsePoints(cx: 0.40, cy: 0.84, rx: 0.055, ry: 0.028, rotation: -0.5),
  ellipsePoints(cx: 0.60, cy: 0.84, rx: 0.055, ry: 0.028, rotation: 0.5),
]);

// Daraxt (Tree) — traced from a 1113x1446 source asset (strokeWidth 35).
// The canopy's raw traced outline points don't form a clean non-crossing
// loop (the source spec itself flags that stretch as "est. ordering"), so
// the canopy is rebuilt procedurally as a 9-lobe scalloped blob sized to the
// same bounding box instead — same silhouette character, guaranteed clean.
// The trunk's traced points read coherently and are used as-is.
final ColoringItemDef _daraxt = ColoringItemDef.detailed(
  label: 'Daraxt',
  ruLabel: 'Дерево',
  canvasSize: const Size(1113, 1446),
  elements: [
    ColoringElement.stroke(
      strokeWidth: 35,
      closed: true,
      points: scallopedBlobPoints(
        cx: 576, cy: 520, baseRadius: 1.0, lobeAmplitude: 0.28,
        lobeCount: 9, phase: 0.4, rx: 460, ry: 340,
      ),
    ),
    const ColoringElement.stroke(
      strokeWidth: 35,
      closed: true,
      smooth: false,
      points: [
        Offset(556, 658), Offset(565, 700), Offset(592, 701), Offset(595, 723),
        Offset(599, 701), Offset(609, 718), Offset(660, 663), Offset(661, 744),
        Offset(729, 712), Offset(721, 740), Offset(746, 753),
        Offset(684, 867), Offset(666, 1028), Offset(691, 1205), Offset(749, 1388),
        Offset(703, 1367), Offset(650, 1389), Offset(610, 1356), Offset(543, 1391),
        Offset(515, 1381), Offset(473, 1400), Offset(452, 1376),
        Offset(500, 1227), Offset(500, 984), Offset(467, 834), Offset(399, 732),
        Offset(471, 771), Offset(478, 686), Offset(500, 710), Offset(517, 702),
        Offset(525, 722), Offset(526, 693), Offset(535, 712),
      ],
    ),
  ],
);

// Quyosh (Sun) — traced from a 926x887 source asset (strokeWidth 12).
final ColoringItemDef _quyosh = ColoringItemDef.detailed(
  label: 'Quyosh',
  ruLabel: 'Солнце',
  canvasSize: const Size(926, 887),
  elements: [
    // 14-spike ray star — kept faceted (smooth:false), a smoothed zigzag
    // would round away the sun-ray points.
    const ColoringElement.stroke(
      strokeWidth: 12,
      closed: true,
      smooth: false,
      points: [
        Offset(821, 513), Offset(702, 545), Offset(757, 678), Offset(618, 642),
        Offset(600, 759), Offset(493, 696), Offset(414, 804), Offset(351, 686),
        Offset(247, 716), Offset(240, 621), Offset(120, 638), Offset(170, 520),
        Offset(29, 477), Offset(146, 391), Offset(9, 288), Offset(183, 261),
        Offset(115, 100), Offset(272, 162), Offset(284, 32), Offset(396, 112),
        Offset(474, 41), Offset(529, 121), Offset(629, 67), Offset(638, 182),
        Offset(831, 121), Offset(717, 293), Offset(821, 351), Offset(737, 425),
      ],
    ),
    ColoringElement.stroke(
      strokeWidth: 12,
      closed: true,
      points: ellipsePoints(cx: 442.0, cy: 404.3, rx: 240.5, ry: 240.5, segments: 48),
    ),
    const ColoringElement.stroke(strokeWidth: 12, points: [
      Offset(321, 295), Offset(330, 282), Offset(343, 277), Offset(356, 282), Offset(360, 295),
    ]),
    const ColoringElement.stroke(strokeWidth: 12, points: [
      Offset(523, 295), Offset(533, 281), Offset(542, 277), Offset(552, 281), Offset(562, 295),
    ]),
    ColoringElement.fillWithHoles(
      points: ellipsePoints(cx: 339, cy: 351, rx: 34, ry: 44.5, rotation: 24 * pi / 180, segments: 32),
      holes: [
        ellipsePoints(cx: 348, cy: 339, rx: 16, ry: 16, segments: 16),
        ellipsePoints(cx: 331, cy: 362, rx: 8, ry: 8, segments: 12),
      ],
    ),
    ColoringElement.fillWithHoles(
      points: ellipsePoints(cx: 544, cy: 351, rx: 34, ry: 44.5, rotation: -24 * pi / 180, segments: 32),
      holes: [
        ellipsePoints(cx: 549, cy: 339, rx: 16, ry: 16, segments: 16),
        ellipsePoints(cx: 533, cy: 362, rx: 8, ry: 8, segments: 12),
      ],
    ),
    const ColoringElement.stroke(strokeWidth: 12, points: [
      Offset(342, 481), Offset(370, 510), Offset(405, 528), Offset(435, 533),
      Offset(465, 528), Offset(500, 510), Offset(528, 481),
    ]),
  ],
);

final List<ColoringItemDef> kNatureColoringItems = [
  _gul,
  _daraxt,
  _quyosh,
];