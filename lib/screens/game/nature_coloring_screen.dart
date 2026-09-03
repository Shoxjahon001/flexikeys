import 'package:flutter/material.dart';
import '../../data/coloring_items/nature_coloring_data.dart';
import '../../l10n/app_localizations.dart';
import 'coloring_screen.dart';

class NatureColoringScreen extends StatelessWidget {
  const NatureColoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return ColoringScreen(
      title: '${t.colorTitleNature} · ${t.coloringSuffix}',
      items: kNatureColoringItems,
      levelSlug: 'nature_color',
      completionTitle: t.completionAllNatureColored,
    );
  }
}
