library fk_app_bar;

import 'package:flutter/material.dart';

import '../tokens/app_color_theme.dart';

/// Standard top bar: 48×48 back button, centered [h2] title, up to 2
/// trailing icon actions. Back button omitted when [onBack] is null (root
/// screens).
class FkAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final String backSemanticLabel;
  final List<FkAppBarAction> actions;

  const FkAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.backSemanticLabel = 'Back',
    this.actions = const [],
  }) : assert(actions.length <= 2, 'FkAppBar supports at most 2 trailing actions');

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppBar(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leadingWidth: onBack != null ? 56 : null,
      leading: onBack == null
          ? null
          : Semantics(
              label: backSemanticLabel,
              button: true,
              child: SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: colors.textPrimary,
                  onPressed: onBack,
                ),
              ),
            ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.headlineMedium,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        for (final action in actions)
          Semantics(
            label: action.semanticLabel,
            button: true,
            child: SizedBox(
              width: 48,
              height: 48,
              child: IconButton(
                icon: Icon(action.icon),
                color: colors.textPrimary,
                onPressed: action.onPressed,
              ),
            ),
          ),
        if (actions.isNotEmpty) const SizedBox(width: 4),
      ],
    );
  }
}

class FkAppBarAction {
  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;

  const FkAppBarAction({
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
  });
}
