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
import 'aac_language.dart';
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

  const AacCardGridScreen({
    super.key,
    required this.category,
    required this.categoryLabel,
  });

  @override
  State<AacCardGridScreen> createState() => _AacCardGridScreenState();
}

class _AacCardGridScreenState extends State<AacCardGridScreen> {
  List<AacCardDef> _cards = const [];
  AacSettings _settings = const AacSettings();
  bool _loading = true;
  AacLanguage _language = AacLanguage.en;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // aacLanguageOf(context) reads Localizations.localeOf(context), so this
  // re-runs whenever the app's interface language changes — even if this
  // screen was already open when that happened (see aac_language.dart).
  // Cards don't need re-fetching: every AacCardDef already carries all 3
  // languages, _labelFor just re-indexes into the new one on rebuild.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = aacLanguageOf(context);
    if (next != _language) {
      // A word mid-speech in the old language must not keep playing over
      // the new one.
      AacAudioPlayer.instance.stop();
      setState(() => _language = next);
    }
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
      card.label[_language] ?? card.label[AacLanguage.en] ?? card.id;

  void _onCardActivate(AacCardDef card) {
    if (card.kind == AacCardKind.branch) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AacFringeScreen(card: card),
        ),
      );
      return;
    }

    final sentence = card.sentenceFor(_language);
    AacEventRepository.instance.logTap(
      card: card,
      category: widget.category,
      sentenceSpoken: sentence,
      language: _language,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AacConfirmationScreen(
          category: widget.category,
          glyph: glyphForCard(card, size: 120),
          sentence: sentence,
          bundledAudioAsset: card.audioAsset[_language],
          isDeviceAudioFile: card.isCustom,
          language: _language,
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
            semanticLabel: AacStrings.of(_language).buildSentenceTooltip,
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
            //
            // LayoutBuilder computes the actual 2-column card width from
            // the real available width, rather than rendering
            // _settings.cardSize.pixels literally and hoping 2 happen to
            // fit — a fixed pixel size only fits on some device widths, and
            // guessing new magic numbers per device report doesn't scale.
            // cardSize.pixels is now a ceiling (the parent's size
            // preference), not a guaranteed literal size: on a narrow phone
            // the card shrinks to whatever actually fits 2-per-row; on a
            // wide tablet it's capped at the preference instead of
            // stretching arbitrarily large.
            : LayoutBuilder(
                builder: (context, constraints) {
                  const horizontalPadding = AppSpacing.md;
                  const gap = FkSpacing.sm;
                  final available =
                      constraints.maxWidth - horizontalPadding * 2;
                  final fitWidth = (available - gap) / 2;
                  final cardSize =
                      fitWidth.clamp(96.0, _settings.cardSize.pixels);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: horizontalPadding, vertical: AppSpacing.lg),
                    // Center, not just Wrap's own `alignment: center` —
                    // SingleChildScrollView gives its child loose (not
                    // tight) cross-axis constraints, so Wrap shrinks to fit
                    // its own content instead of filling the screen width.
                    // WrapAlignment.center then only centers within that
                    // already-shrunk box (a no-op once it's exactly as wide
                    // as its content), and the scroll view left-aligns the
                    // whole narrower block by default — cards hugging the
                    // left edge with all the leftover space pushed to the
                    // right, exactly the reported bug. Center forces the
                    // Wrap to actually center against the full width.
                    child: Center(
                      child: Wrap(
                        spacing: gap,
                        runSpacing: AacSizes.gridGapAdvanced,
                        alignment: WrapAlignment.center,
                        children: _cards.map((card) {
                          return AacCard(
                            category: widget.category,
                            label: _labelFor(card),
                            glyph: glyphForCard(card, size: cardSize * 0.5),
                            size: cardSize,
                            dwellEnabled: _settings.dwellEnabled,
                            dwellDuration: _settings.dwellDuration,
                            highContrast: _settings.highContrast,
                            onActivate: () => _onCardActivate(card),
                            onSpeak: () => AacAudioPlayer.instance.speak(
                              bundledAssetPath: card.audioAsset[_language],
                              // A branch card's sentenceTemplate has an
                              // unfilled {noun} placeholder until a fringe
                              // option is chosen (see
                              // AacCardDef.sentenceFor) — the label itself
                              // ("Food") is what the speaker button should
                              // say for those, not the raw template.
                              sentence: card.kind == AacCardKind.branch
                                  ? _labelFor(card)
                                  : card.sentenceFor(_language),
                              language: _language,
                              isDeviceFile: card.isCustom,
                            ),
                            speakLabel: AacStrings.of(_language).speakTooltip,
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
