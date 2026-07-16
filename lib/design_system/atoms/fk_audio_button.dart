library fk_audio_button;

import 'package:flutter/material.dart';
import '../fk_tokens.dart';
import '../fk_theme.dart';

/// Replay-pronunciation button. Pulses when audio is playing.
class FkAudioButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool playing;
  final double size;

  const FkAudioButton({
    super.key,
    this.onPressed,
    this.playing = false,
    this.size = 56,
  });

  @override
  State<FkAudioButton> createState() => _FkAudioButtonState();
}

class _FkAudioButtonState extends State<FkAudioButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: FkDurations.normal,
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulse, curve: FkCurves.gentle),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fk = FkTheme.of(context);
    final reduced = FkTheme.reducedMotion(context);

    return GestureDetector(
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (context, child) {
          final scale = (!reduced && widget.playing) ? _pulseAnim.value : 1.0;
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: fk.primary,
            shape: BoxShape.circle,
            boxShadow: FkElevation.low(fk.ink),
          ),
          child: Icon(
            widget.playing ? Icons.volume_up_rounded : Icons.play_arrow_rounded,
            color: fk.ink,
            size: widget.size * 0.5,
          ),
        ),
      ),
    );
  }
}