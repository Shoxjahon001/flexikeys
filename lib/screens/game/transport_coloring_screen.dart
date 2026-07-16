import 'package:flutter/material.dart';
import '../../data/coloring_items/transport_coloring_data.dart';
import 'coloring_screen.dart';

class TransportColoringScreen extends StatelessWidget {
  const TransportColoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoringScreen(
      title: 'Transport · bo\'yash',
      items: kTransportColoringItems,
      levelSlug: 'transport_color',
      instructionNoun: 'transportni',
      completionTitle: 'All transport colored!',
    );
  }
}