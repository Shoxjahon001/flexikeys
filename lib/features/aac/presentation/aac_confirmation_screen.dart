library aac_confirmation_screen;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../data/aac_audio_player.dart';
import '../domain/aac_card_def.dart';
import 'aac_strings.dart';

/// Full-screen confirmation overlay — steps 2-6 of the tap sequence in
/// docs/aac_design_system.md §4: the loop animation plays full-screen, the
/// sentence is spoken as it begins (not after), the sentence text appears
/// alongside the voice, and it auto-dismisses once spoken — or the child
/// can tap the checkmark to replay, or the close affordance (top-left) if
/// the tap was a mistake.
class AacConfirmationScreen extends StatefulWidget {
  final AacCategory category;

  /// See [AacCard.glyph] — a parent-provided photo (custom cards) or the
  /// emoji placeholder, resolved by the caller via `glyphForCard()`.
  final Widget glyph;
  final String sentence;
  final String? bundledAudioAsset;
  final AacLanguage language;

  /// True when [bundledAudioAsset] is a parent-recorded custom-card voice
  /// (a real device file path) rather than a bundled starter-vocabulary
  /// asset — see [AacAudioPlayer.speak]'s `isDeviceFile` doc comment.
  final bool isDeviceAudioFile;

  const AacConfirmationScreen({
    super.key,
    required this.category,
    required this.glyph,
    required this.sentence,
    required this.bundledAudioAsset,
    required this.language,
    this.isDeviceAudioFile = false,
  });

  @override
  State<AacConfirmationScreen> createState() => _AacConfirmationScreenState();
}

class _AacConfirmationScreenState extends State<AacConfirmationScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _loop;
  Timer? _autoDismiss;

  @override
  void initState() {
    super.initState();
    // Reads the OS-level flag directly rather than MediaQuery.of(context) —
    // an InheritedWidget dependency isn't allowed to be established before
    // initState() finishes; build()/AppMotion.reduced(context) is used
    // for the same check everywhere else in this screen.
    final reduced = WidgetsBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    _entrance = AnimationController(
      vsync: this,
      duration: reduced ? Duration.zero : FkDurations.normal,
    )..forward();
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // within AacSizes.animationLoop*
    )..repeat(reverse: true);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _speakAndScheduleDismiss());
  }

  Future<void> _speakAndScheduleDismiss() async {
    _autoDismiss?.cancel();
    await AacAudioPlayer.instance.speak(
      bundledAssetPath: widget.bundledAudioAsset,
      sentence: widget.sentence,
      language: widget.language,
      isDeviceFile: widget.isDeviceAudioFile,
    );
    if (!mounted) return;
    _autoDismiss = Timer(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  void dispose() {
    _autoDismiss?.cancel();
    _entrance.dispose();
    _loop.dispose();
    AacAudioPlayer.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aac = AacTheme.of(context);
    final reduced = AppMotion.reduced(context);
    final accent = aac.colorFor(widget.category);

    return Scaffold(
      backgroundColor: accent,
      body: SafeArea(
        child: FadeTransition(
          opacity: _entrance,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: _entrance, curve: FkCurves.gentle),
            child: Stack(
              children: [
                Positioned(
                  top: FkSpacing.md,
                  left: FkSpacing.md,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    tooltip: AacStrings.of(widget.language).closeTooltip,
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 32),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ConfirmationGlyph(
                        glyph: widget.glyph,
                        controller: _loop,
                        reduced: reduced,
                      ),
                      const SizedBox(height: FkSpacing.lg),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: FkSpacing.lg),
                        child: Text(
                          widget.sentence,
                          style: FkTextStyles.playDisplay
                              .copyWith(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: FkSpacing.lg,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Semantics(
                      label: AacStrings.of(widget.language).replayTooltip,
                      button: true,
                      excludeSemantics: true,
                      onTap: _speakAndScheduleDismiss,
                      child: GestureDetector(
                        onTap: _speakAndScheduleDismiss,
                        child: Container(
                          width: AacSizes.cardMin,
                          height: AacSizes.cardMin,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: FkElevation.medium(Colors.black),
                          ),
                          child: Icon(Icons.check_rounded,
                              color: accent, size: 48),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfirmationGlyph extends StatelessWidget {
  final Widget glyph;
  final AnimationController controller;
  final bool reduced;

  const _ConfirmationGlyph({
    required this.glyph,
    required this.controller,
    required this.reduced,
  });

  @override
  Widget build(BuildContext context) {
    if (reduced) return glyph;
    final scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
    return AnimatedBuilder(
      animation: scaleAnim,
      builder: (context, child) =>
          Transform.scale(scale: scaleAnim.value, child: child),
      child: glyph,
    );
  }
}
