import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flexikeys/design_system/components/keyboard/fk_keyboard_metrics.dart';
import 'package:flexikeys/features/adaptive/adaptive_profile.dart';
import 'package:flexikeys/features/keyboard/keyboard_layouts.dart';

/// Regression test for the Phase 1 keyboard-metrics extraction. Every
/// expected value below was hand-derived from the ORIGINAL formula that
/// used to live inline in `FkKeyboard`/`_KeyWidget`
/// (`baseW = 36.0 * keyScale`, `keyH = baseH * perKeyScale`,
/// `effectiveH = keyScale >= 1.0 ? keyH.clamp(64, inf) : keyH`,
/// `fontSize = (18 * keyScale).clamp(14, 28)`) — independently of
/// `FkKeyboardMetrics`, so a transcription mistake during extraction would
/// show up as a test failure here, not just "looks right on inspection".
///
/// Profile values (keyScale up to 1.40, keySpacing up to 1.60, per-key
/// scale up to 1.50) are drawn from the real bounds in
/// shared/adaptive_policy.json, not arbitrary numbers.

// Binary floating-point can't represent values like 46.8 exactly, so
/// direct `Size` equality intermittently fails on the last bit even when
/// the math is correct (e.g. `46.8` vs `46.800000000000004`) — compare
/// each dimension with a tight tolerance instead.
void _expectSize(Size actual, double width, double height) {
  expect(actual.width, closeTo(width, 1e-9));
  expect(actual.height, closeTo(height, 1e-9));
}

void main() {
  const normalKey = KeyDef('a'); // widthFactor 1.0
  const wideKey = KeyDef("o'", widthFactor: 1.3); // real layout value
  const backspaceKey = KeyDef('⌫', widthFactor: 1.4); // real layout value

  group('FkKeyboardMetrics.keySize — byte-for-byte match with the pre-extraction formula', () {
    test('default profile, normal key', () {
      const profile = AdaptationProfile(); // keyScale 1.0, keySpacing 1.0
      final size = FkKeyboardMetrics.keySize(
          profile: profile, keyDef: normalKey, isBackspace: false);
      _expectSize(size, 36.0, 64.0);
    });

    test('global-max keyScale (1.40), normal key', () {
      const profile = AdaptationProfile(keyScale: 1.40);
      final size = FkKeyboardMetrics.keySize(
          profile: profile, keyDef: normalKey, isBackspace: false);
      _expectSize(size, 50.4, 67.2);
    });

    test('default keyScale, max keySpacing (1.60) — spacing does not affect key size', () {
      const profile = AdaptationProfile(keySpacing: 1.60);
      final size = FkKeyboardMetrics.keySize(
          profile: profile, keyDef: normalKey, isBackspace: false);
      _expectSize(size, 36.0, 64.0);
    });

    test('max keyScale + max keySpacing together', () {
      const profile = AdaptationProfile(keyScale: 1.40, keySpacing: 1.60);
      final size = FkKeyboardMetrics.keySize(
          profile: profile, keyDef: normalKey, isBackspace: false);
      _expectSize(size, 50.4, 67.2);
    });

    test('default profile, wide key (widthFactor 1.3)', () {
      const profile = AdaptationProfile();
      final size = FkKeyboardMetrics.keySize(
          profile: profile, keyDef: wideKey, isBackspace: false);
      _expectSize(size, 46.8, 64.0);
    });

    test('max keyScale, wide key', () {
      const profile = AdaptationProfile(keyScale: 1.40);
      final size = FkKeyboardMetrics.keySize(
          profile: profile, keyDef: wideKey, isBackspace: false);
      _expectSize(size, 65.52, 67.2);
    });

    test('backspace key ignores a per-key scale override', () {
      const profile = AdaptationProfile(
        keyScale: 1.0,
        keyScalePerKey: {'⌫': 1.5}, // must be ignored — isBackspace forces 1.0
      );
      final size = FkKeyboardMetrics.keySize(
          profile: profile, keyDef: backspaceKey, isBackspace: true);
      _expectSize(size, 50.4, 64.0);
    });

    test('backspace key at max keyScale', () {
      const profile = AdaptationProfile(keyScale: 1.40);
      final size = FkKeyboardMetrics.keySize(
          profile: profile, keyDef: backspaceKey, isBackspace: true);
      _expectSize(size, 70.56, 67.2);
    });

    test('per-key scale override at max (1.50)', () {
      const profile = AdaptationProfile(
        keyScalePerKey: {'a': 1.50},
      );
      final size = FkKeyboardMetrics.keySize(
          profile: profile, keyDef: normalKey, isBackspace: false);
      _expectSize(size, 54.0, 72.0);
    });

    test('keyScale below 1.0 (outside today\'s documented policy range) leaves height unclamped', () {
      // key_scale_min in shared/adaptive_policy.json is 1.00, so this
      // branch is dead in production today — kept because the original
      // code has it, and a byte-for-byte extraction must preserve
      // unreachable branches exactly, not prune them.
      const profile = AdaptationProfile(keyScale: 0.8);
      final size = FkKeyboardMetrics.keySize(
          profile: profile, keyDef: normalKey, isBackspace: false);
      _expectSize(size, 28.8, 38.4);
    });
  });

  group('FkKeyboardMetrics — padding and font size', () {
    test('outerPadding / innerSpacing scale with keySpacing only', () {
      const profile = AdaptationProfile(keySpacing: 1.60);
      expect(FkKeyboardMetrics.outerPadding(profile), closeTo(12.8, 1e-9));
      expect(FkKeyboardMetrics.innerSpacing(profile), closeTo(6.4, 1e-9));
    });

    test('keyFontSize scales with keyScale only, ignoring per-key overrides', () {
      const profile = AdaptationProfile(
        keyScale: 1.40,
        keyScalePerKey: {'a': 1.50}, // must NOT affect font size
      );
      expect(FkKeyboardMetrics.keyFontSize(profile), closeTo(25.2, 1e-9));
    });

    test('keyFontSize is clamped to [14, 28]', () {
      expect(
        FkKeyboardMetrics.keyFontSize(const AdaptationProfile(keyScale: 0.5)),
        14.0,
      );
      expect(
        FkKeyboardMetrics.keyFontSize(const AdaptationProfile(keyScale: 2.0)),
        28.0,
      );
    });
  });

  group('Touch-target audit (reporting only — see Phase 1 report, not fixed here)', () {
    // CLAUDE.md: "Child touch targets ≥ 64×64dp." The height dimension is
    // correctly floored to 64dp once keyScale >= 1.0 (see keySize above),
    // but WIDTH is never clamped anywhere in the original formula. At the
    // *default*, unadapted profile — what most children see before any
    // server-side adaptation has fired — a normal key is only 36dp wide,
    // under both the app's own 64dp child standard AND the generic 48dp
    // minimum. This test documents the gap; it does not assert it as
    // correct, and this refactor does not change it.
    test('default profile: normal-key width is 36dp — below the 48dp minimum', () {
      const profile = AdaptationProfile();
      final size = FkKeyboardMetrics.keySize(
          profile: profile, keyDef: normalKey, isBackspace: false);
      expect(size.width, 36.0); // KNOWN GAP — width is never clamped
      expect(size.height, greaterThanOrEqualTo(48.0)); // height is fine
    });

    test('default profile: wide key (1.3x) is still under 48dp', () {
      const profile = AdaptationProfile();
      final size = FkKeyboardMetrics.keySize(
          profile: profile, keyDef: wideKey, isBackspace: false);
      expect(size.width, closeTo(46.8, 1e-9)); // KNOWN GAP — 46.8 < 48
    });
  });
}
