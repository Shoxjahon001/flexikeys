import 'package:flutter/material.dart';
import 'coloring_item_def.dart';

// Mashina (Car) — traced from a 1170x1093 source asset.
final ColoringItemDef _mashina = ColoringItemDef.detailed(
  label: 'Mashina',
  canvasSize: const Size(1170, 1093),
  elements: [
    const ColoringElement.ring(
      points: [
        Offset(89, 625), Offset(109, 530), Offset(170, 443), Offset(253, 392),
        Offset(336, 377), Offset(407, 291), Offset(479, 240), Offset(630, 195),
        Offset(805, 222), Offset(942, 318), Offset(1015, 436), Offset(1040, 625),
      ],
      innerPoints: [
        Offset(98, 625), Offset(129, 510), Offset(194, 435), Offset(255, 401),
        Offset(341, 386), Offset(411, 300), Offset(485, 247), Offset(630, 204),
        Offset(773, 220), Offset(903, 293), Offset(987, 397), Offset(1029, 627),
      ],
    ),
    ColoringElement.ring(
      points: roundedRectPoints(x: 59, y: 626, w: 1013, h: 115, r: 22),
      innerPoints: roundedRectPoints(x: 69, y: 636, w: 993, h: 95, r: 12),
    ),
    const ColoringElement.ring(
      points: [
        Offset(369, 415), Offset(369, 554), Offset(408, 594), Offset(437, 605),
        Offset(604, 605), Offset(623, 600), Offset(644, 582), Offset(654, 555), Offset(654, 419),
      ],
      innerPoints: [
        Offset(379, 420), Offset(378, 550), Offset(420, 591), Offset(436, 596),
        Offset(604, 596), Offset(622, 590), Offset(639, 573), Offset(645, 555), Offset(645, 419),
      ],
    ),
    const ColoringElement.ring(
      points: [
        Offset(654, 238), Offset(654, 415), Offset(369, 415), Offset(385, 387),
        Offset(438, 325), Offset(500, 280), Offset(579, 248), Offset(654, 238),
      ],
      innerPoints: [
        Offset(645, 249), Offset(644, 410), Offset(383, 409), Offset(426, 350),
        Offset(458, 320), Offset(496, 293), Offset(570, 260), Offset(614, 250), Offset(645, 249),
      ],
    ),
    const ColoringElement.ring(
      points: [
        Offset(682, 238), Offset(762, 252), Offset(839, 287), Offset(912, 348),
        Offset(960, 419), Offset(682, 419), Offset(682, 238),
      ],
      innerPoints: [
        Offset(691, 249), Offset(725, 252), Offset(764, 262), Offset(836, 296),
        Offset(873, 323), Offset(904, 353), Offset(944, 409), Offset(692, 410), Offset(691, 249),
      ],
    ),
    // WheelFront: tire + hub, two concentric rings
    ColoringElement.ring(
      points: ellipsePoints(cx: 286.0, cy: 695.8, rx: 136.5, ry: 136.5, segments: 40),
      innerPoints: ellipsePoints(cx: 286.0, cy: 695.8, rx: 127.7, ry: 127.7, segments: 40),
    ),
    ColoringElement.ring(
      points: ellipsePoints(cx: 286.0, cy: 695.8, rx: 60.3, ry: 60.3, segments: 32),
      innerPoints: ellipsePoints(cx: 286.0, cy: 695.8, rx: 51.3, ry: 51.3, segments: 32),
    ),
    // WheelRear: tire + hub
    ColoringElement.ring(
      points: ellipsePoints(cx: 832.8, cy: 695.8, rx: 136.5, ry: 136.5, segments: 40),
      innerPoints: ellipsePoints(cx: 832.8, cy: 695.8, rx: 127.7, ry: 127.7, segments: 40),
    ),
    ColoringElement.ring(
      points: ellipsePoints(cx: 832.8, cy: 695.8, rx: 60.3, ry: 60.3, segments: 32),
      innerPoints: ellipsePoints(cx: 832.8, cy: 695.8, rx: 51.3, ry: 51.3, segments: 32),
    ),
  ],
);

// Avtobus (Bus) — traced from a 1108x1011 source asset. The body's exact
// inner edge wasn't separately measured in the source (only the 6px stroke
// width), so its inner ring is a uniform synthetic inset of the outer edge.
final ColoringItemDef _avtobus = ColoringItemDef.detailed(
  label: 'Avtobus',
  canvasSize: const Size(1108, 1011),
  elements: [
    ColoringElement.ring(
      points: const [
        Offset(177, 186), Offset(1019, 190), Offset(1057, 218), Offset(1070, 262),
        Offset(1068, 617), Offset(1043, 638), Offset(82, 638), Offset(53, 620),
        Offset(45, 472), Offset(69, 303), Offset(112, 222),
      ],
      innerPoints: offsetTowardCentroid(const [
        Offset(177, 186), Offset(1019, 190), Offset(1057, 218), Offset(1070, 262),
        Offset(1068, 617), Offset(1043, 638), Offset(82, 638), Offset(53, 620),
        Offset(45, 472), Offset(69, 303), Offset(112, 222),
      ], 6),
    ),
    const ColoringElement.ring(
      points: [
        Offset(188, 233), Offset(350, 233), Offset(350, 372), Offset(320, 379),
        Offset(274, 401), Offset(216, 441), Offset(144, 504), Offset(120, 515),
        Offset(107, 513), Offset(103, 405), Offset(109, 358), Offset(125, 299),
        Offset(148, 258), Offset(164, 243), Offset(188, 233),
      ],
      innerPoints: [
        Offset(193, 237), Offset(344, 237), Offset(345, 367), Offset(268, 399),
        Offset(208, 441), Offset(139, 502), Offset(111, 510), Offset(107, 416),
        Offset(113, 362), Offset(127, 307), Offset(151, 262), Offset(173, 243), Offset(193, 237),
      ],
    ),
    ColoringElement.ring(
      points: roundedRectPoints(x: 392, y: 233, w: 177, h: 140, r: 12),
      innerPoints: roundedRectPoints(x: 396, y: 237, w: 168, h: 131, r: 8),
    ),
    ColoringElement.ring(
      points: roundedRectPoints(x: 612, y: 233, w: 177, h: 140, r: 12),
      innerPoints: roundedRectPoints(x: 616, y: 237, w: 168, h: 131, r: 8),
    ),
    ColoringElement.ring(
      points: roundedRectPoints(x: 831, y: 233, w: 195, h: 140, r: 14),
      innerPoints: roundedRectPoints(x: 836, y: 237, w: 186, h: 131, r: 10),
    ),
    ColoringElement.ring(
      points: ellipsePoints(cx: 290.7, cy: 605.2, rx: 116.0, ry: 116.0, segments: 40),
      innerPoints: ellipsePoints(cx: 290.7, cy: 605.2, rx: 110.5, ry: 110.5, segments: 40),
    ),
    ColoringElement.ring(
      points: ellipsePoints(cx: 290.7, cy: 605.2, rx: 64.8, ry: 64.8, segments: 32),
      innerPoints: ellipsePoints(cx: 290.7, cy: 605.2, rx: 60.2, ry: 60.2, segments: 32),
    ),
    ColoringElement.ring(
      points: ellipsePoints(cx: 811.6, cy: 605.2, rx: 116.0, ry: 116.0, segments: 40),
      innerPoints: ellipsePoints(cx: 811.6, cy: 605.2, rx: 110.5, ry: 110.5, segments: 40),
    ),
    ColoringElement.ring(
      points: ellipsePoints(cx: 811.6, cy: 605.2, rx: 64.8, ry: 64.8, segments: 32),
      innerPoints: ellipsePoints(cx: 811.6, cy: 605.2, rx: 60.2, ry: 60.2, segments: 32),
    ),
  ],
);

// Samolyot (Airplane) — traced from a 969x695 source asset. Only one edge of
// the fuselage/wings/tail-fin was measured precisely in the source; the
// other edge is a uniform synthetic offset (see [offsetTowardCentroid]).
final ColoringItemDef _samolyot = ColoringItemDef.detailed(
  label: 'Samolyot',
  canvasSize: const Size(969, 695),
  elements: [
    // Thin blade shapes (wings, tail fin): filled solid rather than RING —
    // a uniform centroid-based inner offset distorts/collapses shapes this
    // elongated, so a plain silhouette reads far cleaner at this scale.
    const ColoringElement.fill(points: [
      Offset(351, 176), Offset(459, 78), Offset(502, 48), Offset(523, 38),
      Offset(544, 34), Offset(557, 39), Offset(562, 45), Offset(563, 66),
      Offset(555, 89), Offset(500, 196),
    ]),
    const ColoringElement.fill(points: [
      Offset(340, 441), Offset(541, 426), Offset(640, 569), Offset(652, 599),
      Offset(648, 620), Offset(634, 631), Offset(615, 634), Offset(589, 627),
      Offset(548, 605), Offset(456, 540),
    ]),
    const ColoringElement.fill(points: [
      Offset(750, 247), Offset(778, 192), Offset(815, 164), Offset(860, 169),
      Offset(883, 205), Offset(883, 249), Offset(869, 279),
    ]),
    const ColoringElement.ring(
      points: [
        Offset(102, 374), Offset(115, 333), Offset(162, 300), Offset(284, 292),
        Offset(281, 240), Offset(270, 212), Offset(253, 197), Offset(278, 187),
        Offset(330, 182), Offset(428, 190), Offset(760, 251), Offset(778, 203),
        Offset(812, 171), Offset(852, 172), Offset(876, 201), Offset(869, 279),
        Offset(850, 343), Offset(830, 380), Offset(585, 416), Offset(258, 436),
        Offset(161, 427), Offset(126, 409), Offset(102, 374),
      ],
      innerPoints: [
        Offset(109, 380), Offset(121, 341), Offset(166, 309), Offset(283, 301),
        Offset(280, 250), Offset(269, 219), Offset(254, 204), Offset(276, 195),
        Offset(328, 190), Offset(427, 198), Offset(752, 258), Offset(770, 210),
        Offset(806, 178), Offset(846, 179), Offset(868, 205), Offset(861, 277),
        Offset(842, 339), Offset(824, 373), Offset(586, 408), Offset(261, 428),
        Offset(166, 419), Offset(133, 402), Offset(109, 380),
      ],
    ),
    const ColoringElement.ring(
      points: [
        Offset(247, 200), Offset(258, 207), Offset(266, 217), Offset(275, 240),
        Offset(279, 274), Offset(277, 288), Offset(270, 292), Offset(181, 290),
        Offset(180, 287), Offset(189, 255), Offset(203, 230), Offset(218, 215), Offset(240, 199),
      ],
      innerPoints: [
        Offset(243, 208), Offset(251, 214), Offset(258, 223), Offset(266, 242),
        Offset(270, 271), Offset(268, 282), Offset(263, 285), Offset(190, 283),
        Offset(189, 280), Offset(197, 254), Offset(209, 233), Offset(222, 221), Offset(240, 208),
      ],
    ),
    ColoringElement.ring(
      points: ellipsePoints(cx: 406.3, cy: 276.1, rx: 29.5, ry: 29.5, segments: 28),
      innerPoints: ellipsePoints(cx: 406.3, cy: 276.1, rx: 24.0, ry: 24.0, segments: 28),
    ),
    ColoringElement.ring(
      points: ellipsePoints(cx: 506.2, cy: 281.6, rx: 29.5, ry: 29.5, segments: 28),
      innerPoints: ellipsePoints(cx: 506.2, cy: 281.6, rx: 24.0, ry: 24.0, segments: 28),
    ),
    ColoringElement.ring(
      points: ellipsePoints(cx: 598.1, cy: 285.4, rx: 29.5, ry: 29.5, segments: 28),
      innerPoints: ellipsePoints(cx: 598.1, cy: 285.4, rx: 24.0, ry: 24.0, segments: 28),
    ),
    ColoringElement.ring(
      points: ellipsePoints(cx: 802.5, cy: 327.5, rx: 46, ry: 29, rotation: 7 * 3.14159265 / 180, segments: 28),
      innerPoints: ellipsePoints(cx: 802.5, cy: 327.5, rx: 40, ry: 22, rotation: 7 * 3.14159265 / 180, segments: 28),
    ),
  ],
);

final List<ColoringItemDef> kTransportColoringItems = [
  _mashina,
  _avtobus,
  _samolyot,
];