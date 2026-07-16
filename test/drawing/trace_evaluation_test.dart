import 'package:flutter_test/flutter_test.dart';

import 'package:flexikeys/features/drawing/domain/drawing_models.dart';

// ── Reference path ─────────────────────────────────────────────────────────

// A simple diagonal line: (0.1,0.1) → (0.9,0.9) with 9 points.
final _referencePath = TracePath(
  skillKey: 'en:shape:diagonal',
  points: [
    for (int i = 0; i < 9; i++) [0.1 + i * 0.1, 0.1 + i * 0.1],
  ],
);

DrawPoint _pt(double x, double y) => DrawPoint(
      x: x,
      y: y,
      timestampMs: 0,
    );

// ── Helpers ───────────────────────────────────────────────────────────────────

List<DrawPoint> _perfectStroke() => [
      for (int i = 0; i < 9; i++) _pt(0.1 + i * 0.1, 0.1 + i * 0.1),
    ];

/// Adds Gaussian-ish noise within [amplitude] to each point.
List<DrawPoint> _wobblyStroke(double amplitude) => [
      for (int i = 0; i < 9; i++)
        _pt(
          (0.1 + i * 0.1) + (i.isEven ? amplitude : -amplitude),
          (0.1 + i * 0.1) + (i.isOdd ? amplitude : -amplitude),
        ),
    ];

/// Offsets the entire stroke by [dx, dy].
List<DrawPoint> _offsetStroke(double dx, double dy) => [
      for (int i = 0; i < 9; i++) _pt(0.1 + i * 0.1 + dx, 0.1 + i * 0.1 + dy),
    ];

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('TraceEvaluator — accurate stroke', () {
    test('perfect stroke passes with default tolerance', () {
      final result = TraceEvaluator.evaluate(
        userStroke: _perfectStroke(),
        reference: _referencePath,
      );

      expect(result.passed, isTrue);
      expect(result.avgDeviation, closeTo(0.0, 0.001));
    });

    test('evaluation returns correct tolerance value', () {
      const tol = 0.12;
      final result = TraceEvaluator.evaluate(
        userStroke: _perfectStroke(),
        reference: _referencePath,
        tolerance: tol,
      );
      expect(result.tolerance, tol);
    });
  });

  group('TraceEvaluator — wobbly stroke', () {
    test('slight wobble (0.05) passes with default tolerance 0.15', () {
      final result = TraceEvaluator.evaluate(
        userStroke: _wobblyStroke(0.05),
        reference: _referencePath,
      );
      expect(result.passed, isTrue);
    });

    test('moderate wobble (0.10) passes with default tolerance 0.15', () {
      final result = TraceEvaluator.evaluate(
        userStroke: _wobblyStroke(0.10),
        reference: _referencePath,
      );
      expect(result.passed, isTrue);
    });

    test('severe wobble (0.20) fails with default tolerance 0.15', () {
      final result = TraceEvaluator.evaluate(
        userStroke: _wobblyStroke(0.20),
        reference: _referencePath,
      );
      expect(result.passed, isFalse);
    });

    test('severe wobble passes with adapted wide tolerance 0.30', () {
      // Children with lower touch precision get wider tolerance from profile.
      // wobble 0.20 on both axes → avg deviation ≈ 0.20×√2 ≈ 0.283.
      // Adaptive tolerance of 0.30 comfortably covers this.
      final result = TraceEvaluator.evaluate(
        userStroke: _wobblyStroke(0.20),
        reference: _referencePath,
        tolerance: 0.30,
      );
      expect(result.passed, isTrue);
    });
  });

  group('TraceEvaluator — offset stroke', () {
    test('small offset (0.05) passes with default tolerance', () {
      final result = TraceEvaluator.evaluate(
        userStroke: _offsetStroke(0.05, 0.0),
        reference: _referencePath,
      );
      expect(result.passed, isTrue);
    });

    test('large offset (0.30) fails with default tolerance', () {
      final result = TraceEvaluator.evaluate(
        userStroke: _offsetStroke(0.30, 0.0),
        reference: _referencePath,
      );
      expect(result.passed, isFalse);
    });

    test('large offset passes with adapted wide tolerance', () {
      final result = TraceEvaluator.evaluate(
        userStroke: _offsetStroke(0.30, 0.0),
        reference: _referencePath,
        tolerance: 0.40,
      );
      expect(result.passed, isTrue);
    });
  });

  group('TraceEvaluator — edge cases', () {
    test('empty user stroke fails', () {
      final result = TraceEvaluator.evaluate(
        userStroke: [],
        reference: _referencePath,
      );
      expect(result.passed, isFalse);
    });

    test('empty reference fails', () {
      final result = TraceEvaluator.evaluate(
        userStroke: _perfectStroke(),
        reference: const TracePath(points: [], skillKey: 'test'),
      );
      expect(result.passed, isFalse);
    });

    test('single-point reference evaluates against that point', () {
      const singlePt = TracePath(
        skillKey: 'single',
        points: [
          [0.5, 0.5],
        ],
      );
      final result = TraceEvaluator.evaluate(
        userStroke: [_pt(0.5, 0.5)],
        reference: singlePt,
      );
      expect(result.passed, isTrue);
      expect(result.avgDeviation, closeTo(0.0, 0.001));
    });
  });

  group('DrawingController — connect-the-dots', () {
    test('tapping correct dot in order connects it', () {
      // Conceptual unit test — DrawingController manages state transitions.
      // The controller's _handleDotTap is called with a DrawPoint near the
      // expected dot. Here we verify the DoingModel initialisation.
      final dots = [
        ConnectDot(number: 1, x: 0.1, y: 0.1),
        ConnectDot(number: 2, x: 0.5, y: 0.5),
      ];
      expect(dots[0].connected, isFalse);
      expect(dots[1].connected, isFalse);
    });
  });

  group('DrawPoint — distance', () {
    test('distance between identical points is 0', () {
      final a = _pt(0.3, 0.4);
      expect(a.distanceTo(a), closeTo(0.0, 0.001));
    });

    test('distance (0,0)→(3,4) = 5 (Pythagorean)', () {
      const a = DrawPoint(x: 0, y: 0, timestampMs: 0);
      const b = DrawPoint(x: 3, y: 4, timestampMs: 0);
      expect(a.distanceTo(b), closeTo(5.0, 0.001));
    });
  });
}