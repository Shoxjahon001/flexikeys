import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flexikeys/features/lesson/application/lesson_controller.dart';
import 'package:flexikeys/features/lesson/domain/lesson_state.dart';
import 'package:flexikeys/features/curriculum/curriculum_models.dart';
import 'package:flexikeys/features/adaptive/adaptive_profile.dart';
import 'package:flexikeys/features/keyboard/fk_keyboard.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

CurriculumItem _item(String text, {String id = 'item1', String skill = 'en:letter:a'}) {
  return CurriculumItem(
    id: id,
    type: 'letter',
    skillKey: skill,
    l10n: CurriculumItemL10n(
      text: text,
      audioUrl: 'https://example.com/audio.mp3',
    ),
  );
}

KeystrokeRecord _keystroke({
  required String targetKey,
  required String actualKey,
  bool rejectedByDwell = false,
  bool rejectedByDebounce = false,
}) {
  return KeystrokeRecord(
    targetKey: targetKey,
    actualKey: actualKey,
    correct: targetKey == actualKey,
    latencyMs: 200,
    timeToFirstTouchMs: 300,
    offsetRatio: 0.0,
    touchOffset: const Offset(0, 0),
    rejectedByDwell: rejectedByDwell,
    rejectedByDebounce: rejectedByDebounce,
    accidentalTap: rejectedByDwell,
  );
}

LessonController _makeController() {
  final container = ProviderContainer();
  return container.read(lessonControllerProvider.notifier);
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('LessonController — state machine phases', () {
    test('loadPlan moves to awaitInput with correct items', () async {
      final ctrl = _makeController();
      final items = [_item('cat')];

      ctrl.loadPlan(items: items, reviewItems: []);
      await Future.microtask(() {});

      expect(ctrl.state.phase, LessonPhase.awaitInput);
      expect(ctrl.state.items.length, 1);
      expect(ctrl.state.currentIndex, 0);
      expect(ctrl.state.typedSoFar, isEmpty);
    });

    test('correct keystroke advances typedSoFar', () async {
      final ctrl = _makeController();
      ctrl.loadPlan(items: [_item('ab')], reviewItems: []);
      await Future.microtask(() {});

      ctrl.onKeystroke(
        _keystroke(targetKey: 'a', actualKey: 'a'),
        AdaptationProfile.defaults,
      );
      await Future.microtask(() {});

      expect(ctrl.state.typedSoFar, ['a']);
    });

    test('completing all chars moves to celebrate then presentItem', () async {
      final ctrl = _makeController();
      ctrl.loadPlan(
        items: [_item('a'), _item('b', id: 'item2', skill: 'en:letter:b')],
        reviewItems: [],
      );
      await Future.microtask(() {});

      // Type 'a' to complete item 1
      ctrl.onKeystroke(
        _keystroke(targetKey: 'a', actualKey: 'a'),
        AdaptationProfile.defaults,
      );
      await Future.microtask(() {});

      // Phase should be celebrate or presentItem (microtask advances it)
      expect(
        [LessonPhase.celebrate, LessonPhase.presentItem, LessonPhase.awaitInput]
            .contains(ctrl.state.phase),
        isTrue,
      );
    });

    test('final item completion transitions to summary', () async {
      final ctrl = _makeController();
      ctrl.loadPlan(items: [_item('a')], reviewItems: []);
      await Future.microtask(() {});

      ctrl.onKeystroke(
        _keystroke(targetKey: 'a', actualKey: 'a'),
        AdaptationProfile.defaults,
      );
      await Future.microtask(() {});

      expect(ctrl.state.phase, LessonPhase.summary);
    });

    test('coins accumulate at flat rate per item', () async {
      final ctrl = _makeController();
      ctrl.loadPlan(items: [_item('a'), _item('b', id: 'i2')], reviewItems: []);
      await Future.microtask(() {});

      // Complete item 1
      ctrl.onKeystroke(_keystroke(targetKey: 'a', actualKey: 'a'), AdaptationProfile.defaults);
      await Future.microtask(() {});
      await Future.delayed(const Duration(milliseconds: 650));

      // Complete item 2
      ctrl.onKeystroke(_keystroke(targetKey: 'b', actualKey: 'b'), AdaptationProfile.defaults);
      await Future.microtask(() {});

      // 10 coins each = 20 total (effort-based, not accuracy-scaled)
      expect(ctrl.state.totalCoins, 20);
    });
  });

  group('LessonController — no-failure rules', () {
    test('wrong key increments miss count but does NOT show error', () async {
      final ctrl = _makeController();
      ctrl.loadPlan(items: [_item('cat')], reviewItems: []);
      await Future.microtask(() {});

      ctrl.onKeystroke(
        _keystroke(targetKey: 'c', actualKey: 'x'),
        AdaptationProfile.defaults,
      );
      await Future.microtask(() {});

      // typedSoFar unchanged — nothing was filled
      expect(ctrl.state.typedSoFar, isEmpty);
      expect(ctrl.state.missCountCurrent, 1);
      // Phase returns to awaitInput (feedback then back)
      expect(ctrl.state.phase, LessonPhase.awaitInput);
    });

    test('wrong key never fills in the wrong character', () async {
      final ctrl = _makeController();
      ctrl.loadPlan(items: [_item('at')], reviewItems: []);
      await Future.microtask(() {});

      ctrl.onKeystroke(
        _keystroke(targetKey: 'a', actualKey: 'z'),
        AdaptationProfile.defaults,
      );
      await Future.microtask(() {});

      expect(ctrl.state.typedSoFar, isEmpty);
    });

    test('after 3 misses item auto-fills (assisted completion)', () async {
      final ctrl = _makeController();
      ItemAttempt? completedAttempt;
      ctrl.onItemCompleted = (a) => completedAttempt = a;

      ctrl.loadPlan(items: [_item('cat')], reviewItems: []);
      await Future.microtask(() {});

      // 3 wrong keystrokes
      for (int i = 0; i < 3; i++) {
        ctrl.onKeystroke(
          _keystroke(targetKey: 'c', actualKey: 'x'),
          AdaptationProfile.defaults,
        );
        await Future.microtask(() {});
      }

      // Item should have completed as assisted
      expect(completedAttempt, isNotNull);
      expect(completedAttempt!.assisted, isTrue);
      expect(completedAttempt!.missCount, 3);
    });

    test('assisted item still earns coins (effort-based, not accuracy)', () async {
      final ctrl = _makeController();
      ctrl.loadPlan(items: [_item('a')], reviewItems: []);
      await Future.microtask(() {});

      // 3 wrong key → assisted auto-fill
      for (int i = 0; i < 3; i++) {
        ctrl.onKeystroke(
          _keystroke(targetKey: 'a', actualKey: 'x'),
          AdaptationProfile.defaults,
        );
        await Future.microtask(() {});
      }

      // Coins still earned
      expect(ctrl.state.totalCoins, 10);
    });

    test('rejected-by-dwell keystroke is ignored (no miss, no fill)', () async {
      final ctrl = _makeController();
      ctrl.loadPlan(items: [_item('ab')], reviewItems: []);
      await Future.microtask(() {});

      ctrl.onKeystroke(
        _keystroke(
          targetKey: 'a',
          actualKey: 'a',
          rejectedByDwell: true,
        ),
        AdaptationProfile.defaults,
      );
      await Future.microtask(() {});

      expect(ctrl.state.typedSoFar, isEmpty);
      expect(ctrl.state.missCountCurrent, 0);
    });

    test('rejected-by-debounce keystroke is ignored', () async {
      final ctrl = _makeController();
      ctrl.loadPlan(items: [_item('ab')], reviewItems: []);
      await Future.microtask(() {});

      ctrl.onKeystroke(
        _keystroke(
          targetKey: 'a',
          actualKey: 'a',
          rejectedByDebounce: true,
        ),
        AdaptationProfile.defaults,
      );
      await Future.microtask(() {});

      expect(ctrl.state.typedSoFar, isEmpty);
    });
  });

  group('LessonController — multi-char Uzbek', () {
    test("o' digraph treated as single token", () async {
      final ctrl = _makeController();
      ctrl.loadPlan(
        items: [_item("o'l", skill: "uz:word:o'l")],
        reviewItems: [],
      );
      await Future.microtask(() {});

      // Type "o'" as single token
      ctrl.onKeystroke(
        _keystroke(targetKey: "o'", actualKey: "o'"),
        AdaptationProfile.defaults,
      );
      await Future.microtask(() {});

      expect(ctrl.state.typedSoFar, ["o'"]);
    });
  });

  group('LessonController — session pacing', () {
    test('break not suggested before threshold', () {
      final ctrl = _makeController();
      ctrl.loadPlan(items: [_item('a')], reviewItems: []);
      ctrl.tick(DateTime.now().millisecondsSinceEpoch + 60 * 1000); // 1 min

      expect(ctrl.state.breakSuggested, isFalse);
    });

    test('break suggested after 7 minutes', () {
      final ctrl = _makeController();
      ctrl.loadPlan(items: [_item('a')], reviewItems: []);
      // Tick to 8 minutes
      ctrl.tick(ctrl.state.sessionStartMs + 8 * 60 * 1000);

      expect(ctrl.state.breakSuggested, isTrue);
    });

    test('dismissBreak clears suggestion', () {
      final ctrl = _makeController();
      ctrl.loadPlan(items: [_item('a')], reviewItems: []);
      ctrl.tick(ctrl.state.sessionStartMs + 8 * 60 * 1000);
      expect(ctrl.state.breakSuggested, isTrue);

      ctrl.dismissBreak();
      expect(ctrl.state.breakSuggested, isFalse);
      expect(ctrl.state.breakDismissed, isTrue);
    });

    test('break not re-suggested after dismiss', () {
      final ctrl = _makeController();
      ctrl.loadPlan(items: [_item('a')], reviewItems: []);
      ctrl.tick(ctrl.state.sessionStartMs + 8 * 60 * 1000);
      ctrl.dismissBreak();

      // Tick again
      ctrl.tick(ctrl.state.sessionStartMs + 9 * 60 * 1000);
      expect(ctrl.state.breakSuggested, isFalse);
    });
  });

  group('LessonController — stars computation', () {
    test('all correct first-try earns 3 stars', () async {
      final ctrl = _makeController();
      ctrl.loadPlan(items: [_item('a')], reviewItems: []);
      await Future.microtask(() {});

      ctrl.onKeystroke(
        _keystroke(targetKey: 'a', actualKey: 'a'),
        AdaptationProfile.defaults,
      );
      await Future.microtask(() {});

      expect(ctrl.state.starsEarned, 3);
    });

    test('assisted item earns 1 star', () async {
      final ctrl = _makeController();
      ctrl.loadPlan(items: [_item('a')], reviewItems: []);
      await Future.microtask(() {});

      // 3 misses → assisted
      for (int i = 0; i < 3; i++) {
        ctrl.onKeystroke(
          _keystroke(targetKey: 'a', actualKey: 'x'),
          AdaptationProfile.defaults,
        );
        await Future.microtask(() {});
      }

      expect(ctrl.state.starsEarned, 1);
    });
  });

  group('LessonController — review items', () {
    test('review items appended after new items', () async {
      final ctrl = _makeController();
      ctrl.loadPlan(
        items: [_item('a', id: 'new1')],
        reviewItems: [_item('b', id: 'rev1')],
      );
      await Future.microtask(() {});

      expect(ctrl.state.items.length, 2);
      expect(ctrl.state.items[0].id, 'new1');
      expect(ctrl.state.items[1].id, 'rev1');
    });
  });
}