library aac_settings_store;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../design_system/aac/aac_theme.dart';

/// Parent-configurable card size (docs/aac_design_system.md §2-3: cards use
/// a dedicated 120-160px tier, not the generic child touch target).
enum AacCardSizeSetting { l, xl, xxl }

extension AacCardSizeSettingPixels on AacCardSizeSetting {
  double get pixels => switch (this) {
        AacCardSizeSetting.l => AacSizes.cardMin, // 120
        AacCardSizeSetting.xl => 140,
        AacCardSizeSetting.xxl => AacSizes.cardMax, // 160
      };
}

/// "My Voice" accessibility settings — all parent-configurable, per
/// docs/aac_design_system.md Phase 2's accessibility requirements list
/// (touch target size, dwell-time activation, high-contrast, reduced
/// motion). Stored via SharedPreferences (small, simple mutable state —
/// same rationale as `AacCustomCardStore`, see that file's doc comment for
/// why this isn't in the drift database).
class AacSettings {
  final AacCardSizeSetting cardSize;

  /// Alternate activation trigger for severe motor impairment: hold instead
  /// of tap. See docs/aac_design_system.md §4.
  final bool dwellEnabled;
  final Duration dwellDuration;

  /// Solid white card surface + thicker full-saturation border instead of
  /// the default soft tint — a further contrast boost on top of the
  /// AAA-by-default palette from docs/aac_design_system.md §1.
  final bool highContrast;

  /// Forces the static/reduced-motion presentation even when the OS-level
  /// "reduce motion" setting is off — combined with
  /// `MediaQuery.disableAnimations` at the widget layer via OR, not instead
  /// of it (see AacCard).
  final bool reducedMotion;

  const AacSettings({
    this.cardSize = AacCardSizeSetting.l,
    this.dwellEnabled = false,
    this.dwellDuration = AacSizes.dwellDefault,
    this.highContrast = false,
    this.reducedMotion = false,
  });

  AacSettings copyWith({
    AacCardSizeSetting? cardSize,
    bool? dwellEnabled,
    Duration? dwellDuration,
    bool? highContrast,
    bool? reducedMotion,
  }) {
    return AacSettings(
      cardSize: cardSize ?? this.cardSize,
      dwellEnabled: dwellEnabled ?? this.dwellEnabled,
      dwellDuration: dwellDuration ?? this.dwellDuration,
      highContrast: highContrast ?? this.highContrast,
      reducedMotion: reducedMotion ?? this.reducedMotion,
    );
  }

  factory AacSettings.fromJson(Map<String, dynamic> json) => AacSettings(
        cardSize: AacCardSizeSetting.values.byName(json['card_size'] as String? ?? 'l'),
        dwellEnabled: json['dwell_enabled'] as bool? ?? false,
        dwellDuration: Duration(milliseconds: json['dwell_ms'] as int? ?? AacSizes.dwellDefault.inMilliseconds),
        highContrast: json['high_contrast'] as bool? ?? false,
        reducedMotion: json['reduced_motion'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'card_size': cardSize.name,
        'dwell_enabled': dwellEnabled,
        'dwell_ms': dwellDuration.inMilliseconds,
        'high_contrast': highContrast,
        'reduced_motion': reducedMotion,
      };
}

class AacSettingsStore {
  AacSettingsStore._();
  static final AacSettingsStore instance = AacSettingsStore._();

  static const _key = 'aac_settings_v1';

  AacSettings? _cache;

  Future<AacSettings> get() async {
    final cached = _cache;
    if (cached != null) return cached;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      _cache = const AacSettings();
      return _cache!;
    }
    _cache = AacSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    return _cache!;
  }

  Future<void> update(AacSettings settings) async {
    _cache = settings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
  }

  /// See `AacCustomCardStore.resetCacheForTesting` — same rationale.
  void resetCacheForTesting() => _cache = null;
}
