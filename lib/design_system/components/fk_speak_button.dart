library fk_speak_button;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/app_color_theme.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_shadows.dart';

/// Small circular speaker button pinned to a card corner — 40dp visual
/// circle inside a 48dp tap target, with animated pulse rings while
/// [playing]. Distinct from the full-size hero [FkPlayButton].
class FkSpeakButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool playing;
  final String semanticLabel;

  const FkSpeakButton({
    super.key,
    this.onPressed,
    this.playing = false,
    this.semanticLabel = 'Play sound',
  });

  @override
  State<FkSpeakButton> createState() => _FkSpeakButtonState();
}

class _FkSpeakButtonState extends State<FkSpeakButton>
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
          if (widget.onPressed != null) HapticFeedback.selectionClick();
          widget.onPressed?.call();
        },
        child: SizedBox(
          width: 48,
          height: 48,
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
                        width: 40 + t * 16,
                        height: 40 + t * 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primary.withValues(alpha: (1 - t) * 0.25),
                        ),
                      ),
                    child!,
                  ],
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary,
                  boxShadow: AppShadows.soft,
                ),
                child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
