import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flexikeys/design_system/design_system.dart';

void main() {
  group('AacTheme', () {
    const theme = AacTheme();

    test('registered as a ThemeExtension in FlexiKeysTheme.light()', () {
      final data = FlexiKeysTheme.light();
      expect(data.extension<AacTheme>(), isNotNull);
    });

    test('of(context) falls back to the const default when unregistered', () {
      // Matches FkPlayTheme's own fallback contract.
      expect(theme.dailyActivities, FkColors.skyBlue);
    });

    test('every AacCategory maps to exactly one FkColors.playful entry', () {
      final mapped = AacCategory.values.map(theme.colorFor).toSet();
      expect(mapped.length, AacCategory.values.length,
          reason: 'no two categories should share a color');
      for (final c in mapped) {
        expect(FkColors.playful, contains(c));
      }
    });

    test('category → color matches the design doc mapping', () {
      expect(theme.colorFor(AacCategory.dailyActivities), FkColors.skyBlue);
      expect(theme.colorFor(AacCategory.needs), FkColors.leaf);
      expect(theme.colorFor(AacCategory.feelings), FkColors.sunshine);
      expect(theme.colorFor(AacCategory.people), FkColors.grape);
      expect(theme.colorFor(AacCategory.places), FkColors.tangerine);
      expect(theme.colorFor(AacCategory.play), FkColors.coral);
    });

    test('tintFor never returns the full-saturation accent (must be blended)', () {
      for (final category in AacCategory.values) {
        expect(theme.tintFor(category), isNot(theme.colorFor(category)));
      }
    });

    test('tintFor is deterministic for the same category', () {
      expect(theme.tintFor(AacCategory.play), theme.tintFor(AacCategory.play));
    });

    test('copyWith overrides only the given fields', () {
      final custom = theme.copyWith(play: Colors.black);
      expect(custom.play, Colors.black);
      expect(custom.needs, theme.needs);
    });

    test('lerp at t=0 returns starting colors, t=1 returns ending colors', () {
      const other = AacTheme(play: Colors.black);
      expect(theme.lerp(other, 0).play, theme.play);
      expect(theme.lerp(other, 1).play, Colors.black);
    });
  });

  group('AacSizes', () {
    test('card touch target range is well above the generic child target', () {
      expect(AacSizes.cardMin, greaterThan(FkTouchTargets.child));
      expect(AacSizes.cardMax, greaterThan(AacSizes.cardMin));
    });

    test('beginner grid gap is more generous than advanced (fewer, bigger cards)', () {
      expect(AacSizes.gridGapBeginner, greaterThan(AacSizes.gridGapAdvanced));
    });

    test('dwell default sits within the adjustable min/max range', () {
      expect(AacSizes.dwellDefault, greaterThanOrEqualTo(AacSizes.dwellMin));
      expect(AacSizes.dwellDefault, lessThanOrEqualTo(AacSizes.dwellMax));
    });
  });
}
