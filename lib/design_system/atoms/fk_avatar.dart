library fk_avatar;

import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_shadows.dart';
import '../tokens/app_typography.dart';

/// Child avatar — shows initials or an image asset inside a soft circle.
class FkAvatar extends StatelessWidget {
  final String name;
  final String? imageAsset;
  final double size;
  final Color? backgroundColor;

  const FkAvatar({
    super.key,
    required this.name,
    this.imageAsset,
    this.size = 56,
    this.backgroundColor,
  });

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: AppShadows.soft,
      ),
      child: ClipOval(
        child: imageAsset != null
            ? Image.asset(imageAsset!, fit: BoxFit.cover)
            : Center(
                child: Text(
                  _initials,
                  style: AppTypography.h3.copyWith(
                    fontSize: size * 0.35,
                    // The default background is the vivid AppColors.primary
                    // purple — white initials for contrast, unlike the pale
                    // lavender this replaces which used dark ink text.
                    color: backgroundColor == null
                        ? Colors.white
                        : AppColors.textPrimary,
                  ),
                ),
              ),
      ),
    );
  }
}