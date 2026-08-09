library fk_filter_chip_bar;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/app_color_theme.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';

class FkFilterChip {
  final String label;
  final String value;

  const FkFilterChip({required this.label, required this.value});
}

/// Horizontal-scroll chip bar. Selected chip is primary-filled with white
/// text; unselected chips use the soft primary tint. Selection persists
/// across scroll since state lives with the caller, not scroll position.
class FkFilterChipBar extends StatelessWidget {
  final List<FkFilterChip> chips;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  const FkFilterChipBar({
    super.key,
    required this.chips,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final chip = chips[index];
          final selected = chip.value == selectedValue;
          final colors = context.colors;
          return Semantics(
            button: true,
            selected: selected,
            label: chip.label,
            child: GestureDetector(
              onTap: () {
                if (!selected) HapticFeedback.selectionClick();
                onSelected(chip.value);
              },
              child: AnimatedContainer(
                duration: AppMotion.fast,
                curve: AppMotion.transition,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: selected ? colors.primary : colors.primarySoft,
                  borderRadius: AppRadius.pillAll,
                ),
                child: Text(
                  chip.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: selected ? Colors.white : colors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
