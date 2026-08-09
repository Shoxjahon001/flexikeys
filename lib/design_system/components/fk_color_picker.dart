library fk_color_picker;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';

/// Row of category-palette swatches for the Create Card color step —
/// selected swatch shows a check mark.
class FkColorPicker extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const FkColorPicker({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    // categoryPalette is fixed content data (the set of pickable card
    // colors), not a semantic UI role — it doesn't have or need a dark
    // variant, unlike AppColorTheme's primary/surface/etc.
    const palette = AppColors.categoryPalette; // ignore: static-tokens
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        for (var i = 0; i < palette.length; i++)
          _Swatch(
            color: palette[i].$1,
            checkColor: palette[i].$2,
            selected: i == selectedIndex,
            onTap: () {
              if (i != selectedIndex) HapticFeedback.selectionClick();
              onSelected(i);
            },
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  final Color color;
  final Color checkColor;
  final bool selected;
  final VoidCallback onTap;

  const _Swatch({
    required this.color,
    required this.checkColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Color swatch',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: selected ? Border.all(color: checkColor, width: 2) : null,
          ),
          child: selected ? Icon(Icons.check_rounded, color: checkColor, size: 20) : null,
        ),
      ),
    );
  }
}
