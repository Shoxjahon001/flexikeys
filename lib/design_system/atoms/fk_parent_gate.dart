library fk_parent_gate;

import 'package:flutter/material.dart';
import '../fk_tokens.dart';
import '../fk_theme.dart';
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
    final fk = FkTheme.of(context);

    return Scaffold(
      backgroundColor: fk.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(FkSpacing.lg),
          child: FkCard(
            padding: const EdgeInsets.all(FkSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Parent Area',
                  style: FkTextStyles.adultHeadline.copyWith(color: fk.ink),
                ),
                const SizedBox(height: FkSpacing.sm),
                const Text(
                  'Solve to continue:',
                  style: FkTextStyles.adultBody,
                ),
                const SizedBox(height: FkSpacing.sm),
                Text(
                  '$_a × $_b = ?',
                  style: FkTextStyles.childLabel.copyWith(color: fk.ink),
                ),
                const SizedBox(height: FkSpacing.sm),
                if (_error)
                  Padding(
                    padding: const EdgeInsets.only(bottom: FkSpacing.xs),
                    child: Text(
                      'Try again',
                      style: FkTextStyles.adultCaption
                          .copyWith(color: fk.attention),
                    ),
                  ),
                TextField(
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'Your answer',
                    filled: true,
                    fillColor: fk.surface,
                    border: const OutlineInputBorder(
                      borderRadius: FkRadii.mdAll,
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: _verify,
                  onChanged: (v) => setState(() {
                    _answer = v;
                    _error = false;
                  }),
                ),
                const SizedBox(height: FkSpacing.sm),
                FkButton(
                  label: 'Continue',
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