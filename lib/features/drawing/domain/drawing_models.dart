library drawing_models;

import 'dart:ui';

/// The active drawing mode.
enum DrawingMode {
  tracing,       // follow a reference path
  coloring,      // flood-fill regions
  connectDots,   // tap numbered dots in order
  maze,          // drag through a maze
  freePaint,     // free finger painting
}

/// A 2D point with optional pressure.
class DrawPoint {
  final double x;
  final double y;
  final double pressure;
  final int timestampMs;

  const DrawPoint({
    required this.x,
    required this.y,
    this.pressure = 1.0,
    required this.timestampMs,
  });

  Offset get offset => Offset(x, y);

  double distanceTo(DrawPoint other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return (dx * dx + dy * dy) < 0 ? 0 : _sqrt(dx * dx + dy * dy);
  }

  static double _sqrt(double v) {
    // Newton's method — avoids dart:math import
    if (v <= 0) return 0;
    double x = v;
    for (int i = 0; i < 20; i++) {
      x = (x + v / x) / 2;
    }
    return x;
  }
}

/// A reference tracing path — normalised 0–1 coordinate points.
/// The first dimension is the point index; second is [x, y].
class TracePath {
  final List<List<double>> points;
  final String skillKey;

  const TracePath({required this.points, required this.skillKey});

  factory TracePath.fromJson(Map<String, dynamic> json) {
    final pts = (json['points'] as List)
        .map((row) => (row as List).map((v) => (v as num).toDouble()).toList())
        .toList();
    return TracePath(
      points: pts,
      skillKey: json['skill_key'] as String? ?? '',
    );
  }

  List<Offset> toOffsets(Size canvasSize) {
    return points
        .map((p) => Offset(p[0] * canvasSize.width, p[1] * canvasSize.height))
        .toList();
  }
}

/// A numbered dot for connect-the-dots.
class ConnectDot {
  final int number;
  final double x; // 0–1 normalised
  final double y;
  bool connected;

  ConnectDot({
    required this.number,
    required this.x,
    required this.y,
    this.connected = false,
  });

  Offset toOffset(Size canvasSize) =>
      Offset(x * canvasSize.width, y * canvasSize.height);
}

/// Maze definition — list of wall segments (x1,y1,x2,y2 normalised).
class MazeWall {
  final double x1, y1, x2, y2;
  const MazeWall(this.x1, this.y1, this.x2, this.y2);
}

/// Evaluation result of a trace stroke against a reference path.
class TraceEvaluation {
  /// Average pixel deviation from the reference path.
  final double avgDeviation;
  /// Whether the trace is within tolerance (generous for children).
  final bool passed;
  /// Tolerance used in this evaluation.
  final double tolerance;

  const TraceEvaluation({
    required this.avgDeviation,
    required this.passed,
    required this.tolerance,
  });
}

/// Evaluates a user trace against a reference path.
class TraceEvaluator {
  /// [tolerance] in normalised units (0–1 coordinate space).
  /// Default 0.15 = generous; adapted tighter for more precise children.
  static TraceEvaluation evaluate({
    required List<DrawPoint> userStroke,
    required TracePath reference,
    double tolerance = 0.15,
  }) {
    if (userStroke.isEmpty || reference.points.isEmpty) {
      return TraceEvaluation(
        avgDeviation: double.infinity,
        passed: false,
        tolerance: tolerance,
      );
    }

    // For each user point, find the nearest reference point distance.
    double totalDev = 0;
    for (final up in userStroke) {
      double minDist = double.infinity;
      for (final rp in reference.points) {
        final dx = up.x - rp[0];
        final dy = up.y - rp[1];
        final d = DrawPoint._sqrt(dx * dx + dy * dy);
        if (d < minDist) minDist = d;
      }
      totalDev += minDist;
    }
    final avg = totalDev / userStroke.length;
    return TraceEvaluation(
      avgDeviation: avg,
      passed: avg <= tolerance,
      tolerance: tolerance,
    );
  }
}