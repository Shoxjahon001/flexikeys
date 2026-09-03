// Generates lib/data/trace_items/letters_trace_data_ru.dart from the
// verbatim Cyrillic stroke spec (SVG-path-like M/L/Q/DOT commands, box
// x:0-100 y:0-100(-112)) — run via `flutter test`, see export_audio_manifest
// .dart for why (transitively imports package:flutter, dart run can't
// compile that outside the Flutter toolchain).
//
// Affine transform (uniform scale, no shear): the existing Latin data uses
// a normalized 0-1 canvas with y=0.15 (cap line) / y=0.87 (baseline) — a
// span of 0.72. Using that SAME scale factor for x (never a different one
// per axis, or letters shear) and centering the source box's x midpoint
// (50) on the canvas's x midpoint (0.5) gives:
//   scale = 0.72 / 100 = 0.0072
//   x_out = x_in * scale + 0.14   (0->0.14, 100->0.86, matching the
//                                  existing Latin data's typical x range)
//   y_out = y_in * scale + 0.15   (0->0.15 cap, 100->0.87 baseline,
//                                  descenders to 112 -> 0.9564, well
//                                  inside the 0-1 canvas)
//
//   flutter test tool/generate_ru_letters_trace_data.dart
import 'dart:io';
import 'package:flutter/material.dart';

const double _scale = 0.0072; // 0.72 / 100
const double _dx = 0.14;
const double _dy = 0.15;

Offset _tx(double x, double y) => Offset(x * _scale + _dx, y * _scale + _dy);

// ── Stroke command model — mirrors the spec's SVG-path grammar exactly ────

sealed class _Seg {
  const _Seg();
}

class _M extends _Seg {
  final double x, y;
  const _M(this.x, this.y);
}

class _L extends _Seg {
  final double x, y;
  const _L(this.x, this.y);
}

class _Q extends _Seg {
  final double cx, cy, x, y;
  const _Q(this.cx, this.cy, this.x, this.y);
}

/// A lone filled dot (Ё only) — modeled as its own single-segment "stroke".
class _Dot extends _Seg {
  final double x, y, r;
  const _Dot(this.x, this.y, this.r);
}

typedef _Stroke = List<_Seg>;

class _LetterSpec {
  final String label;
  final List<_Stroke> strokes;
  const _LetterSpec(this.label, this.strokes);
}

// ── The 33 letters, transcribed verbatim from the spec ────────────────────

const _letters = <_LetterSpec>[
  _LetterSpec('А', [
    [_M(24, 100), _L(50, 0), _L(76, 100)],
    [_M(34, 68), _L(66, 68)],
  ]),
  _LetterSpec('Б', [
    [_M(30, 0), _L(30, 100)],
    [_M(30, 0), _L(74, 0)],
    [_M(30, 48), _L(56, 48), _Q(78, 52, 78, 74), _Q(78, 98, 52, 100), _L(30, 100)],
  ]),
  _LetterSpec('В', [
    [_M(30, 0), _L(30, 100)],
    [_M(30, 0), _L(56, 0), _Q(74, 2, 74, 25), _Q(74, 46, 54, 50), _L(30, 50)],
    [_M(30, 50), _L(58, 50), _Q(78, 54, 78, 75), _Q(78, 97, 56, 100), _L(30, 100)],
  ]),
  _LetterSpec('Г', [
    [_M(30, 0), _L(30, 100)],
    [_M(30, 0), _L(74, 0)],
  ]),
  _LetterSpec('Д', [
    [_M(38, 10), _L(68, 10), _L(72, 88)],
    [_M(38, 10), _L(28, 88)],
    [_M(18, 88), _L(82, 88)],
    [_M(26, 88), _L(26, 108)],
    [_M(74, 88), _L(74, 108)],
  ]),
  _LetterSpec('Е', [
    [_M(32, 0), _L(32, 100)],
    [_M(32, 0), _L(74, 0)],
    [_M(32, 50), _L(66, 50)],
    [_M(32, 100), _L(74, 100)],
  ]),
  _LetterSpec('Ё', [
    [_M(32, 16), _L(32, 100)],
    [_M(32, 16), _L(74, 16)],
    [_M(32, 58), _L(66, 58)],
    [_M(32, 100), _L(74, 100)],
    [_Dot(40, 5, 4)],
    [_Dot(64, 5, 4)],
  ]),
  _LetterSpec('Ж', [
    [_M(50, 0), _L(50, 100)],
    [_M(20, 0), _L(50, 50), _L(20, 100)],
    [_M(80, 0), _L(50, 50), _L(80, 100)],
  ]),
  _LetterSpec('З', [
    [_M(26, 14), _Q(32, 0, 50, 0), _Q(74, 0, 74, 25), _Q(74, 48, 50, 50), _Q(78, 52, 78, 74), _Q(78, 100, 48, 100), _Q(26, 100, 22, 84)],
  ]),
  _LetterSpec('И', [
    [_M(28, 0), _L(28, 100), _L(72, 0), _L(72, 100)],
  ]),
  _LetterSpec('Й', [
    [_M(28, 16), _L(28, 100), _L(72, 16), _L(72, 100)],
    [_M(38, 6), _Q(50, 18, 62, 6)],
  ]),
  _LetterSpec('К', [
    [_M(30, 0), _L(30, 100)],
    [_M(72, 0), _L(36, 52), _L(74, 100)],
  ]),
  _LetterSpec('Л', [
    [_M(24, 100), _L(38, 0), _L(72, 0), _L(72, 100)],
  ]),
  _LetterSpec('М', [
    [_M(24, 100), _L(24, 0), _L(50, 56), _L(76, 0), _L(76, 100)],
  ]),
  _LetterSpec('Н', [
    [_M(28, 0), _L(28, 100)],
    [_M(72, 0), _L(72, 100)],
    [_M(28, 50), _L(72, 50)],
  ]),
  _LetterSpec('О', [
    [_M(50, 0), _Q(78, 0, 78, 50), _Q(78, 100, 50, 100), _Q(22, 100, 22, 50), _Q(22, 0, 50, 0)],
  ]),
  _LetterSpec('П', [
    [_M(28, 100), _L(28, 0), _L(72, 0), _L(72, 100)],
  ]),
  _LetterSpec('Р', [
    [_M(30, 0), _L(30, 100)],
    [_M(30, 0), _L(58, 0), _Q(78, 2, 78, 26), _Q(78, 50, 56, 52), _L(30, 52)],
  ]),
  _LetterSpec('С', [
    [_M(74, 16), _Q(66, 0, 48, 0), _Q(22, 0, 22, 50), _Q(22, 100, 48, 100), _Q(66, 100, 74, 84)],
  ]),
  _LetterSpec('Т', [
    [_M(22, 0), _L(78, 0)],
    [_M(50, 0), _L(50, 100)],
  ]),
  _LetterSpec('У', [
    [_M(26, 0), _L(50, 60)],
    [_M(76, 0), _L(50, 60), _L(34, 110)],
  ]),
  _LetterSpec('Ф', [
    [_M(50, 0), _L(50, 100)],
    [_M(50, 14), _Q(20, 14, 20, 50), _Q(20, 86, 50, 86), _Q(80, 86, 80, 50), _Q(80, 14, 50, 14)],
  ]),
  _LetterSpec('Х', [
    [_M(24, 0), _L(76, 100)],
    [_M(76, 0), _L(24, 100)],
  ]),
  _LetterSpec('Ц', [
    [_M(28, 0), _L(28, 100), _L(76, 100), _L(76, 112)],
    [_M(76, 0), _L(76, 100)],
  ]),
  _LetterSpec('Ч', [
    [_M(28, 0), _L(28, 50), _L(72, 50)],
    [_M(72, 0), _L(72, 100)],
  ]),
  _LetterSpec('Ш', [
    [_M(22, 0), _L(22, 100), _L(78, 100), _L(78, 0)],
    [_M(50, 0), _L(50, 100)],
  ]),
  _LetterSpec('Щ', [
    [_M(20, 0), _L(20, 100), _L(80, 100), _L(80, 112)],
    [_M(48, 0), _L(48, 100)],
    [_M(76, 0), _L(76, 100)],
  ]),
  _LetterSpec('Ъ', [
    [_M(22, 0), _L(46, 0), _L(46, 100)],
    [_M(46, 48), _L(64, 48), _Q(80, 50, 80, 74), _Q(80, 98, 62, 100), _L(46, 100)],
  ]),
  _LetterSpec('Ы', [
    [_M(24, 0), _L(24, 100)],
    [_M(24, 48), _L(42, 48), _Q(58, 50, 58, 74), _Q(58, 98, 40, 100), _L(24, 100)],
    [_M(76, 0), _L(76, 100)],
  ]),
  _LetterSpec('Ь', [
    [_M(32, 0), _L(32, 100)],
    [_M(32, 48), _L(56, 48), _Q(74, 50, 74, 74), _Q(74, 98, 54, 100), _L(32, 100)],
  ]),
  _LetterSpec('Э', [
    [_M(26, 16), _Q(32, 0, 52, 0), _Q(76, 0, 76, 50), _Q(76, 100, 52, 100), _Q(32, 100, 26, 84)],
    [_M(44, 50), _L(72, 50)],
  ]),
  _LetterSpec('Ю', [
    [_M(22, 0), _L(22, 100)],
    [_M(22, 50), _L(40, 50)],
    [_M(62, 0), _Q(84, 0, 84, 50), _Q(84, 100, 62, 100), _Q(40, 100, 40, 50), _Q(40, 0, 62, 0)],
  ]),
  _LetterSpec('Я', [
    [_M(70, 0), _L(70, 100)],
    [_M(70, 0), _L(44, 0), _Q(24, 2, 24, 26), _Q(24, 50, 46, 52), _L(70, 52)],
    [_M(46, 52), _L(24, 100)],
  ]),
];

// ── SVG-path -> (dots, ghost) ──────────────────────────────────────────────

const int _qSegments = 16;

List<Offset> _sampleQuadratic(Offset p0, Offset cx, Offset p2) {
  final pts = <Offset>[];
  for (int i = 1; i <= _qSegments; i++) {
    final t = i / _qSegments;
    final mt = 1 - t;
    final x = mt * mt * p0.dx + 2 * mt * t * cx.dx + t * t * p2.dx;
    final y = mt * mt * p0.dy + 2 * mt * t * cx.dy + t * t * p2.dy;
    pts.add(Offset(x, y));
  }
  return pts;
}

class _Processed {
  final List<Offset> dots;
  final List<List<Offset>> ghost;
  const _Processed(this.dots, this.ghost);
}

_Processed _process(_LetterSpec spec) {
  final dots = <Offset>[];
  final ghost = <List<Offset>>[];

  for (final stroke in spec.strokes) {
    if (stroke.isEmpty) continue;
    if (stroke.length == 1 && stroke.first is _Dot) {
      final d = stroke.first as _Dot;
      final p = _tx(d.x, d.y);
      dots.add(p);
      ghost.add([p]); // single-point "stroke" -> rendered as a filled dot
      continue;
    }

    final first = stroke.first;
    if (first is! _M) {
      throw StateError('${spec.label}: stroke must start with M, got $first');
    }
    var cur = _tx(first.x, first.y);
    final ghostPts = <Offset>[cur];
    dots.add(cur); // M is always a numbered waypoint

    for (final seg in stroke.skip(1)) {
      switch (seg) {
        case _L(:final x, :final y):
          final p = _tx(x, y);
          ghostPts.add(p);
          dots.add(p);
          cur = p;
        case _Q(:final cx, :final cy, :final x, :final y):
          final ctrl = _tx(cx, cy);
          final end = _tx(x, y);
          ghostPts.addAll(_sampleQuadratic(cur, ctrl, end));
          dots.add(end); // control point never a dot, only the end point
          cur = end;
        case _M():
          throw StateError('${spec.label}: unexpected mid-stroke M');
        case _Dot():
          throw StateError('${spec.label}: unexpected mid-stroke DOT');
      }
    }
    ghost.add(ghostPts);
  }

  return _Processed(dots, ghost);
}

String _fmt(double v) {
  // Trim to at most 4 decimals, strip trailing zeros — keeps the generated
  // source readable while staying exact enough (source coords are at most
  // 2 decimal places pre-transform).
  var s = v.toStringAsFixed(4);
  s = s.replaceFirst(RegExp(r'0+$'), '');
  s = s.replaceFirst(RegExp(r'\.$'), '');
  return s;
}

String _offsetLit(Offset o) => 'Offset(${_fmt(o.dx)},${_fmt(o.dy)})';

void main() {
  final buf = StringBuffer();
  buf.writeln("import 'package:flutter/material.dart';");
  buf.writeln("import 'trace_item_def.dart';");
  buf.writeln();
  buf.writeln('// GENERATED by tool/generate_ru_letters_trace_data.dart from the');
  buf.writeln('// verbatim Cyrillic stroke spec — do not hand-edit coordinates here;');
  buf.writeln('// change the spec in the generator and re-run it instead.');
  buf.writeln('//');
  buf.writeln('// Body sits between y=0.15 (cap line) and y=0.87 (baseline), same');
  buf.writeln('// convention as kLetterTraceItems — Д/У/Ц/Щ descend to y~0.9564.');
  buf.writeln('// Ё/Й bodies are shifted down (y starts at 0.265) to leave room for');
  buf.writeln('// the diaeresis dots / breve above, per the source spec.');
  buf.writeln('const List<TraceItemDef> kLetterTraceItemsRu = [');

  for (final spec in _letters) {
    final p = _process(spec);
    buf.writeln('  // ${spec.label} ${'─' * 70}');
    buf.writeln("  TraceItemDef(label: '${spec.label}',");
    buf.write('    dots: [');
    buf.write(p.dots.map(_offsetLit).join(', '));
    buf.writeln('],');
    buf.write('    ghost: [');
    buf.write(p.ghost.map((path) => '[${path.map(_offsetLit).join(',')}]').join(', '));
    buf.writeln(']),');
  }

  buf.writeln('];');
  buf.writeln();
  buf.writeln('/// 33 letters split into groups of 3-4, computed from');
  buf.writeln('/// [kLetterTraceItemsRu] the same way as the English list — see');
  buf.writeln('/// computeGroupSizes/buildLetterGroups in trace_item_def.dart.');
  buf.writeln('final List<LetterGroup> kLetterGroupsRu =');
  buf.writeln("    buildLetterGroups(kLetterTraceItemsRu, 'letters_group_ru');");

  final file = File('lib/data/trace_items/letters_trace_data_ru.dart');
  file.writeAsStringSync(buf.toString());

  // ignore: avoid_print
  print('Wrote ${file.path}: ${_letters.length} letters');
  for (final spec in _letters) {
    final p = _process(spec);
    // ignore: avoid_print
    print('  ${spec.label}: ${spec.strokes.length} strokes, '
        '${p.dots.length} dots, ${p.ghost.length} ghost paths');
  }

  _writeContactSheetData();
}

// ── Contact-sheet data: native-space (untransformed) SVG path strings + ────
// dot positions, for a faithful, independent visual review of the verbatim
// source spec — not the Flutter-space transcription above.

String _svgPathFor(_Stroke stroke) {
  final b = StringBuffer();
  for (final seg in stroke) {
    switch (seg) {
      case _M(:final x, :final y):
        b.write('M${_fmt(x)},${_fmt(y)} ');
      case _L(:final x, :final y):
        b.write('L${_fmt(x)},${_fmt(y)} ');
      case _Q(:final cx, :final cy, :final x, :final y):
        b.write('Q${_fmt(cx)},${_fmt(cy)} ${_fmt(x)},${_fmt(y)} ');
      case _Dot():
        break; // dots are rendered separately, not part of a path
    }
  }
  return b.toString().trim();
}

void _writeContactSheetData() {
  final buf = StringBuffer();
  buf.writeln('const LETTERS = [');
  for (final spec in _letters) {
    // Same walk as _process() (numbered continuously across strokes, in
    // stroke order — M/L/Q endpoints AND each DOT command all get a
    // number; only Q control points don't), computed independently here
    // (no shared code with _process) so a bug in one can't hide in the
    // other. `filled: true` marks a DOT command specifically (Ё's two
    // diaeresis dots) — rendered as a solid dot, not just a numbered
    // circle, in addition to being numbered like every other point.
    final dots = <Map<String, Object>>[];
    final paths = <String>[];
    for (final stroke in spec.strokes) {
      if (stroke.length == 1 && stroke.first is _Dot) {
        final d = stroke.first as _Dot;
        dots.add({'x': d.x, 'y': d.y, 'filled': true});
        continue;
      }
      paths.add(_svgPathFor(stroke));
      for (final seg in stroke) {
        switch (seg) {
          case _M(:final x, :final y):
            dots.add({'x': x, 'y': y, 'filled': false});
          case _L(:final x, :final y):
            dots.add({'x': x, 'y': y, 'filled': false});
          case _Q(:final x, :final y):
            dots.add({'x': x, 'y': y, 'filled': false});
          case _Dot():
            break;
        }
      }
    }
    final dotsLit = dots
        .map((d) =>
            '{x:${_fmt(d['x'] as double)},y:${_fmt(d['y'] as double)},filled:${d['filled']}}')
        .join(',');
    buf.writeln('  {');
    buf.writeln("    label: '${spec.label}',");
    buf.writeln('    strokeCount: ${spec.strokes.length},');
    buf.writeln('    dotCount: ${dots.length},');
    buf.writeln('    paths: [${paths.map((p) => "'$p'").join(', ')}],');
    buf.writeln('    dots: [$dotsLit],');
    buf.writeln('  },');
  }
  buf.writeln('];');

  final file = File('tool/_contact_sheet_data.js');
  file.writeAsStringSync(buf.toString());
  // ignore: avoid_print
  print('Wrote ${file.path}');
}
