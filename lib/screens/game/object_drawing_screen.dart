import 'package:flutter/material.dart';
import '../../data/trace_items/objects_trace_data.dart';
import '../../l10n/app_localizations.dart';
import 'trace_drawing_screen.dart';

class ObjectDrawingScreen extends StatelessWidget {
  const ObjectDrawingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return TraceDrawingScreen(
      title: '${t.drawTitleObjects} · ${t.drawingSuffix}',
      items: kObjectTraceItems,
      levelSlug: 'object_drawing',
      completionTitle: t.completionAllObjectsDone,
    );
  }
}
