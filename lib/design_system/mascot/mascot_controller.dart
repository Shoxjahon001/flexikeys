library mascot_controller;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../fk_tokens.dart';
import 'mascot_renderer.dart';

/// Queued mascot utterance — links a localisation key to a display duration.
class MascotUtterance {
  final String l10nKey;
  final Duration displayFor;
  const MascotUtterance(this.l10nKey, {this.displayFor = const Duration(seconds: 3)});
}

/// Mascot state — immutable value held by the Riverpod notifier.
class MascotState {
  final FkExpression expression;
  final MascotUtterance? currentUtterance;

  const MascotState({
    this.expression = FkExpression.happy,
    this.currentUtterance,
  });

  MascotState copyWith({
    FkExpression? expression,
    MascotUtterance? currentUtterance,
    bool clearUtterance = false,
  }) {
    return MascotState(
      expression: expression ?? this.expression,
      currentUtterance: clearUtterance ? null : (currentUtterance ?? this.currentUtterance),
    );
  }
}

/// Riverpod StateNotifier that drives the mascot state machine.
///
/// Features reacts to lesson events via this notifier — never hardcoded in
/// screens. Copy comes only from the curated l10n catalog (ARB files).
class MascotController extends StateNotifier<MascotState> {
  final List<MascotUtterance> _queue = [];
  bool _draining = false;

  MascotController() : super(const MascotState());

  /// Set mascot expression immediately.
  void setExpression(FkExpression expr) {
    state = state.copyWith(expression: expr);
  }

  /// Enqueue a speech bubble utterance identified by [l10nKey].
  /// The key must exist in the ARB catalog — never free-form text for child UI.
  void say(String l10nKey, {Duration displayFor = const Duration(seconds: 3)}) {
    _queue.add(MascotUtterance(l10nKey, displayFor: displayFor));
    _drainQueue();
  }

  Future<void> _drainQueue() async {
    if (_draining || _queue.isEmpty) return;
    _draining = true;
    while (_queue.isNotEmpty) {
      final utterance = _queue.removeAt(0);
      state = state.copyWith(currentUtterance: utterance);
      await Future.delayed(utterance.displayFor);
    }
    state = state.copyWith(clearUtterance: true);
    _draining = false;
  }

  /// React to a lesson event — sets appropriate expression + queued line.
  void onLessonEvent(LessonEvent event) {
    switch (event) {
      case LessonEvent.itemCorrect:
        setExpression(FkExpression.encouraging);
        say('mascotEffortPraise');
      case LessonEvent.itemStruggling:
        setExpression(FkExpression.encouraging);
        say('mascotKeepTrying');
      case LessonEvent.levelComplete:
        setExpression(FkExpression.celebrating);
        say('mascotCelebrating');
      case LessonEvent.fatigueDetected:
        setExpression(FkExpression.thinking);
        say('breakSuggestion');
      case LessonEvent.sessionStart:
        setExpression(FkExpression.happy);
        say('mascotGreeting');
      case LessonEvent.sessionEnd:
        setExpression(FkExpression.waving);
        say('mascotWaving');
    }
  }
}

/// Domain events the mascot reacts to.
enum LessonEvent {
  itemCorrect,
  itemStruggling,
  levelComplete,
  fatigueDetected,
  sessionStart,
  sessionEnd,
}

/// Riverpod provider — access via `ref.read(mascotControllerProvider.notifier)`.
final mascotControllerProvider =
    StateNotifierProvider<MascotController, MascotState>(
  (_) => MascotController(),
);

/// Widget that renders the mascot + speech bubble from provider state.
class MascotWidget extends ConsumerWidget {
  final double size;

  const MascotWidget({super.key, this.size = 160});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mascotControllerProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MascotRenderer(expression: state.expression, size: size),
        if (state.currentUtterance != null)
          _SpeechBubble(l10nKey: state.currentUtterance!.l10nKey),
      ],
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  final String l10nKey;
  const _SpeechBubble({required this.l10nKey});

  @override
  Widget build(BuildContext context) {
    // l10nKey is resolved by callers — here we display the resolved text
    // passed through the widget tree via the l10n lookup. In practice callers
    // call `say()` with a key and the resolved string is fetched from AppLocalizations.
    // For now we render the key as a debug label.
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: FkColors.cloud,
          borderRadius: FkRadii.mdAll,
          boxShadow: FkElevation.low(FkColors.ink),
        ),
        child: Text(
          l10nKey,
          style: FkTextStyles.childBody,
        ),
      ),
    );
  }
}