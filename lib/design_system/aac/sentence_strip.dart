library sentence_strip;

import 'package:flutter/material.dart';

import '../fk_tokens.dart';
import 'aac_theme.dart';

/// One word added to a [SentenceStrip] — a card's emoji glyph plus the
/// spoken word for that tap.
class SentenceStripEntry {
  final String emoji;
  final String word;

  const SentenceStripEntry({required this.emoji, required this.word});
}

/// A horizontal strip of tapped words building toward one spoken sentence —
/// docs/aac_design_system.md §Phase 2.5 "Sentence Strip". Core-vocabulary
/// AAC practice at this level is word juxtaposition ("Mom water"), not
/// grammatical sentence assembly — the strip shows exactly the words
/// tapped, in order, with speak/clear controls.
class SentenceStrip extends StatelessWidget {
  final List<SentenceStripEntry> entries;
  final VoidCallback? onSpeak;
  final VoidCallback? onClear;

  /// Localized by the caller (see `AacStrings`) — this widget has no sense
  /// of the active AAC language itself. English defaults only cover a
  /// caller that hasn't been updated; every real call site passes these.
  final String placeholderText;
  final String speakTooltip;
  final String clearTooltip;

  const SentenceStrip({
    super.key,
    required this.entries,
    this.onSpeak,
    this.onClear,
    this.placeholderText = 'Tap cards to build a sentence',
    this.speakTooltip = 'Speak',
    this.clearTooltip = 'Clear',
  });

  @override
  Widget build(BuildContext context) {
    final aac = AacTheme.of(context);
    return Container(
      // Fixed, not minHeight: the horizontal ListView of tapped words below
      // needs a bounded cross-axis extent to lay out, and a plain Column
      // parent (e.g. AacSentenceStripScreen) gives an unconstrained child
      // unbounded height rather than the finite height a Scaffold.body would.
      height: 96,
      margin: const EdgeInsets.symmetric(horizontal: FkSpacing.md),
      padding: const EdgeInsets.symmetric(horizontal: FkSpacing.sm, vertical: FkSpacing.xs),
      decoration: BoxDecoration(
        color: aac.surface,
        borderRadius: BorderRadius.circular(FkRadii.md),
        boxShadow: FkElevation.low(aac.ink),
      ),
      child: Row(
        children: [
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Text(
                      placeholderText,
                      style: FkTextStyles.playLabel.copyWith(color: aac.inkSoft),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(width: FkSpacing.xs),
                    itemBuilder: (context, i) => _StripChip(entry: entries[i]),
                  ),
          ),
          IconButton(
            onPressed: entries.isEmpty ? null : onSpeak,
            tooltip: speakTooltip,
            icon: Icon(Icons.volume_up_rounded, color: aac.ink),
          ),
          IconButton(
            onPressed: entries.isEmpty ? null : onClear,
            tooltip: clearTooltip,
            icon: Icon(Icons.backspace_rounded, color: aac.ink),
          ),
        ],
      ),
    );
  }
}

class _StripChip extends StatelessWidget {
  final SentenceStripEntry entry;

  const _StripChip({required this.entry});

  @override
  Widget build(BuildContext context) {
    final aac = AacTheme.of(context);
    return Container(
      width: 72,
      padding: const EdgeInsets.all(FkSpacing.xxs),
      decoration: BoxDecoration(
        color: aac.background,
        borderRadius: BorderRadius.circular(FkRadii.sm),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(entry.emoji, style: const TextStyle(fontSize: 28)),
          Text(
            entry.word,
            style: FkTextStyles.playLabel.copyWith(color: aac.ink, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
