import 'package:flutter/material.dart';
import '../../data/trace_items/numbers_trace_data.dart';
import 'trace_drawing_screen.dart';

class NumberDrawingScreen extends StatelessWidget {
  const NumberDrawingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TraceDrawingScreen(
      title: 'Raqamlar · chizish',
      items: kNumberTraceItems,
      levelSlug: 'number_drawing',
      instructionNoun: 'raqamini',
      completionTitle: 'All numbers done!',
    );
  }
}