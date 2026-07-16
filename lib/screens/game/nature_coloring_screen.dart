import 'package:flutter/material.dart';
import '../../data/coloring_items/nature_coloring_data.dart';
import 'coloring_screen.dart';

class NatureColoringScreen extends StatelessWidget {
  const NatureColoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoringScreen(
      title: 'Tabiat · bo\'yash',
      items: kNatureColoringItems,
      levelSlug: 'nature_color',
      instructionNoun: 'rasmni',
      completionTitle: 'All nature pictures colored!',
    );
  }
}