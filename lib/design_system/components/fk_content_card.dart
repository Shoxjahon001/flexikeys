library fk_content_card;

import 'package:flutter/material.dart';

import '../tokens/app_color_theme.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_shadows.dart';
import '../tokens/app_spacing.dart';
import 'fk_speak_button.dart';

/// White grid card: square image area, ≤2-line caption, corner
/// [FkSpeakButton]. The category-screen card in the reference mockup.
class FkContentCard extends StatelessWidget {
  final Widget image;
  final String caption;
  final VoidCallback? onTap;
  final VoidCallback? onSpeak;
  final bool speaking;

  const FkContentCard({
    super.key,
    required this.image,
    required this.caption,
    this.onTap,
    this.onSpeak,
    this.speaking = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: caption,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: AppRadius.mdAll,
            boxShadow: AppShadows.soft,
          ),
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: AppRadius.mdAll,
                      child: image,
                    ),
                  ),
                  if (onSpeak != null)
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: FkSpeakButton(onPressed: onSpeak, playing: speaking),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Text(
                  caption,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
