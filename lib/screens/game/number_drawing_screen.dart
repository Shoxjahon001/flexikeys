import 'package:flutter/material.dart';
import '../../data/trace_items/numbers_trace_data.dart';
import '../../l10n/app_localizations.dart';
import 'trace_drawing_screen.dart';

class NumberDrawingScreen extends StatelessWidget {
  const NumberDrawingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return TraceDrawingScreen(
      title: 'Raqamlar · ${t.drawingSuffix}',
      items: kNumberTraceItems,
      levelSlug: 'number_drawing',
      completionTitle: t.completionAllNumbersDone,
    );
  }
}
