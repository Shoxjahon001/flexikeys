import 'package:flutter/material.dart';
import '../../data/trace_items/letters_trace_data.dart';
import 'trace_drawing_screen.dart';

class LetterDrawingScreen extends StatelessWidget {
  const LetterDrawingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TraceDrawingScreen(
      title: "Harflar · chizish",
      items: kLetterTraceItems,
      levelSlug: 'letter_drawing',
      instructionNoun: 'harfini',
      completionTitle: 'All letters done!',
    );
  }
}