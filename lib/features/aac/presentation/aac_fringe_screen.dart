library aac_fringe_screen;

import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../data/aac_event_repository.dart';
import '../data/aac_settings_store.dart';
import '../domain/aac_card_def.dart';
import 'aac_confirmation_screen.dart';
import 'aac_glyphs.dart';

/// The second step of a branch card's two-step (core+fringe) flow — docs/
/// aac_design_system.md §2.4. E.g. tapping "Food" on the Card Grid opens
/// this screen showing Apple/Banana/Bread/Rice; picking one speaks the
/// completed sentence ("I want banana.") via [AacConfirmationScreen].
/// Reuses [AacCard] itself for the options — a fringe option is
/// structurally the same interaction unit as a vocabulary card, just
/// scoped to one branch.
class AacFringeScreen extends StatefulWidget {
  final AacCardDef card;
  final AacLanguage language;

  const AacFringeScreen({super.key, required this.card, required this.language});

  @override
  State<AacFringeScreen> createState() => _AacFringeScreenState();
}

class _AacFringeScreenState extends State<AacFringeScreen> {
  AacSettings _settings = const AacSettings();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await AacSettingsStore.instance.get();
    if (mounted) setState(() => _settings = settings);
  }

  String _labelFor(Map<AacLanguage, String> map, String fallbackId) =>
      map[widget.language] ?? map[AacLanguage.en] ?? fallbackId;

  void _onOptionActivate(AacFringeOption option) {
    final sentence = widget.card.sentenceFor(widget.language, chosenFringe: option);
    AacEventRepository.instance.logTap(
      card: widget.card,
      category: widget.card.category,
      sentenceSpoken: sentence,
      language: widget.language,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AacConfirmationScreen(
          category: widget.card.category,
          glyph: aacGlyph(emojiForCard(option.id), size: 120),
          sentence: sentence,
          bundledAudioAsset: option.audioAsset[widget.language],
          language: widget.language,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aac = AacTheme.of(context);

    return Scaffold(
      backgroundColor: aac.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(FkSpacing.md),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(Icons.arrow_back_rounded, color: aac.ink),
                  ),
                  Expanded(
                    child: Text(
                      _labelFor(widget.card.label, widget.card.id),
                      style: FkTextStyles.playHeadline.copyWith(color: aac.ink),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Wrap(
                  spacing: AacSizes.gridGapAdvanced,
                  runSpacing: AacSizes.gridGapAdvanced,
                  alignment: WrapAlignment.center,
                  children: widget.card.fringeOptions.map((option) {
                    return AacCard(
                      category: widget.card.category,
                      label: _labelFor(option.label, option.id),
                      glyph: aacGlyph(emojiForCard(option.id),
                          size: _settings.cardSize.pixels * 0.5),
                      size: _settings.cardSize.pixels,
                      dwellEnabled: _settings.dwellEnabled,
                      dwellDuration: _settings.dwellDuration,
                      highContrast: _settings.highContrast,
                      onActivate: () => _onOptionActivate(option),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
