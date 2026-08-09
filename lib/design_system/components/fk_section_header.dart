library fk_section_header;

import 'package:flutter/material.dart';

import '../tokens/app_color_theme.dart';

/// [h3] section title with an optional trailing text action ("See all").
class FkSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const FkSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(child: Text(title, style: textTheme.headlineSmall)),
        if (actionLabel != null && onAction != null)
          Semantics(
            button: true,
            label: actionLabel,
            child: GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: textTheme.bodyMedium
                    ?.copyWith(color: context.colors.primary, fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }
}
