library fk_scaffold;

import 'package:flutter/material.dart';

import '../tokens/app_color_theme.dart';
import 'fk_app_bar.dart';
import 'fk_bottom_nav.dart';

/// Standard screen shell — background, safe areas, optional app bar and
/// bottom nav. Every redesigned screen builds on this rather than a bare
/// [Scaffold].
class FkScaffold extends StatelessWidget {
  final FkAppBar? appBar;
  final Widget body;
  final FkBottomNav? bottomNav;
  final Color? backgroundColor;
  final bool safeAreaTop;
  final bool safeAreaBottom;

  const FkScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNav,
    this.backgroundColor,
    this.safeAreaTop = true,
    this.safeAreaBottom = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? context.colors.background,
      appBar: appBar,
      bottomNavigationBar: bottomNav,
      body: SafeArea(
        top: safeAreaTop,
        bottom: safeAreaBottom && bottomNav == null,
        child: body,
      ),
    );
  }
}
