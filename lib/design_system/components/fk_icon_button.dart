library fk_icon_button;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/app_color_theme.dart';
import '../tokens/app_motion.dart';

enum FkIconButtonSize { small, medium, large }
enum FkIconButtonVariant { soft, filled }

/// Circular icon-only button. Sizes: 40 (small) / 48 (medium) / 56 (large).
/// [FkIconButtonVariant.soft] = soft primary-tinted bg + primary icon;
/// [FkIconButtonVariant.filled] = primary bg + white icon.
class FkIconButton extends StatefulWidget {
  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final FkIconButtonSize size;
  final FkIconButtonVariant variant;

  const FkIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
    this.size = FkIconButtonSize.medium,
    this.variant = FkIconButtonVariant.soft,
  });

  double get _diameter => switch (size) {
        FkIconButtonSize.small => 40,
        FkIconButtonSize.medium => 48,
        FkIconButtonSize.large => 56,
      };

  @override
  State<FkIconButton> createState() => _FkIconButtonState();
}

class _FkIconButtonState extends State<FkIconButton>
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
    _scaleController.animateTo(pressed ? AppMotion.pressScale : 1.0, curve: AppMotion.press);
    if (pressed) HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final filled = widget.variant == FkIconButtonVariant.filled;
    final colors = context.colors;
    final bg = !_enabled
        ? colors.surfaceMuted
        : filled
            ? colors.primary
            : colors.primarySoft;
    final fg = !_enabled
        ? colors.textTertiary
        : filled
            ? Colors.white
            : colors.primary;
    final d = widget._diameter;

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onPressed,
        child: AnimatedBuilder(
          animation: _scaleController,
          builder: (context, child) => Transform.scale(scale: _scaleController.value, child: child),
          child: Container(
            width: d,
            height: d,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(widget.icon, color: fg, size: d * 0.45),
          ),
        ),
      ),
    );
  }
}
