library fk_category_card;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/app_motion.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';

/// Home-grid category tile: pastel background from the category palette
/// (see app_colors.dart's `categoryPalette`, passed in by the caller as
/// [paletteEntry]), label top-left in the paired foreground, illustration
/// bottom-right.
class FkCategoryCard extends StatefulWidget {
  final String label;
  final (Color background, Color foreground) paletteEntry;
  final Widget illustration;
  final VoidCallback? onTap;

  const FkCategoryCard({
    super.key,
    required this.label,
    required this.paletteEntry,
    required this.illustration,
    this.onTap,
  });

  @override
  State<FkCategoryCard> createState() => _FkCategoryCardState();
}

class _FkCategoryCardState extends State<FkCategoryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController = AnimationController(
    vsync: this,
    duration: AppMotion.fast,
    lowerBound: AppMotion.pressScale,
    upperBound: 1.0,
    value: 1.0,
  );

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _setPressed(bool pressed) {
    if (widget.onTap == null) return;
    _scaleController.animateTo(pressed ? AppMotion.pressScale : 1.0, curve: AppMotion.press);
    if (pressed) HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = widget.paletteEntry;

    return Semantics(
      button: widget.onTap != null,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleController,
          builder: (context, child) => Transform.scale(scale: _scaleController.value, child: child),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 132),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(color: bg, borderRadius: AppRadius.lgAll),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      widget.label,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: fg),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: widget.illustration,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
