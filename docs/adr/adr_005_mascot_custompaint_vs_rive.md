# ADR-005 — Mascot: CustomPainter vs Rive

**Status:** Accepted  
**Date:** 2026-07-13

## Context

Phase 06 requires a mascot with 7 distinct expressions plus a continuous idle float animation. The CLAUDE.md tech stack lists Rive (`rive` package) as the target implementation. Rive provides a visual state machine that an animator can author, producing a `.riv` binary file.

In the current development environment there is no Rive animator tooling available, no `.riv` file has been authored, and adding the Rive runtime package (which ships its own renderer) would block progress and add a cold-start dependency before the visual style is finalised.

## Decision

Implement `MascotRenderer` as a `CustomPainter` cloud character with the same **public API** as the planned Rive adapter:

```dart
class MascotRenderer extends StatefulWidget {
  final FkExpression expression;
  final double size;
  ...
}
```

`FkExpression` is the shared enum used by both the CustomPainter implementation and the future Rive adapter. All callers (screens, `MascotController`) reference only this interface.

A `MascotController` (Riverpod `StateNotifier`) drives expression changes and a queued speech-bubble system. Expressions react to domain events (`LessonEvent`) — the controller is never hardcoded in individual screens.

## Why This Works

- The `MascotRenderer` widget signature is identical to what a Rive-backed widget would expose.
- Swapping to Rive requires only rewriting `mascot_renderer.dart`; `mascot_controller.dart`, all screens, and all tests are unaffected.
- The CustomPainter cloud character satisfies the visual soft/rounded style spec (pastel blob, expressive eyes, blush marks) without any external assets.

## Swap Path (When Rive Asset Is Ready)

1. Animator exports `mascot.riv` to `assets/rive/`.
2. Add `rive: ^0.13` to `pubspec.yaml`.
3. Replace `MascotRenderer`'s `CustomPainter` internals with a `RiveAnimation.asset` widget plus a Rive `StateMachineController` that maps `FkExpression` → Rive inputs.
4. All callers compile unchanged.

## Consequences

- **Good:** Unblocks Phase 06 without waiting for visual-design asset authoring.
- **Good:** Pure Dart, no native code, smaller binary for now.
- **Good:** Full testability without Rive runtime setup in CI.
- **Accepted tradeoff:** Characters drawn in code are simpler than what a skilled Rive animator would produce. Visual polish deferred to asset-ready phase.
- **Accepted tradeoff:** Idle float is linear (ease-in-out sinusoid). Rive would enable more complex idle physics.