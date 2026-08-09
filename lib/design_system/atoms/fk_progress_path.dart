library fk_progress_path;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_shadows.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

enum FkLevelNodeState { locked, active, mastered }

class FkLevelNode {
  final int ordinal;
  final String label;
  final FkLevelNodeState state;

  const FkLevelNode({
    required this.ordinal,
    required this.label,
    required this.state,
  });
}

/// Horizontal scrolling world-path showing level nodes connected by a curved
/// path. Locked = sleeping cloud glyph; active = waving; mastered = star.
class FkProgressPath extends StatelessWidget {
  final List<FkLevelNode> levels;
  final ValueChanged<FkLevelNode>? onTap;

  const FkProgressPath({
    super.key,
    required this.levels,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        itemCount: levels.length,
        separatorBuilder: (_, i) => _PathConnector(
          leftState: levels[i].state,
          rightState: levels[i + 1].state,
        ),
        itemBuilder: (context, i) => _LevelNodeWidget(
          node: levels[i],
          onTap: onTap != null ? () => onTap!(levels[i]) : null,
        ),
      ),
    );
  }
}

class _PathConnector extends StatelessWidget {
  final FkLevelNodeState leftState;
  final FkLevelNodeState rightState;

  const _PathConnector({
    required this.leftState,
    required this.rightState,
  });

  @override
  Widget build(BuildContext context) {
    final done = leftState == FkLevelNodeState.mastered;
    return SizedBox(
      width: 40,
      child: CustomPaint(
        painter: _ConnectorPainter(
          color: done ? AppColors.success : AppColors.border,
        ),
      ),
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  final Color color;
  _ConnectorPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height / 2)
      ..quadraticBezierTo(
        size.width / 2,
        size.height / 2 + math.sin(0.5) * 12,
        size.width,
        size.height / 2,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ConnectorPainter old) => old.color != color;
}

class _LevelNodeWidget extends StatefulWidget {
  final FkLevelNode node;
  final VoidCallback? onTap;

  const _LevelNodeWidget({required this.node, this.onTap});

  @override
  State<_LevelNodeWidget> createState() => _LevelNodeWidgetState();
}

class _LevelNodeWidgetState extends State<_LevelNodeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _wave;
  late Animation<double> _waveAnim;

  @override
  void initState() {
    super.initState();
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _waveAnim = Tween<double>(begin: -3, end: 3).animate(
      CurvedAnimation(parent: _wave, curve: AppMotion.transition),
    );
    if (widget.node.state == FkLevelNodeState.active) {
      _wave.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);

    Color bg;
    String glyph;
    switch (widget.node.state) {
      case FkLevelNodeState.locked:
        bg = AppColors.border;
        glyph = '😴';
      case FkLevelNodeState.active:
        bg = AppColors.primary;
        glyph = '👋';
      case FkLevelNodeState.mastered:
        bg = AppColors.success;
        glyph = '⭐';
    }

    return GestureDetector(
      onTap: widget.node.state != FkLevelNodeState.locked ? widget.onTap : null,
      child: AnimatedBuilder(
        animation: _waveAnim,
        builder: (context, child) => Transform.translate(
          offset: Offset(
            0,
            (reduced || widget.node.state != FkLevelNodeState.active)
                ? 0
                : _waveAnim.value,
          ),
          child: child,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                boxShadow: AppShadows.soft,
              ),
              child: Center(
                child: Text(glyph, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.node.label,
              style: AppTypography.caption.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}