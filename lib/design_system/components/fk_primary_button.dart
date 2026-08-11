library fk_primary_button;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/app_color_theme.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_shadows.dart';
import '../tokens/app_spacing.dart';

/// The redesign's primary call-to-action button: pill radius, primary fill,
/// [AppShadows.primaryGlow]. Distinct from the existing [FkButton]
/// (lib/design_system/atoms/fk_button.dart), which stays as-is for the
/// child-facing game screens it already serves — that widget's rounded-rect
/// shape and per-purpose sizing don't match this component's pill/glow
/// contract from the mockup, so this is a new component rather than an
/// extension of it. See the Phase 2 report for why these aren't merged yet.
class FkPrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool fullWidth;
  final bool loading;
  final Widget? leadingIcon;

  /// Overrides the fill color (default `context.colors.primary`) — used
  /// for a destructive confirm action (e.g. [FkDialog.confirm]'s delete
  /// button), which needs this button's exact visual contract with
  /// `colors.danger` instead of the brand color.
  final Color? color;

  const FkPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.fullWidth = false,
    this.loading = false,
    this.leadingIcon,
    this.color,
  });

  @override
  State<FkPrimaryButton> createState() => _FkPrimaryButtonState();
}

class _FkPrimaryButtonState extends State<FkPrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController = AnimationController(
    vsync: this,
    duration: AppMotion.fast,
    lowerBound: AppMotion.pressScale,
    upperBound: 1.0,
    value: 1.0,
  );

  bool get _enabled => widget.onPressed != null && !widget.loading;

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _setPressed(bool pressed) {
    if (!_enabled) return;
    _scaleController.animateTo(pressed ? AppMotion.pressScale : 1.0,
        curve: AppMotion.press);
    if (pressed) HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = !_enabled;
    final primary = widget.color ?? context.colors.primary;
    final bg = disabled ? primary.withValues(alpha: 0.4) : primary;

    final content = widget.loading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.leadingIcon != null) ...[
                IconTheme(
                  data: const IconThemeData(color: Colors.white, size: 20),
                  child: widget.leadingIcon!,
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                widget.label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
              ),
            ],
          );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: _enabled ? widget.onPressed : null,
        child: AnimatedBuilder(
          animation: _scaleController,
          builder: (context, child) => Transform.scale(
            scale: _scaleController.value,
            child: child,
          ),
          child: Container(
            width: widget.fullWidth ? double.infinity : null,
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: AppRadius.pillAll,
              boxShadow: disabled ? null : AppShadows.primaryGlow,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
