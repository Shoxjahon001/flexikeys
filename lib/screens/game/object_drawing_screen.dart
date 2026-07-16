import 'package:flutter/material.dart';
import '../../data/trace_items/objects_trace_data.dart';
import 'trace_drawing_screen.dart';

class ObjectDrawingScreen extends StatelessWidget {
  const ObjectDrawingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TraceDrawingScreen(
      title: 'Narsalar · chizish',
      items: kObjectTraceItems,
      levelSlug: 'object_drawing',
      instructionNoun: 'rasmini',
      completionTitle: 'All objects done!',
    );
  }
}