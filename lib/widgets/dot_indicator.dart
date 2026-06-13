import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DotIndicator extends StatelessWidget {
  final int count;
  final int current;

  const DotIndicator({super.key, required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: isActive ? 14 : 10,
          height: isActive ? 14 : 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppTheme.textDark : Colors.transparent,
            border: Border.all(
              color: isActive ? AppTheme.textDark : AppTheme.textMedium,
              width: 1.5,
            ),
          ),
        );
      }),
    );
  }
}
