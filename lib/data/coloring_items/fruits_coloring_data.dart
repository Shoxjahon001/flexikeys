import 'package:flutter/material.dart';
import 'coloring_item_def.dart';

// Banan (Banana) — traced from a 1160x976 source asset. The main silhouette
// is drawn as a thick STROKE along the (precisely measured) outer edge
// rather than RING+synthetic-inner: a banana is a thin curved crescent, and
// a uniform centroid-based inner offset distorts/self-intersects a shape
// this elongated (same lesson learned from the airplane's wings).
final ColoringItemDef _banan = ColoringItemDef.detailed(
  label: 'Banan',
  canvasSize: const Size(1160, 976),
  elements: [
    const ColoringElement.stroke(
      strokeWidth: 20,
      closed: true,
      points: [
        Offset(1108, 117), Offset(1087, 102), Offset(1016, 97), Offset(1008, 111),
        Offset(1011, 191), Offset(994, 217), Offset(869, 325), Offset(752, 369),
        Offset(647, 385), Offset(445, 372), Offset(218, 329), Offset(103, 291),
        Offset(34, 353), Offset(30, 376), Offset(53, 429), Offset(83, 467),
        Offset(206, 581), Offset(326, 665), Offset(411, 702), Offset(510, 726),
        Offset(615, 732), Offset(694, 719), Offset(804, 679), Offset(899, 625),
        Offset(971, 561), Offset(1023, 497), Offset(1064, 429), Offset(1085, 372),
        Offset(1095, 287), Offset(1076, 201), Offset(1085, 165), Offset(1108, 135),
      ],
    ),
    const ColoringElement.stroke(
      strokeWidth: 20,
      points: [
        Offset(105, 395), Offset(240, 455), Offset(455, 530), Offset(600, 555),
        Offset(720, 540), Offset(855, 480), Offset(940, 410), Offset(985, 350), Offset(1018, 225),
      ],
    ),
    const ColoringElement.fill(points: [
      Offset(103, 291), Offset(34, 353), Offset(30, 376), Offset(53, 429),
      Offset(83, 467), Offset(126, 384), Offset(123, 329),
    ]),
  ],
);

// Gilos (Cherries) — traced from a 1170x919 source asset.
final ColoringItemDef _gilos = ColoringItemDef.detailed(
  label: 'Gilos',
  canvasSize: const Size(1170, 919),
  elements: [
    const ColoringElement.stroke(strokeWidth: 21, points: [
      Offset(430, 90), Offset(455, 180), Offset(475, 255), Offset(468, 345), Offset(420, 440), Offset(370, 528),
    ]),
    const ColoringElement.stroke(strokeWidth: 21, points: [
      Offset(445, 95), Offset(560, 205), Offset(690, 300), Offset(760, 390), Offset(792, 470), Offset(783, 528),
    ]),
    const ColoringElement.stroke(
      strokeWidth: 21,
      closed: true,
      points: [Offset(397, 66), Offset(386, 110), Offset(433, 175), Offset(428, 66)],
    ),
    const ColoringElement.stroke(
      strokeWidth: 21,
      closed: true,
      points: [
        Offset(435, 196), Offset(432, 216), Offset(422, 244), Offset(395, 289),
        Offset(366, 320), Offset(343, 338), Offset(318, 351), Offset(313, 349),
        Offset(308, 335), Offset(308, 310), Offset(316, 284), Offset(332, 258),
        Offset(353, 236), Offset(372, 221), Offset(404, 204), Offset(435, 196),
      ],
    ),
    ColoringElement.ring(
      points: offsetTowardCentroid(const [
        Offset(241, 506), Offset(279, 500), Offset(308, 509), Offset(363, 541),
        Offset(429, 524), Offset(461, 525), Offset(492, 535), Offset(524, 566),
        Offset(537, 605), Offset(535, 650), Offset(519, 695), Offset(473, 750),
        Offset(413, 779), Offset(339, 782), Offset(277, 761), Offset(226, 714),
        Offset(198, 655), Offset(193, 581), Offset(214, 528), Offset(241, 506),
      ], -21),
      innerPoints: const [
        Offset(241, 506), Offset(279, 500), Offset(308, 509), Offset(363, 541),
        Offset(429, 524), Offset(461, 525), Offset(492, 535), Offset(524, 566),
        Offset(537, 605), Offset(535, 650), Offset(519, 695), Offset(473, 750),
        Offset(413, 779), Offset(339, 782), Offset(277, 761), Offset(226, 714),
        Offset(198, 655), Offset(193, 581), Offset(214, 528), Offset(241, 506),
      ],
    ),
    ColoringElement.ring(
      points: offsetTowardCentroid(const [
        Offset(629, 528), Offset(656, 506), Offset(693, 500), Offset(713, 504),
        Offset(780, 542), Offset(847, 522), Offset(905, 535), Offset(935, 561),
        Offset(951, 597), Offset(952, 641), Offset(935, 693), Offset(900, 739),
        Offset(844, 774), Offset(812, 782), Offset(764, 783), Offset(701, 766),
        Offset(651, 727), Offset(616, 665), Offset(607, 589), Offset(614, 556), Offset(629, 528),
      ], -21),
      innerPoints: const [
        Offset(629, 528), Offset(656, 506), Offset(693, 500), Offset(713, 504),
        Offset(780, 542), Offset(847, 522), Offset(905, 535), Offset(935, 561),
        Offset(951, 597), Offset(952, 641), Offset(935, 693), Offset(900, 739),
        Offset(844, 774), Offset(812, 782), Offset(764, 783), Offset(701, 766),
        Offset(651, 727), Offset(616, 665), Offset(607, 589), Offset(614, 556), Offset(629, 528),
      ],
    ),
    // FaceLeft
    ColoringElement.fill(points: ellipsePoints(cx: 313.8, cy: 626.4, rx: 19.1, ry: 19.1, segments: 20)),
    ColoringElement.fill(points: ellipsePoints(cx: 415.5, cy: 626.5, rx: 20.0, ry: 20.0, segments: 20)),
    const ColoringElement.stroke(strokeWidth: 10, points: [Offset(343, 660), Offset(365, 693), Offset(400, 664)]),
    const ColoringElement.stroke(strokeWidth: 10, points: [Offset(417, 547), Offset(472, 568), Offset(507, 650)]),
    const ColoringElement.stroke(strokeWidth: 9, points: [Offset(492, 681), Offset(468, 716)]),
    const ColoringElement.stroke(strokeWidth: 13, points: [Offset(213, 585), Offset(225, 652)]),
    // FaceRight
    ColoringElement.fill(points: ellipsePoints(cx: 735.7, cy: 636.4, rx: 19.6, ry: 19.6, segments: 20)),
    ColoringElement.fill(points: ellipsePoints(cx: 839.0, cy: 644.8, rx: 20.3, ry: 20.3, segments: 20)),
    const ColoringElement.stroke(strokeWidth: 10, points: [Offset(757, 670), Offset(779, 711), Offset(818, 680)]),
    const ColoringElement.stroke(strokeWidth: 10, points: [Offset(858, 548), Offset(903, 577), Offset(924, 635)]),
    const ColoringElement.stroke(strokeWidth: 9, points: [Offset(924, 670), Offset(903, 699)]),
    const ColoringElement.stroke(strokeWidth: 11, points: [Offset(633, 638), Offset(652, 688)]),
  ],
);

// Normalized 0-1 line-art outlines for Olma/Apelsin, no scoring — just a
// coloring-book guide.
final List<ColoringItemDef> kFruitsColoringItems = [
  const ColoringItemDef(label: 'Olma', outline: [
    [Offset(0.50,0.20),Offset(0.68,0.25),Offset(0.80,0.42),Offset(0.78,0.62),Offset(0.65,0.80),Offset(0.50,0.85),Offset(0.35,0.80),Offset(0.22,0.62),Offset(0.20,0.42),Offset(0.32,0.25),Offset(0.46,0.20),Offset(0.50,0.20)],
    [Offset(0.50,0.20),Offset(0.52,0.10)],
    [Offset(0.52,0.13),Offset(0.65,0.08),Offset(0.60,0.18),Offset(0.52,0.13)],
  ]),
  _banan,
  const ColoringItemDef(label: 'Apelsin', outline: [
    [Offset(0.50,0.20),Offset(0.68,0.27),Offset(0.78,0.45),Offset(0.75,0.65),Offset(0.60,0.80),Offset(0.40,0.80),Offset(0.25,0.65),Offset(0.22,0.45),Offset(0.32,0.27),Offset(0.50,0.20)],
    [Offset(0.50,0.20),Offset(0.50,0.12)],
  ]),
  _gilos,
];