library fk_step_pills;

import 'package:flutter/material.dart';
import '../fk_theme.dart';
import '../fk_tokens.dart';

/// Segmented step indicator — one pill per item, the current step lit in
/// the play palette's primary color, the rest muted. Used by the
/// tracing/coloring game screens instead of a continuous progress bar.
class FkStepPills extends StatelessWidget {
  final int total;
  final int current; // 0-indexed

  const FkStepPills({super.key, required this.total, required this.current});

  @override
  Widget build(BuildContext context) {
    final fk = FkPlayTheme.of(context);
    return Row(
      children: List.generate(total, (i) {
        final active = i == current;
        return Expanded(
          child: Container(
            height: 6,
            margin: EdgeInsets.only(right: i == total - 1 ? 0 : FkSpacing.xxs),
            decoration: BoxDecoration(
              color: active ? fk.primary : fk.disabled,
              borderRadius: FkRadii.pillAll,
            ),
          ),
        );
      }),
    );
  }
}