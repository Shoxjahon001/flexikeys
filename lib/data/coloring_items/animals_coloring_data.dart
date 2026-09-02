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

// Quyon (Rabbit) — replaces the old hand-tuned normalized-outline rabbit
// with a faithful trace of a purpose-built 400x400 geometry (head, ears,
// eyes, nose, mouth), native pixel space via ColoringItemDef.detailed
// rather than degrading it into the legacy 0-1 model. Inner-ear creases,
// forehead tuft, and cheek lines omitted, matching the source geometry's
// own trace-step list — too thin/decorative for a child's finger to
// follow. Stroke widths mirror the source's reference painter
// (RabbitHeadPainter): 7 for head/ears, 6 for eyes/mouth, 5 for the nose.
// Left as outline-only (no .fill) so the child paints every part
// themselves, matching every other item here.
final ColoringItemDef _quyon = ColoringItemDef.detailed(
  label: 'Quyon',
  canvasSize: const Size(400, 400),
  elements: [
    // Head — six chained cubic-Bezier segments forming one closed silhouette
    ColoringElement.stroke(
      strokeWidth: 7,
      closed: true,
      smooth: false,
      points: chainCurvePoints([
        cubicBezierPoints(const Offset(128, 272), const Offset(132, 218), const Offset(162, 194), const Offset(200, 194)),
        cubicBezierPoints(const Offset(200, 194), const Offset(238, 194), const Offset(268, 218), const Offset(272, 272)),
        cubicBezierPoints(const Offset(272, 272), const Offset(292, 300), const Offset(320, 306), const Offset(336, 300)),
        cubicBezierPoints(const Offset(336, 300), const Offset(340, 348), const Offset(300, 384), const Offset(200, 384)),
        cubicBezierPoints(const Offset(200, 384), const Offset(100, 384), const Offset(60, 348), const Offset(64, 300)),
        cubicBezierPoints(const Offset(64, 300), const Offset(80, 306), const Offset(108, 300), const Offset(128, 272)),
      ]),
    ),
    // Ears — each a closed loop of three chained cubic-Bezier segments
    ColoringElement.stroke(
      strokeWidth: 7,
      closed: true,
      smooth: false,
      points: chainCurvePoints([
        cubicBezierPoints(const Offset(150, 196), const Offset(130, 160), const Offset(124, 80), const Offset(144, 40)),
        cubicBezierPoints(const Offset(144, 40), const Offset(158, 16), const Offset(180, 34), const Offset(184, 96)),
        cubicBezierPoints(const Offset(184, 96), const Offset(187, 140), const Offset(180, 180), const Offset(168, 202)),
      ]),
    ),
    ColoringElement.stroke(
      strokeWidth: 7,
      closed: true,
      smooth: false,
      points: chainCurvePoints([
        cubicBezierPoints(const Offset(250, 196), const Offset(270, 160), const Offset(276, 80), const Offset(256, 40)),
        cubicBezierPoints(const Offset(256, 40), const Offset(242, 16), const Offset(220, 34), const Offset(216, 96)),
        cubicBezierPoints(const Offset(216, 96), const Offset(213, 140), const Offset(220, 180), const Offset(232, 202)),
      ]),
    ),
    // Eyes
    ColoringElement.stroke(
      strokeWidth: 6,
      closed: true,
      points: ellipsePoints(cx: 162, cy: 262, rx: 20, ry: 26, segments: 24),
    ),
    ColoringElement.stroke(
      strokeWidth: 6,
      closed: true,
      points: ellipsePoints(cx: 238, cy: 262, rx: 20, ry: 26, segments: 24),
    ),
    // Nose — three chained quadratic-Bezier segments forming a closed loop
    ColoringElement.stroke(
      strokeWidth: 5,
      closed: true,
      smooth: false,
      points: chainCurvePoints([
        quadraticBezierPoints(const Offset(182, 300), const Offset(200, 292), const Offset(218, 300)),
        quadraticBezierPoints(const Offset(218, 300), const Offset(214, 320), const Offset(200, 328)),
        quadraticBezierPoints(const Offset(200, 328), const Offset(186, 320), const Offset(182, 300)),
      ]),
    ),
    // Mouth — a straight chin line then two curved smile lobes
    const ColoringElement.stroke(
      strokeWidth: 6,
      points: [Offset(200, 328), Offset(200, 338)],
    ),
    ColoringElement.stroke(
      strokeWidth: 6,
      smooth: false,
      points: quadraticBezierPoints(const Offset(200, 338), const Offset(184, 358), const Offset(170, 344)),
    ),
    ColoringElement.stroke(
      strokeWidth: 6,
      smooth: false,
      points: quadraticBezierPoints(const Offset(200, 338), const Offset(216, 358), const Offset(230, 344)),
    ),
  ],
);

// Baliq (Fish) — replaces the old hand-tuned normalized-outline fish with a
// faithful trace of a purpose-built 400x400 geometry (body, tail, dorsal
// fin, pelvic fin, side fin, eye, mouth), native pixel space via
// ColoringItemDef.detailed rather than degrading it into the legacy 0-1
// model. Scale arcs and the gill line omitted, matching the source
// geometry's own trace-step list — decoration, not meant for tracing.
// Stroke widths mirror the source's reference painter (FishPainter): 7 for
// body/fins/eye, 6 for the mouth. Left as outline-only (no .fill) so the
// child paints every part themselves, matching every other item here.
final ColoringItemDef _baliq = ColoringItemDef.detailed(
  label: 'Baliq',
  canvasSize: const Size(400, 400),
  elements: [
    // Body — four chained cubic-Bezier segments forming one closed silhouette
    ColoringElement.stroke(
      strokeWidth: 7,
      closed: true,
      smooth: false,
      points: chainCurvePoints([
        cubicBezierPoints(const Offset(120, 205), const Offset(152, 158), const Offset(212, 130), const Offset(272, 130)),
        cubicBezierPoints(const Offset(272, 130), const Offset(336, 130), const Offset(372, 165), const Offset(372, 205)),
        cubicBezierPoints(const Offset(372, 205), const Offset(372, 245), const Offset(336, 280), const Offset(272, 280)),
        cubicBezierPoints(const Offset(272, 280), const Offset(212, 280), const Offset(152, 252), const Offset(120, 205)),
      ]),
    ),
    // Tail
    ColoringElement.stroke(
      strokeWidth: 7,
      closed: true,
      smooth: false,
      points: chainCurvePoints([
        cubicBezierPoints(const Offset(120, 205), const Offset(98, 174), const Offset(60, 142), const Offset(32, 146)),
        cubicBezierPoints(const Offset(32, 146), const Offset(44, 174), const Offset(50, 192), const Offset(68, 205)),
        cubicBezierPoints(const Offset(68, 205), const Offset(50, 218), const Offset(44, 236), const Offset(32, 264)),
        cubicBezierPoints(const Offset(32, 264), const Offset(60, 268), const Offset(98, 236), const Offset(120, 205)),
      ]),
    ),
    // Dorsal fin
    ColoringElement.stroke(
      strokeWidth: 7,
      closed: true,
      smooth: false,
      points: chainCurvePoints([
        cubicBezierPoints(const Offset(208, 142), const Offset(216, 106), const Offset(240, 82), const Offset(276, 82)),
        cubicBezierPoints(const Offset(276, 82), const Offset(284, 98), const Offset(286, 118), const Offset(282, 132)),
        cubicBezierPoints(const Offset(282, 132), const Offset(258, 128), const Offset(228, 134), const Offset(208, 142)),
      ]),
    ),
    // Pelvic fin
    ColoringElement.stroke(
      strokeWidth: 7,
      closed: true,
      smooth: false,
      points: chainCurvePoints([
        cubicBezierPoints(const Offset(196, 268), const Offset(202, 298), const Offset(222, 318), const Offset(248, 314)),
        cubicBezierPoints(const Offset(248, 314), const Offset(252, 298), const Offset(248, 284), const Offset(242, 278)),
        cubicBezierPoints(const Offset(242, 278), const Offset(224, 280), const Offset(208, 274), const Offset(196, 268)),
      ]),
    ),
    // Side fin
    ColoringElement.stroke(
      strokeWidth: 7,
      closed: true,
      smooth: false,
      points: chainCurvePoints([
        cubicBezierPoints(const Offset(286, 236), const Offset(308, 220), const Offset(342, 232), const Offset(350, 258)),
        cubicBezierPoints(const Offset(350, 258), const Offset(340, 284), const Offset(304, 284), const Offset(288, 262)),
      ]),
    ),
    // Eye
    ColoringElement.stroke(
      strokeWidth: 7,
      closed: true,
      points: ellipsePoints(cx: 334, cy: 180, rx: 18, ry: 18, segments: 24),
    ),
    // Mouth
    ColoringElement.stroke(
      strokeWidth: 6,
      smooth: false,
      points: quadraticBezierPoints(const Offset(348, 204), const Offset(360, 214), const Offset(346, 224)),
    ),
  ],
);

/// Not const: several shapes below are built with [ellipsePoints], a
/// function call that isn't const-evaluable.
final List<ColoringItemDef> kAnimalsColoringItems = [
  _mushuk,
  _quyon,
  _baliq,
];