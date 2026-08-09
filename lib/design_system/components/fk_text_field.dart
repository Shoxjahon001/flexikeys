library fk_text_field;

import 'package:flutter/material.dart';

import '../tokens/app_color_theme.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';

/// Standard text input: muted fill, no harsh borders, 2px primary ring on
/// focus, error state with [errorText].
class FkTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? errorText;
  final bool enabled;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;

  const FkTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.errorText,
    this.enabled = true,
    this.maxLines = 1,
    this.onChanged,
    this.textInputAction,
  });

  @override
  State<FkTextField> createState() => _FkTextFieldState();
}

class _FkTextFieldState extends State<FkTextField> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _focused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          Text(widget.labelText!, style: textTheme.labelLarge?.copyWith(color: colors.textSecondary)),
          const SizedBox(height: AppSpacing.xs),
        ],
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceMuted,
            borderRadius: AppRadius.smAll,
            border: Border.all(
              color: hasError
                  ? colors.danger
                  : _focused
                      ? colors.primary
                      : Colors.transparent,
              width: _focused || hasError ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            maxLines: widget.maxLines,
            onChanged: widget.onChanged,
            textInputAction: widget.textInputAction,
            style: textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: textTheme.bodyMedium?.copyWith(color: colors.textTertiary),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(widget.errorText!, style: textTheme.bodySmall?.copyWith(color: colors.danger)),
        ],
      ],
    );
  }
}
