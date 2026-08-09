library fk_secondary_button;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/app_color_theme.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';

/// White-fill, bordered counterpart to [FkPrimaryButton] — same pill/height
/// contract, lower visual weight for secondary actions (e.g. "Repeat" next
/// to a primary "Next").
class FkSecondaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool fullWidth;
  final Widget? leadingIcon;

  const FkSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.fullWidth = false,
    this.leadingIcon,
  });

  @override
  State<FkSecondaryButton> createState() => _FkSecondaryButtonState();
}

class _FkSecondaryButtonState extends State<FkSecondaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController = AnimationController(
    vsync: this,
    duration: AppMotion.fast,
    lowerBound: AppMotion.pressScale,
    upperBound: 1.0,
    value: 1.0,
  );

  bool get _enabled => widget.onPressed != null;

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
    final colors = context.colors;
    final textColor = _enabled ? colors.textPrimary : colors.textTertiary;

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onPressed,
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
              color: colors.surface,
              borderRadius: AppRadius.pillAll,
              border: Border.all(
                color: _enabled ? colors.border : colors.border.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.leadingIcon != null) ...[
                  IconTheme(
                    data: IconThemeData(color: textColor, size: 20),
                    child: widget.leadingIcon!,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(widget.label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: textColor)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
