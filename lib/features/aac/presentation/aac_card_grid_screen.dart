library aac_card_grid_screen;

import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../data/aac_card_repository.dart';
import '../data/aac_event_repository.dart';
import '../data/aac_settings_store.dart';
import '../domain/aac_card_def.dart';
import 'aac_confirmation_screen.dart';
import 'aac_fringe_screen.dart';
import 'aac_glyphs.dart';
import 'aac_sentence_strip_screen.dart';
import 'aac_strings.dart';

/// One category's vocabulary — docs/aac_design_system.md §2.2/§3. Direct
/// cards speak immediately via [AacConfirmationScreen]; branch cards open
/// [AacFringeScreen] first. Real mastery-gated progression (which tiers are
/// unlocked) needs a persisted `AacProgressionState` store that doesn't
/// exist yet (see docs/aac_phase1_architecture.md "Progression system") —
/// until that lands, this screen shows the category's lowest-difficulty
/// cards up to the grid rule's hard ceiling of 6, not a real unlock state.
class AacCardGridScreen extends StatefulWidget {
  final AacCategory category;
  final String categoryLabel;
  final AacLanguage language;

  const AacCardGridScreen({
    super.key,
    required this.category,
    required this.categoryLabel,
    required this.language,
  });

  @override
  State<AacCardGridScreen> createState() => _AacCardGridScreenState();
}

class _AacCardGridScreenState extends State<AacCardGridScreen> {
  static const _maxCardsPerScreen = 6; // docs §3 grid rule — hard ceiling

  List<AacCardDef> _cards = const [];
  AacSettings _settings = const AacSettings();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      AacCardRepository.instance.loadCategory(widget.category),
      AacSettingsStore.instance.get(),
    ]);
    final cards = (results[0] as List<AacCardDef>)
      ..sort((a, b) => a.difficultyTier.compareTo(b.difficultyTier));
    if (!mounted) return;
    setState(() {
      _cards = cards.take(_maxCardsPerScreen).toList();
      _settings = results[1] as AacSettings;
      _loading = false;
    });
  }

  String _labelFor(AacCardDef card) =>
      card.label[widget.language] ?? card.label[AacLanguage.en] ?? card.id;

  void _onCardActivate(AacCardDef card) {
    if (card.kind == AacCardKind.branch) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AacFringeScreen(card: card, language: widget.language),
        ),
      );
      return;
    }

    final sentence = card.sentenceFor(widget.language);
    AacEventRepository.instance.logTap(
      card: card,
      category: widget.category,
      sentenceSpoken: sentence,
      language: widget.language,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AacConfirmationScreen(
          category: widget.category,
          glyph: glyphForCard(card, size: 120),
          sentence: sentence,
          bundledAudioAsset: card.audioAsset[widget.language],
          isDeviceAudioFile: card.isCustom,
          language: widget.language,
        ),
      ),
    );
  }

  void _openSentenceStrip() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AacSentenceStripScreen(
          category: widget.category,
          categoryLabel: widget.categoryLabel,
          cards: _cards,
          language: widget.language,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aac = AacTheme.of(context);
    final accent = aac.colorFor(widget.category);

    return Scaffold(
      backgroundColor: aac.background,
      body: SafeArea(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: accent))
            : Column(
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
                            widget.categoryLabel,
                            style: FkTextStyles.playHeadline.copyWith(color: aac.ink),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          onPressed: _cards.isEmpty ? null : _openSentenceStrip,
                          tooltip: AacStrings.of(widget.language).buildSentenceTooltip,
                          icon: Icon(Icons.forum_rounded, color: aac.ink),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Wrap(
                        spacing: AacSizes.gridGapAdvanced,
                        runSpacing: AacSizes.gridGapAdvanced,
                        alignment: WrapAlignment.center,
                        children: _cards.map((card) {
                          return AacCard(
                            category: widget.category,
                            label: _labelFor(card),
                            glyph: glyphForCard(card),
                            size: _settings.cardSize.pixels,
                            dwellEnabled: _settings.dwellEnabled,
                            dwellDuration: _settings.dwellDuration,
                            highContrast: _settings.highContrast,
                            onActivate: () => _onCardActivate(card),
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
