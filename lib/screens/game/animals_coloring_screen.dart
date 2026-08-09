import 'package:flutter/material.dart';
import '../../data/coloring_items/animals_coloring_data.dart';
import '../../l10n/app_localizations.dart';
import 'coloring_screen.dart';

class AnimalsColoringScreen extends StatelessWidget {
  const AnimalsColoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return ColoringScreen(
      title: 'Hayvonlar · ${t.coloringSuffix}',
      items: kAnimalsColoringItems,
      levelSlug: 'animals_color',
      completionTitle: t.completionAllAnimalsColored,
    );
  }
}
