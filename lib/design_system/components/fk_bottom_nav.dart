library fk_bottom_nav;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/app_color_theme.dart';
import '../tokens/app_shadows.dart';

class FkBottomNavItem {
  final IconData icon;
  final IconData filledIcon;
  final String label;

  const FkBottomNavItem({required this.icon, required this.filledIcon, required this.label});
}

/// Phone bottom nav: 4 items + a raised circular primary FAB in the center
/// notch. [onFabPressed] is optional — omit it to render a plain 4-item bar.
class FkBottomNav extends StatelessWidget {
  final List<FkBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final IconData? fabIcon;
  final VoidCallback? onFabPressed;

  const FkBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.fabIcon,
    this.onFabPressed,
  }) : assert(items.length == 4, 'FkBottomNav takes exactly 4 items');

  @override
  Widget build(BuildContext context) {
    final half = items.length ~/ 2;
    final colors = context.colors;
    final labelStyle = Theme.of(context).textTheme.labelLarge;

    Widget buildItem(int index) {
      final item = items[index];
      final active = index == currentIndex;
      final color = active ? colors.primary : colors.textTertiary;
      return Expanded(
        child: Semantics(
          button: true,
          selected: active,
          label: item.label,
          child: InkWell(
            onTap: () {
              if (!active) HapticFeedback.selectionClick();
              onTap(index);
            },
            child: SizedBox(
              height: 64,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(active ? item.filledIcon : item.icon, color: color, size: 24),
                  const SizedBox(height: 2),
                  Text(item.label, style: labelStyle?.copyWith(color: color)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(color: colors.surface, boxShadow: AppShadows.lifted),
      child: SafeArea(
        top: false,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Row(
              children: [
                for (var i = 0; i < half; i++) buildItem(i),
                if (onFabPressed != null) const SizedBox(width: 64),
                for (var i = half; i < items.length; i++) buildItem(i),
              ],
            ),
            if (onFabPressed != null)
              Positioned(
                top: -20,
                child: Semantics(
                  button: true,
                  label: 'Record',
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      onFabPressed!();
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.primaryGlow,
                        border: Border.all(color: colors.surface, width: 3),
                      ),
                      child: Icon(fabIcon ?? Icons.mic_rounded, color: Colors.white, size: 26),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
