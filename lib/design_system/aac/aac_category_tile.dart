library aac_category_tile;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../fk_tokens.dart';
import '../tokens/app_motion.dart';
import 'aac_theme.dart';

/// A Category Home tile — one of the six top-level "My Voice" categories
/// (docs/aac_design_system.md §2-3). Shares [AacCard]'s visual anatomy
/// (full-accent icon area over a tinted label surface, same contrast rule)
/// but is a plain navigation tap, not a spoken utterance: lighter haptic,
/// no dwell-to-activate, no confirmation overlay — tapping just opens that
/// category's Card Grid.
class AacCategoryTile extends StatefulWidget {
  final AacCategory category;
  final String label;

  /// The icon-area content — an emoji glyph today, see [AacCard.glyph] for
  /// why (no per-category illustration assets exist yet).
  final Widget glyph;
  final double size;
  final VoidCallback onTap;

  /// See [AacCard.highContrast].
  final bool highContrast;

  const AacCategoryTile({
    super.key,
    required this.category,
    required this.label,
    required this.glyph,
    required this.onTap,
    this.size = AacSizes.cardMax,
    this.highContrast = false,
  });

  @override
  State<AacCategoryTile> createState() => _AacCategoryTileState();
}

class _AacCategoryTileState extends State<AacCategoryTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _pressAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: FkDurations.fast,
      value: 1.0,
    );
    _pressAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: FkCurves.standard),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    HapticFeedback.lightImpact();
    if (!AppMotion.reduced(context)) _pressController.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _pressController.reverse();
    widget.onTap();
  }

  void _onTapCancel() => _pressController.reverse();

  @override
  Widget build(BuildContext context) {
    final aac = AacTheme.of(context);
    final reduced = AppMotion.reduced(context);
    final accent = aac.colorFor(widget.category);
    final tint = aac.tintFor(widget.category);

    return Semantics(
      label: widget.label,
      button: true,
      excludeSemantics: true,
      onTap: widget.onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedBuilder(
          animation: _pressAnim,
          builder: (context, child) => Transform.scale(
            scale: reduced ? 1.0 : _pressAnim.value,
            child: child,
          ),
          child: Container(
            width: widget.size,
            height: widget.size,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: widget.highContrast ? aac.surface : tint,
              borderRadius: BorderRadius.circular(AacSizes.cardRadius),
              boxShadow: FkElevation.medium(accent),
              border: widget.highContrast
                  ? Border.all(color: accent, width: 3)
                  : null,
            ),
            child: Column(
              children: [
                Expanded(
                  flex: 65,
                  child: Container(
                    width: double.infinity,
                    color: accent,
                    padding: const EdgeInsets.all(FkSpacing.sm),
                    child: Center(child: widget.glyph),
                  ),
                ),
                Expanded(
                  flex: 35,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: FkSpacing.xs),
                    child: Center(
                      child: Text(
                        widget.label,
                        style:
                            FkTextStyles.playHeadline.copyWith(color: aac.ink),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
