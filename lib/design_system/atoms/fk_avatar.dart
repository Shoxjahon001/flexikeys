library fk_avatar;

import 'package:flutter/material.dart';
import '../fk_tokens.dart';
import '../fk_theme.dart';

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
    final fk = FkTheme.of(context);
    final bg = backgroundColor ?? fk.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: FkElevation.low(fk.ink),
      ),
      child: ClipOval(
        child: imageAsset != null
            ? Image.asset(imageAsset!, fit: BoxFit.cover)
            : Center(
                child: Text(
                  _initials,
                  style: FkTextStyles.childLabel.copyWith(
                    fontSize: size * 0.35,
                    color: fk.ink,
                  ),
                ),
              ),
      ),
    );
  }
}