import 'package:flutter/material.dart';
import '../../data/coloring_items/fruits_coloring_data.dart';
import '../../l10n/app_localizations.dart';
import 'coloring_screen.dart';

class FruitsColoringScreen extends StatelessWidget {
  const FruitsColoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return ColoringScreen(
      title: '${t.colorTitleFruits} · ${t.coloringSuffix}',
      items: kFruitsColoringItems,
      levelSlug: 'fruits_color',
      completionTitle: t.completionAllFruitsColored,
    );
  }
}
