library lesson_player_screen;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../../../features/adaptive/adaptive_profile.dart';
import '../../../features/keyboard/fk_keyboard.dart';
import '../../../features/keyboard/keyboard_layouts.dart';
import '../application/lesson_controller.dart';
import '../domain/lesson_state.dart';
import 'widgets/break_overlay.dart';
import 'widgets/ghost_text_display.dart';

/// LessonPlayerScreen drives a full typing lesson.
///
/// Callers pass [items] and [reviewItems] from the NextLessonPlan.
/// [language] selects the keyboard layout and curriculum language.
/// [profile]  is the current AdaptationProfile for this child.
class LessonPlayerScreen extends ConsumerStatefulWidget {
  final List<dynamic> items; // List<CurriculumItem>
  final List<dynamic> reviewItems;
  final String language;
  final AdaptationProfile profile;
  final void Function(LessonState completed)? onLessonComplete;

  const LessonPlayerScreen({
    super.key,
    required this.items,
    required this.reviewItems,
    required this.language,
    required this.profile,
    this.onLessonComplete,
  });

  @override
  ConsumerState<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends ConsumerState<LessonPlayerScreen>
    with WidgetsBindingObserver {
  Timer? _tickTimer;
  bool _burstVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startLesson());
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startLesson() {
    final controller = ref.read(lessonControllerProvider.notifier);
    controller.onItemCompleted = (_) {
      setState(() => _burstVisible = true);
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => _burstVisible = false);
      });
    };
    controller.onLessonComplete = (state) {
      widget.onLessonComplete?.call(state);
    };
    controller.loadPlan(
      items: List.from(widget.items),
      reviewItems: List.from(widget.reviewItems),
    );

    // Tick timer for session pacing
    _tickTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        ref.read(lessonControllerProvider.notifier).tick(
              DateTime.now().millisecondsSinceEpoch,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lessonState = ref.watch(lessonControllerProvider);
    final layout = keyboardLayoutFor(widget.language);

    if (lessonState.phase == LessonPhase.summary) {
      return _SummaryView(lessonState: lessonState);
    }

    return Scaffold(
      backgroundColor: FkColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _TopBar(lessonState: lessonState),
                Expanded(
                  child: _ItemView(
                    lessonState: lessonState,
                    language: widget.language,
                  ),
                ),
                _KeyboardSection(
                  lessonState: lessonState,
                  layout: layout,
                  profile: widget.profile,
                ),
              ],
            ),
          ),
          // Coin burst on item completion
          if (_burstVisible)
            const Align(
              alignment: Alignment.topCenter,
              child: FkStarBurst(active: true),
            ),
          // Break overlay
          if (lessonState.breakSuggested)
            Positioned.fill(
              child: BreakOverlay(
                onContinue: () =>
                    ref.read(lessonControllerProvider.notifier).dismissBreak(),
                onStop: () =>
                    ref.read(lessonControllerProvider.notifier).endSession(),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final LessonState lessonState;
  const _TopBar({required this.lessonState});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FkSpacing.md,
        vertical: FkSpacing.xs,
      ),
      child: Row(
        children: [
          // Progress indicator
          Expanded(
            child: LinearProgressIndicator(
              value: lessonState.items.isEmpty
                  ? 0
                  : lessonState.currentIndex / lessonState.items.length,
              backgroundColor: FkColors.cloud,
              valueColor: const AlwaysStoppedAnimation(FkColors.mint),
              minHeight: 8,
              borderRadius: FkRadii.pillAll,
            ),
          ),
          const SizedBox(width: FkSpacing.sm),
          FkCoinCounter(value: lessonState.totalCoins),
        ],
      ),
    );
  }
}

class _ItemView extends ConsumerWidget {
  final LessonState lessonState;
  final String language;
  const _ItemView({required this.lessonState, required this.language});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = lessonState.currentItem;
    if (item == null) return const SizedBox.shrink();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Mascot
        const MascotWidget(size: 120),
        const SizedBox(height: FkSpacing.md),
        // Item image if available
        if (item.l10n.imageUrl != null)
          AnimatedOpacity(
            opacity: 1.0,
            duration: FkDurations.slow,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: FkColors.warmYellow.withValues(alpha: 0.3),
                borderRadius: FkRadii.lgAll,
              ),
              child: const Icon(
                Icons.image_rounded,
                size: 80,
                color: FkColors.inkSoft,
              ),
            ),
          ),
        const SizedBox(height: FkSpacing.md),
        // Ghost text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: FkSpacing.lg),
          child: GhostTextDisplay(
            target: item.l10n.text,
            typed: lessonState.typedSoFar,
          ),
        ),
        const SizedBox(height: FkSpacing.sm),
        // Subtle "take your time" hint after misses — never a red error
        if (lessonState.missCountCurrent >= 2)
          Text(
            'Take your time',
            style: FkTextStyles.childBody.copyWith(color: FkColors.inkSoft),
          ),
      ],
    );
  }
}

class _KeyboardSection extends ConsumerWidget {
  final LessonState lessonState;
  final KeyboardLayout layout;
  final AdaptationProfile profile;

  const _KeyboardSection({
    required this.lessonState,
    required this.layout,
    required this.profile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = lessonState.currentItem?.l10n.text ?? '';

    return FkKeyboard(
      layout: layout,
      profile: profile,
      targetKey: _nextExpectedChar(target, lessonState.typedSoFar),
      onKeystroke: (record) {
        ref
            .read(lessonControllerProvider.notifier)
            .onKeystroke(record, profile);
      },
    );
  }

  String _nextExpectedChar(String target, List<String> typed) {
    final pos = typed.fold(0, (acc, c) => acc + c.length);
    if (pos >= target.length) return '';
    final remaining = target.substring(pos);
    for (final dg in const ["o'", "g'", "sh", "ch", "ng", "O'", "G'"]) {
      if (remaining.startsWith(dg)) return dg;
    }
    return remaining[0];
  }
}

class _SummaryView extends StatelessWidget {
  final LessonState lessonState;
  const _SummaryView({required this.lessonState});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FkColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(FkSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const MascotWidget(size: 160),
                const SizedBox(height: FkSpacing.lg),
                const Text(
                  'Great effort today!',
                  style: FkTextStyles.childHeadline,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: FkSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < 3; i++)
                      Icon(
                        Icons.star_rounded,
                        size: 40,
                        color: i < lessonState.starsEarned
                            ? FkColors.warmYellow
                            : FkColors.disabled,
                      ),
                  ],
                ),
                const SizedBox(height: FkSpacing.sm),
                FkCoinCounter(value: lessonState.totalCoins), // const not possible: runtime value
                const SizedBox(height: FkSpacing.xl),
                FkButton(
                  label: 'Done',
                  onPressed: () => Navigator.of(context).pop(),
                  size: FkButtonSize.child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


/// Returns the keyboard layout for [language].
KeyboardLayout keyboardLayoutFor(String language) {
  switch (language) {
    case 'uz':
      return uzLayout;
    case 'ru':
      return ruLayout;
    default:
      return enLayout;
  }
}