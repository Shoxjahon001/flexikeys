library break_overlay;

import 'package:flutter/material.dart';
import '../../../../design_system/fk_tokens.dart';
import '../../../../design_system/atoms/fk_button.dart';

/// A calm full-screen overlay suggesting a hand rest.
/// Child can dismiss and continue, or the session naturally ends.
///
/// No negative framing — phrased as an invitation, not an interruption.
class BreakOverlay extends StatelessWidget {
  final VoidCallback onContinue;
  final VoidCallback onStop;

  const BreakOverlay({
    super.key,
    required this.onContinue,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FkColors.lavender.withValues(alpha: 0.92),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(FkSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Breathing animation — gentle pulsing circle
              const _BreathingCircle(),
              const SizedBox(height: FkSpacing.lg),
              const Text(
                "Let's rest our hands",
                style: FkTextStyles.childHeadline,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: FkSpacing.sm),
              Text(
                'Ready when you are.',
                style: FkTextStyles.childBody.copyWith(
                  color: FkColors.inkSoft,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: FkSpacing.xl),
              FkButton(
                label: 'Keep going',
                onPressed: onContinue,
                size: FkButtonSize.child,
              ),
              const SizedBox(height: FkSpacing.sm),
              FkButton(
                label: 'Done for today',
                onPressed: onStop,
                variant: FkButtonVariant.secondary,
                size: FkButtonSize.child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BreathingCircle extends StatefulWidget {
  const _BreathingCircle();

  @override
  State<_BreathingCircle> createState() => _BreathingCircleState();
}

class _BreathingCircleState extends State<_BreathingCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.of(context).disableAnimations;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.scale(
        scale: reducedMotion ? 1.0 : _scale.value,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: FkColors.sky.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.air_rounded,
            size: 48,
            color: FkColors.ink,
          ),
        ),
      ),
    );
  }
}