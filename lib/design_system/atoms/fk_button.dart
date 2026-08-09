library fk_button;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../fk_tokens.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_shadows.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

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
      duration: AppMotion.fast,
      value: 1.0,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scale, curve: AppMotion.press),
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
    final isChild = widget.size == FkButtonSize.child;
    final disabled = widget.onPressed == null || widget.loading;

    final minH = isChild ? FkTouchTargets.child : FkTouchTargets.adult;
    final hPad = isChild ? AppSpacing.xxl : AppSpacing.lg;
    final style = isChild ? AppTypography.h3 : AppTypography.bodyLarge;

    Color bg;
    Color fg;
    Border? border;

    switch (widget.variant) {
      case FkButtonVariant.primary:
        // AppColors.primary is a vivid, saturated purple (unlike the pale
        // lavender it replaces), so the enabled label needs to be white
        // for contrast, not the shared dark-ink default.
        bg = disabled ? AppColors.border : AppColors.primary;
        fg = disabled ? AppColors.textTertiary : Colors.white;
      case FkButtonVariant.secondary:
        bg = disabled ? AppColors.border : AppColors.surface;
        fg = disabled ? AppColors.textTertiary : AppColors.textPrimary;
        border = Border.all(
            color: disabled ? AppColors.border : AppColors.primary, width: 2);
      case FkButtonVariant.ghost:
        bg = Colors.transparent;
        fg = disabled ? AppColors.textTertiary : AppColors.textPrimary;
    }

    final reduced = AppMotion.reduced(context);

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
          duration: AppMotion.fast,
          constraints: BoxConstraints(minHeight: minH),
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.pillAll,
            border: border,
            boxShadow: disabled || widget.variant == FkButtonVariant.ghost
                ? null
                : AppShadows.soft,
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