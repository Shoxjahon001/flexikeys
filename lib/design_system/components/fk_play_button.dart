library fk_play_button;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/app_color_theme.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_shadows.dart';

/// Large hero play/pause button for detail-speak screens — 72dp,
/// [AppShadows.primaryGlow], morphs play↔pause, radial pulse while
/// [playing].
class FkPlayButton extends StatefulWidget {
  final bool playing;
  final VoidCallback? onPressed;
  final String semanticLabel;

  const FkPlayButton({
    super.key,
    required this.playing,
    this.onPressed,
    this.semanticLabel = 'Play',
  });

  @override
  State<FkPlayButton> createState() => _FkPlayButtonState();
}

class _FkPlayButtonState extends State<FkPlayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    final primary = context.colors.primary;

    return Semantics(
      button: true,
      enabled: widget.onPressed != null,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTap: () {
          if (widget.onPressed != null) HapticFeedback.mediumImpact();
          widget.onPressed?.call();
        },
        child: SizedBox(
          width: 96,
          height: 96,
          child: Center(
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) {
                final t = widget.playing && !reduced ? _pulse.value : 0.0;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    if (t > 0)
                      Container(
                        width: 72 + t * 24,
                        height: 72 + t * 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primary.withValues(alpha: (1 - t) * 0.2),
                        ),
                      ),
                    child!,
                  ],
                );
              },
              child: AnimatedContainer(
                duration: AppMotion.base,
                curve: AppMotion.transition,
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary,
                  boxShadow: AppShadows.primaryGlow,
                ),
                child: AnimatedSwitcher(
                  duration: AppMotion.fast,
                  child: Icon(
                    widget.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    key: ValueKey(widget.playing),
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
