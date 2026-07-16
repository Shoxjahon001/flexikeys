import 'package:flutter/material.dart';
import '../../data/coloring_items/animals_coloring_data.dart';
import 'coloring_screen.dart';

class AnimalsColoringScreen extends StatelessWidget {
  const AnimalsColoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoringScreen(
      title: 'Hayvonlar · bo\'yash',
      items: kAnimalsColoringItems,
      levelSlug: 'animals_color',
      instructionNoun: 'hayvonni',
      completionTitle: 'All animals colored!',
    );
  }
}