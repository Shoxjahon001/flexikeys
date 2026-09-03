import 'package:flutter/material.dart';
import '../../data/trace_items/letters_trace_data.dart';
import '../../l10n/app_localizations.dart';
import 'trace_drawing_screen.dart';

class LetterDrawingScreen extends StatelessWidget {
  const LetterDrawingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return TraceDrawingScreen(
      title: '${t.drawTitleLetters} · ${t.drawingSuffix}',
      items: kLetterTraceItems,
      levelSlug: 'letter_drawing',
      completionTitle: t.completionAllLettersDone,
    );
  }
}
