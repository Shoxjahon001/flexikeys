import 'package:flutter/material.dart';
import '../../data/coloring_items/fruits_coloring_data.dart';
import 'coloring_screen.dart';

class FruitsColoringScreen extends StatelessWidget {
  const FruitsColoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoringScreen(
      title: 'Mevalar · bo\'yash',
      items: kFruitsColoringItems,
      levelSlug: 'fruits_color',
      instructionNoun: 'mevani',
      completionTitle: 'All fruits colored!',
    );
  }
}