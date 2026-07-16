library fk_button;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../fk_tokens.dart';
import '../fk_theme.dart';

enum FkButtonVariant { primary, secondary, ghost }
enum FkButtonSize { child, adult }

/// Tap target ≥ 64dp (child) / ≥ 44dp (adult).
/// Press animation: gentle scale to 0.97 + soft haptic.
/// No red, no failure-framing copy (enforced by callers).
class FkButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final FkButtonVariant variant;
  final FkButtonSize size;
  final Widget? icon;
  final bool loading;

  const FkButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = FkButtonVariant.primary,
    this.size = FkButtonSize.child,
    this.icon,
    this.loading = false,
  });

  @override
  State<FkButton> createState() => _FkButtonState();
}

class _FkButtonState extends State<FkButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scale;
  late Animation<double> _scaleAnim;
  @override
  void initState() {
    super.initState();
    _scale = AnimationController(
      vsync: this,
      duration: FkDurations.fast,
      value: 1.0,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scale, curve: FkCurves.standard),
    );
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  Future<void> _onTapDown(TapDownDetails _) async {
    if (widget.onPressed == null || widget.loading) return;
    HapticFeedback.lightImpact();
    await _scale.forward();
  }

  Future<void> _onTapUp(TapUpDetails _) async {
    await _scale.reverse();
    if (!widget.loading) widget.onPressed?.call();
  }

  Future<void> _onTapCancel() async {
    await _scale.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final fk = FkTheme.of(context);
    final isChild = widget.size == FkButtonSize.child;
    final disabled = widget.onPressed == null || widget.loading;

    final minH = isChild ? FkTouchTargets.child : FkTouchTargets.adult;
    final hPad = isChild ? FkSpacing.md : FkSpacing.sm;
    final style = isChild ? FkTextStyles.childLabel : FkTextStyles.adultLabel;

    Color bg;
    Color fg;
    Border? border;

    switch (widget.variant) {
      case FkButtonVariant.primary:
        bg = disabled ? fk.disabled : fk.primary;
        fg = disabled ? fk.inkSoft : fk.ink;
      case FkButtonVariant.secondary:
        bg = disabled ? fk.disabled : fk.surface;
        fg = disabled ? fk.inkSoft : fk.ink;
        border = Border.all(color: disabled ? fk.disabled : fk.primary, width: 2);
      case FkButtonVariant.ghost:
        bg = FkColors.cloud.withValues(alpha: 0);
        fg = disabled ? fk.inkSoft : fk.ink;
    }

    final reduced = FkTheme.reducedMotion(context);

    return GestureDetector(
      onTapDown: disabled ? null : _onTapDown,
      onTapUp: disabled ? null : _onTapUp,
      onTapCancel: disabled ? null : _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => Transform.scale(
          scale: (reduced || disabled) ? 1.0 : _scaleAnim.value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: FkDurations.fast,
          constraints: BoxConstraints(minHeight: minH),
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: FkSpacing.xs),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: FkRadii.pillAll,
            border: border,
            boxShadow: disabled || widget.variant == FkButtonVariant.ghost
                ? null
                : FkElevation.low(fk.ink),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.loading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(fg),
                  ),
                )
              else ...[
                if (widget.icon != null) ...[
                  widget.icon!,
                  const SizedBox(width: 8),
                ],
                Text(widget.label, style: style.copyWith(color: fg)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}