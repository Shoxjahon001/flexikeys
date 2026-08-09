library fk_audio_button;

import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_shadows.dart';

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
      duration: AppMotion.base,
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulse, curve: AppMotion.transition),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);

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
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: AppShadows.soft,
          ),
          // AppColors.primary is a vivid purple — white icon for contrast,
          // unlike the pale lavender this replaces which used dark ink.
          child: Icon(
            widget.playing ? Icons.volume_up_rounded : Icons.play_arrow_rounded,
            color: Colors.white,
            size: widget.size * 0.5,
          ),
        ),
      ),
    );
  }
}