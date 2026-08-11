library aac_card_grid_screen;

import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../data/aac_audio_player.dart';
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
    final all = results[0] as List<AacCardDef>;
    // No cap: every card in the category shows, not just the first 6 by
    // difficulty tier. Built-in cards keep the tier-based teaching
    // progression; custom cards (always tier 1, see
    // aac_card_manager_screen.dart's _save()) are appended after in the
    // order they were created rather than sorted into that progression —
    // a newly-added card must land at the end, never bump an existing
    // built-in card out of view the way the old sort+take(6) could.
    final builtIn = all.where((c) => !c.isCustom).toList()
      ..sort((a, b) => a.difficultyTier.compareTo(b.difficultyTier));
    final custom = all.where((c) => c.isCustom).toList();
    if (!mounted) return;
    setState(() {
      _cards = [...builtIn, ...custom];
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
          builder: (_) =>
              AacFringeScreen(card: card, language: widget.language),
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
      appBar: FkAppBar(
        title: widget.categoryLabel,
        onBack: () => Navigator.of(context).maybePop(),
        actions: [
          FkAppBarAction(
            icon: Icons.forum_rounded,
            semanticLabel: AacStrings.of(widget.language).buildSentenceTooltip,
            onPressed: _cards.isEmpty ? null : _openSentenceStrip,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? Center(child: CircularProgressIndicator(color: accent))
            // Scrollable, not Center-only: with the per-screen cap removed
            // a category can hold more cards than fit one viewport, and
            // this must never overflow. Padding lets the grid genuinely
            // fill the screen edge-to-edge rather than float in the middle
            // with unused space on either side.
            : SingleChildScrollView(
                // Tighter than AppSpacing.lg/AacSizes.gridGapAdvanced
                // (this screen's only deviation from those) — at the
                // current 170-200px card tiers, the roomier defaults
                // pushed 2-per-row past standard ~390pt phone widths,
                // dropping to a lopsided 1-per-row. This reclaims just
                // enough width to keep 2 equal-width cards on one row.
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.lg),
                child: Wrap(
                  spacing: FkSpacing.sm,
                  runSpacing: AacSizes.gridGapAdvanced,
                  alignment: WrapAlignment.center,
                  children: _cards.map((card) {
                    // The glyph helper's own default (56) is a fixed
                    // absolute size that never scaled with the card itself,
                    // so a 160px "xxl" card rendered the same small emoji
                    // as a 120px "l" one — proportional instead, ~50% of
                    // the card so it actually fills the accent-colored
                    // icon area (Expanded flex:65 in AacCard).
                    return AacCard(
                      category: widget.category,
                      label: _labelFor(card),
                      glyph: glyphForCard(card,
                          size: _settings.cardSize.pixels * 0.5),
                      size: _settings.cardSize.pixels,
                      dwellEnabled: _settings.dwellEnabled,
                      dwellDuration: _settings.dwellDuration,
                      highContrast: _settings.highContrast,
                      onActivate: () => _onCardActivate(card),
                      onSpeak: () => AacAudioPlayer.instance.speak(
                        bundledAssetPath: card.audioAsset[widget.language],
                        // A branch card's sentenceTemplate has an unfilled
                        // {noun} placeholder until a fringe option is
                        // chosen (see AacCardDef.sentenceFor) — the label
                        // itself ("Food") is what the speaker button should
                        // say for those, not the raw template.
                        sentence: card.kind == AacCardKind.branch
                            ? _labelFor(card)
                            : card.sentenceFor(widget.language),
                        language: widget.language,
                        isDeviceFile: card.isCustom,
                      ),
                      speakLabel: AacStrings.of(widget.language).speakTooltip,
                    );
                  }).toList(),
                ),
              ),
      ),
    );
  }
}
