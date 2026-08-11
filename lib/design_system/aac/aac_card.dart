library aac_card;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../fk_tokens.dart';
import '../tokens/app_color_theme.dart';
import '../tokens/app_motion.dart';
import 'aac_theme.dart';

/// The primary interaction unit of the "My Voice" AAC module — one
/// vocabulary card. Implements the tap-physics steps of the sequence in
/// docs/aac_design_system.md §4 (touch-down scale + haptic, release/dwell
/// completion calls [onActivate]). The full-screen confirmation (steps 3-6:
/// overlay, voice, text, dismiss) is a separate caller-owned step — this
/// widget only decides *when* an activation happened, not what follows it.
///
/// [icon] is a placeholder animation-area glyph. No per-card illustration
/// or Lottie assets exist yet (see docs/aac_design_system.md §0 — Lottie
/// was deliberately not added this pass since there are no real animation
/// files to play), so a gentle looping icon stands in for the "loop
/// illustration, 3-5s" requirement until real artwork is produced. Swapping
/// this for a Lottie/CustomPainter loop later only touches this one widget.
class AacCard extends StatefulWidget {
  final AacCategory category;
  final String label;

  /// The animation-area content — an emoji glyph today (see
  /// docs/aac_design_system.md §0: no per-card illustration/Lottie assets
  /// exist yet, and abstract icons don't cover fruit/body-part/activity
  /// vocabulary well enough for a pre-literate child). Any widget works, so
  /// a future Lottie/CustomPainter loop can replace it without touching
  /// this card's layout or interaction logic.
  final Widget glyph;
  final double size;
  final VoidCallback onActivate;

  /// Replays this card's audio in place, without triggering [onActivate]'s
  /// navigation/confirmation flow — the reference mockup's dedicated
  /// speaker button, for a child who wants to hear a word again without
  /// leaving the grid. Callers already hold everything needed to speak the
  /// card (`AacAudioPlayer.instance.speak(...)`) at their existing
  /// [onActivate] call sites, so this stays a plain callback rather than
  /// this widget importing the audio player itself.
  final VoidCallback onSpeak;

  /// Accessible label for the speaker button (e.g. "Speak"/"Gapirish"/
  /// "Сказать" — see `AacStrings.speakTooltip`). Passed in rather than
  /// looked up here to keep this design-system widget independent of the
  /// `features/aac` string catalog.
  final String speakLabel;

  /// Alternate activation trigger for severe motor impairment (parent
  /// setting) — touch-and-hold for [dwellDuration] activates instead of
  /// tap-release; releasing early cancels. See §4 "Dwell-time activation".
  final bool dwellEnabled;
  final Duration dwellDuration;

  /// Parent setting (`AacSettings.highContrast`): solid white surface +
  /// thicker full-saturation border instead of the default soft tint — a
  /// further contrast boost on top of the AAA-by-default palette.
  final bool highContrast;

  const AacCard({
    super.key,
    required this.category,
    required this.label,
    required this.glyph,
    required this.onActivate,
    required this.onSpeak,
    required this.speakLabel,
    this.size = AacSizes.cardMax,
    this.dwellEnabled = false,
    this.dwellDuration = AacSizes.dwellDefault,
    this.highContrast = false,
  });

  @override
  State<AacCard> createState() => _AacCardState();
}

class _AacCardState extends State<AacCard> with TickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _pressAnim;
  late final AnimationController _dwellController;
  late final AnimationController _loopController;

  DateTime? _lastActivation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: FkDurations.fast,
      value: 1.0,
    );
    _pressAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pressController, curve: FkCurves.spring),
    );
    _dwellController = AnimationController(
      vsync: this,
      duration: widget.dwellDuration,
    );
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // within AacSizes.animationLoop*
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant AacCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dwellDuration != widget.dwellDuration) {
      _dwellController.duration = widget.dwellDuration;
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    _dwellController.dispose();
    _loopController.dispose();
    super.dispose();
  }

  bool _debounced() {
    final now = DateTime.now();
    if (_lastActivation != null &&
        now.difference(_lastActivation!) < AacSizes.tapDebounce) {
      return true;
    }
    _lastActivation = now;
    return false;
  }

  void _activate() {
    if (_debounced()) return;
    widget.onActivate();
  }

  void _onTapDown(TapDownDetails _) {
    HapticFeedback.mediumImpact();
    if (!AppMotion.reduced(context)) _pressController.forward();
    if (widget.dwellEnabled) {
      _dwellController.forward(from: 0).whenCompleteOrCancel(() {
        if (mounted && _dwellController.isCompleted) _activate();
      });
    }
  }

  void _onTapUp(TapUpDetails _) {
    _pressController.reverse();
    if (widget.dwellEnabled) {
      // Dwell mode: release before the ring completes cancels the
      // activation rather than firing it — a tap alone never activates.
      _dwellController.stop();
      _dwellController.reset();
      return;
    }
    _activate();
  }

  void _onTapCancel() {
    _pressController.reverse();
    if (widget.dwellEnabled) {
      _dwellController.stop();
      _dwellController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final aac = AacTheme.of(context);
    final reduced = AppMotion.reduced(context);
    final accent = aac.colorFor(widget.category);
    final primary = context.colors.primary;
    // Upper bound raised from 44 alongside AacCardSizeSetting's 240-320px
    // range (was 120-160) — the old ceiling capped the button well below
    // its proportional 0.26 share once cards got bigger, leaving it looking
    // undersized next to the larger card.
    final speakerSize = (widget.size * 0.26).clamp(32.0, 88.0);

    // Reference mockup: a plain white card (category color now lives only
    // on the border, not as a fill) with the illustration sitting directly
    // on white, and label + a dedicated speaker button sharing a bottom row
    // instead of the label owning its own tinted band.
    final card = Container(
      width: widget.size,
      height: widget.size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: aac.surface,
        borderRadius: BorderRadius.circular(AacSizes.cardRadius),
        boxShadow: FkElevation.low(aac.inkSoft),
        border: Border.all(
          color: widget.highContrast
              ? accent
              : aac.inkSoft.withValues(alpha: 0.14),
          width: widget.highContrast ? 3 : 1,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(FkSpacing.sm),
              child: Center(
                // FittedBox guards against clipping regardless of how big a
                // glyph's own intrinsic size is (an emoji Text's fontSize,
                // or glyphForCard's fixed-size Image for a custom photo) —
                // callers pass a size proportional to the card, and without
                // this the illustration could render larger than the space
                // actually available and get cut off by the card's
                // clipBehavior: Clip.antiAlias.
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: ExcludeSemantics(
                    child: _AnimationArea(
                      controller: _loopController,
                      reduced: reduced,
                      child: widget.glyph,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                FkSpacing.sm, 0, FkSpacing.xs, FkSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  // FittedBox (same reasoning as the illustration area
                  // above and AacCategoryTile's label) — without it, a
                  // longer word in some languages wrapping to 2 lines grows
                  // this row taller and squeezes the illustration area
                  // above it instead of just shrinking the label itself.
                  child: ExcludeSemantics(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.label,
                        style: FkTextStyles.playHeadline
                            .copyWith(color: aac.ink, fontSize: 15),
                        maxLines: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: FkSpacing.xxs),
                Semantics(
                  button: true,
                  label: widget.speakLabel,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onSpeak();
                    },
                    child: Container(
                      width: speakerSize,
                      height: speakerSize,
                      decoration:
                          BoxDecoration(color: primary, shape: BoxShape.circle),
                      child: Icon(Icons.volume_up_rounded,
                          color: Colors.white, size: speakerSize * 0.55),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Semantics(
      // One clean actionable node for screen readers/switch access covering
      // the card's main activation. NOT excludeSemantics: true — the label
      // Text and glyph are individually wrapped in ExcludeSemantics above
      // (so this node's own `label` isn't announced twice), but the speaker
      // button further down needs to surface as its own reachable,
      // independently-actionable node (two focus stops, like a ListTile
      // with a trailing IconButton) rather than being swallowed into this
      // one — a screen-reader/switch-access user must be able to replay
      // the word without also triggering the full activation flow. Routes
      // straight to _activate() regardless of dwellEnabled: dwell timing
      // exists to filter imprecise touch input, which doesn't apply to a
      // switch-access "select" action.
      label: widget.label,
      button: true,
      onTap: _activate,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _pressAnim,
              builder: (context, child) => Transform.scale(
                scale: reduced ? 1.0 : _pressAnim.value,
                child: child,
              ),
              child: card,
            ),
            if (widget.dwellEnabled)
              AnimatedBuilder(
                animation: _dwellController,
                builder: (context, _) => _dwellController.value <= 0
                    ? const SizedBox.shrink()
                    : IgnorePointer(
                        child: SizedBox(
                          width: widget.size + 12,
                          height: widget.size + 12,
                          child: CircularProgressIndicator(
                            value: _dwellController.value,
                            strokeWidth: 4,
                            color: accent,
                            backgroundColor: accent.withValues(alpha: 0.15),
                          ),
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AnimationArea extends StatelessWidget {
  final Widget child;
  final AnimationController controller;
  final bool reduced;

  const _AnimationArea({
    required this.child,
    required this.controller,
    required this.reduced,
  });

  @override
  Widget build(BuildContext context) {
    if (reduced) return child;
    final scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
    return AnimatedBuilder(
      animation: scaleAnim,
      builder: (context, animatedChild) => Transform.scale(
        scale: scaleAnim.value,
        child: animatedChild,
      ),
      child: child,
    );
  }
}
