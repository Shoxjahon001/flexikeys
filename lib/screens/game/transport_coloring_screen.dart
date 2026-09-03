import 'package:flutter/material.dart';
import '../../data/coloring_items/transport_coloring_data.dart';
import '../../l10n/app_localizations.dart';
import 'coloring_screen.dart';

class TransportColoringScreen extends StatelessWidget {
  const TransportColoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return ColoringScreen(
      title: '${t.colorTitleTransport} · ${t.coloringSuffix}',
      items: kTransportColoringItems,
      levelSlug: 'transport_color',
      completionTitle: t.completionAllTransportColored,
    );
  }
}
