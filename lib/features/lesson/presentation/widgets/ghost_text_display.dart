library ghost_text_display;

import 'package:flutter/material.dart';
import '../../../../design_system/fk_tokens.dart';

/// Shows the target word as large ghost letters with correctly-typed
/// characters filled in (soft pop animation on each fill).
///
/// [target]   — full word/phrase to type
/// [typed]    — characters typed so far (same tokenisation as LessonController)
class GhostTextDisplay extends StatelessWidget {
  final String target;
  final List<String> typed;

  const GhostTextDisplay({
    super.key,
    required this.target,
    required this.typed,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = _tokenise(target);
    int filledCount = typed.length;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      children: [
        for (int i = 0; i < tokens.length; i++)
          _LetterSlot(
            letter: tokens[i],
            filled: i < filledCount,
          ),
      ],
    );
  }

  /// Tokenise respecting Uzbek digraphs.
  static List<String> _tokenise(String text) {
    final tokens = <String>[];
    int pos = 0;
    while (pos < text.length) {
      bool matched = false;
      for (final dg in const ["o'", "g'", "sh", "ch", "ng", "O'", "G'"]) {
        if (text.substring(pos).startsWith(dg)) {
          tokens.add(dg);
          pos += dg.length;
          matched = true;
          break;
        }
      }
      if (!matched) {
        tokens.add(text[pos]);
        pos++;
      }
    }
    return tokens;
  }
}

class _LetterSlot extends StatefulWidget {
  final String letter;
  final bool filled;

  const _LetterSlot({required this.letter, required this.filled});

  @override
  State<_LetterSlot> createState() => _LetterSlotState();
}

class _LetterSlotState extends State<_LetterSlot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  bool _wasFilled = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: FkDurations.normal,
    );
    _scale = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _ctrl, curve: FkCurves.spring),
    );
    _wasFilled = widget.filled;
  }

  @override
  void didUpdateWidget(_LetterSlot old) {
    super.didUpdateWidget(old);
    if (!_wasFilled && widget.filled) {
      // Just became filled — pop animation
      _ctrl.forward().then((_) => _ctrl.reverse());
      _wasFilled = true;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.of(context).disableAnimations;
    final isFilled = widget.filled;

    return ScaleTransition(
      scale: reducedMotion ? const AlwaysStoppedAnimation(1.0) : _scale,
      child: Container(
        constraints: BoxConstraints(
          minWidth: widget.letter.length > 1 ? 56 : 40,
          minHeight: 60,
        ),
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isFilled ? FkColors.mint : FkColors.cloud,
          borderRadius: FkRadii.smAll,
          border: Border.all(
            color: isFilled
                ? FkColors.mint
                : FkColors.ink.withValues(alpha: 0.20),
            width: 2,
          ),
          boxShadow: isFilled ? FkElevation.low(FkColors.mint) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          isFilled ? widget.letter : '_',
          style: isFilled
              ? FkTextStyles.childHeadline.copyWith(color: FkColors.ink)
              : FkTextStyles.childHeadline.copyWith(
                  color: FkColors.ink.withValues(alpha: 0.25),
                ),
        ),
      ),
    );
  }
}