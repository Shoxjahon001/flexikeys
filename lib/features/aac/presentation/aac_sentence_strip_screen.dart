library aac_sentence_strip_screen;

import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../data/aac_audio_player.dart';
import '../data/aac_event_repository.dart';
import '../data/aac_milestones_store.dart';
import '../data/aac_sentence_composer_service.dart';
import '../data/aac_settings_store.dart';
import '../domain/aac_card_def.dart';
import 'aac_glyphs.dart';
import 'aac_strings.dart';

/// Level-4 "sentence building" mode (docs/aac_design_system.md §Phase
/// 2.5): tapping a card appends its word to the [SentenceStrip] instead of
/// immediately opening the full-screen confirmation; a speak button reads
/// the assembled sentence aloud. Branch cards are excluded here — picking
/// a fringe option first requires the single-card confirmation flow, and
/// guessing a default fringe choice for strip-building would misrepresent
/// what the child actually selected.
class AacSentenceStripScreen extends StatefulWidget {
  final AacCategory category;
  final String categoryLabel;
  final List<AacCardDef> cards;
  final AacLanguage language;

  const AacSentenceStripScreen({
    super.key,
    required this.category,
    required this.categoryLabel,
    required this.cards,
    required this.language,
  });

  @override
  State<AacSentenceStripScreen> createState() => _AacSentenceStripScreenState();
}

class _AacSentenceStripScreenState extends State<AacSentenceStripScreen> {
  final List<SentenceStripEntry> _entries = [];
  final List<AacCardDef> _entryCards = [];
  AacSettings _settings = const AacSettings();
  bool _composing = false;
  bool _celebrating = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await AacSettingsStore.instance.get();
    if (mounted) setState(() => _settings = settings);
  }

  String _labelFor(AacCardDef card) =>
      card.label[widget.language] ?? card.label[AacLanguage.en] ?? card.id;

  void _addCard(AacCardDef card) {
    setState(() {
      _entries.add(SentenceStripEntry(
          emoji: emojiForCard(card.id), word: _labelFor(card)));
      _entryCards.add(card);
    });
  }

  void _clear() => setState(() {
        _entries.clear();
        _entryCards.clear();
      });

  Future<void> _speak() async {
    if (_entryCards.isEmpty || _composing) return;
    setState(() => _composing = true);

    // AI-upgraded phrasing when a backend/network is reachable ("I want
    // cold water, please."), naive word-join otherwise/offline (see
    // AacSentenceComposerService) — never silence either way.
    final sentence = await AacSentenceComposerService.instance.compose(
      words: _entries.map((e) => e.word).toList(),
      language: widget.language,
    );

    if (!mounted) return;
    setState(() => _composing = false);

    // Representative event: card_id logs the first tapped card while
    // sentence_spoken carries the full composite utterance — a multi-card
    // strip doesn't map to one AacCardDef the way a single tap does.
    AacEventRepository.instance.logTap(
      card: _entryCards.first,
      category: widget.category,
      sentenceSpoken: sentence,
      language: widget.language,
    );
    // No bundled audio exists for an ad-hoc word sequence — always TTS.
    await AacAudioPlayer.instance.speak(
      bundledAssetPath: null,
      sentence: sentence,
      language: widget.language,
    );

    await _maybeCelebrateFirstSentence();
  }

  /// A single, calm, one-time celebration the first time a child completes
  /// a real multi-word Sentence Strip utterance (Phase 5: "confetti only
  /// for milestones... celebration ≠ distraction" — reuses [FkStarBurst]
  /// as-is rather than inventing new confetti, since it's already exactly
  /// this: soft pastel particles, disabled under reduced motion, never
  /// shown for every-day taps). Single words on the Card Grid already have
  /// their own confirmation moment — this is specifically for the
  /// Sentence-Strip milestone the original spec calls out.
  Future<void> _maybeCelebrateFirstSentence() async {
    if (_entries.length < 2) return;
    if (await AacMilestonesStore.instance.hasCelebratedFirstSentence()) return;
    await AacMilestonesStore.instance.markFirstSentenceCelebrated();
    if (!mounted) return;
    setState(() => _celebrating = true);
    await Future.delayed(FkDurations.slow);
    if (mounted) setState(() => _celebrating = false);
  }

  @override
  Widget build(BuildContext context) {
    final aac = AacTheme.of(context);
    final directCards =
        widget.cards.where((c) => c.kind == AacCardKind.direct).toList();

    return Scaffold(
      backgroundColor: aac.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
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
                          style: FkTextStyles.playHeadline
                              .copyWith(color: aac.ink),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                SentenceStrip(
                  entries: _entries,
                  onSpeak: _composing ? null : _speak,
                  onClear: _composing ? null : _clear,
                  placeholderText:
                      AacStrings.of(widget.language).sentenceStripPlaceholder,
                  speakTooltip: AacStrings.of(widget.language).speakTooltip,
                  clearTooltip: AacStrings.of(widget.language).clearTooltip,
                ),
                const SizedBox(height: FkSpacing.md),
                Expanded(
                  child: Center(
                    child: Wrap(
                      spacing: AacSizes.gridGapAdvanced,
                      runSpacing: AacSizes.gridGapAdvanced,
                      alignment: WrapAlignment.center,
                      children: directCards.map((card) {
                        return AacCard(
                          category: widget.category,
                          label: _labelFor(card),
                          glyph: glyphForCard(card),
                          size: _settings.cardSize.pixels,
                          dwellEnabled: _settings.dwellEnabled,
                          dwellDuration: _settings.dwellDuration,
                          highContrast: _settings.highContrast,
                          onActivate: () => _addCard(card),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
            IgnorePointer(
              child: Center(
                child: FkStarBurst(active: _celebrating, size: 240),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
