library fk_parent_gate;

import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'fk_button.dart';
import 'fk_card.dart';

/// Simple cognitive gate that keeps children from accidentally navigating
/// into parent/settings areas. Shows a simple math challenge; not PIN-based
/// (per COPPA: no PII stored). Parent opens gate by answering correctly.
class FkParentGate extends StatefulWidget {
  final VoidCallback onUnlocked;
  final Widget child;

  const FkParentGate({
    super.key,
    required this.onUnlocked,
    required this.child,
  });

  @override
  State<FkParentGate> createState() => _FkParentGateState();
}

class _FkParentGateState extends State<FkParentGate> {
  bool _locked = true;
  int _a = 0;
  int _b = 0;
  String _answer = '';
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    final rng = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      _a = (rng % 9) + 2;
      _b = (rng ~/ 10 % 9) + 2;
      _answer = '';
      _error = false;
    });
  }

  void _verify(String input) {
    if (int.tryParse(input) == _a * _b) {
      setState(() => _locked = false);
      widget.onUnlocked();
    } else {
      setState(() => _error = true);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_locked) return widget.child;
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: FkCard(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.parentAreaTitle,
                  style: AppTypography.h2,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  t.parentGateInstruction,
                  style: AppTypography.body,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  '$_a × $_b = ?',
                  style: AppTypography.h1,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (_error)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      t.parentGateWrongAnswer,
                      // This is the adult parent-gate screen, not
                      // child-facing failure framing — CLAUDE.md's "never
                      // red for children" rule doesn't apply here, so a
                      // real error color (danger) is more correct than
                      // reusing the gentle child-facing "warning" tone.
                      style: AppTypography.caption
                          .copyWith(color: AppColors.danger),
                    ),
                  ),
                TextField(
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: t.yourAnswerHint,
                    filled: true,
                    fillColor: AppColors.surfaceMuted,
                    border: const OutlineInputBorder(
                      borderRadius: AppRadius.mdAll,
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: _verify,
                  onChanged: (v) => setState(() {
                    _answer = v;
                    _error = false;
                  }),
                ),
                const SizedBox(height: AppSpacing.lg),
                FkButton(
                  label: t.continueButton,
                  size: FkButtonSize.adult,
                  onPressed: _answer.isNotEmpty ? () => _verify(_answer) : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
