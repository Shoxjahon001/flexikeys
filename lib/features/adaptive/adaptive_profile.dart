// Dart model mirroring the AdaptationProfile.params dict from the backend.
// Must stay in sync with shared/adaptive_policy.json.

class AdaptationProfile {
  final double keyScale;
  final Map<String, double> keyScalePerKey;
  final double keySpacing;
  final int dwellTimeMs;
  final int debounceMs;
  final Map<String, int> hintLevel;
  final SessionPacing sessionPacing;
  final bool progressionGate;
  final int version;

  const AdaptationProfile({
    this.keyScale = 1.0,
    this.keyScalePerKey = const {},
    this.keySpacing = 1.0,
    this.dwellTimeMs = 0,
    this.debounceMs = 50,
    this.hintLevel = const {},
    this.sessionPacing = const SessionPacing(),
    this.progressionGate = true,
    this.version = 1,
  });

  factory AdaptationProfile.fromJson(Map<String, dynamic> json) {
    return AdaptationProfile(
      keyScale: (json['key_scale'] as num?)?.toDouble() ?? 1.0,
      keyScalePerKey: (json['key_scale_per_key'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
          const {},
      keySpacing: (json['key_spacing'] as num?)?.toDouble() ?? 1.0,
      dwellTimeMs: (json['dwell_time_ms'] as num?)?.toInt() ?? 0,
      debounceMs: (json['debounce_ms'] as num?)?.toInt() ?? 50,
      hintLevel: (json['hint_level'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toInt())) ??
          const {},
      sessionPacing: json['session_pacing'] != null
          ? SessionPacing.fromJson(json['session_pacing'] as Map<String, dynamic>)
          : const SessionPacing(),
      progressionGate: (json['progression_gate'] as bool?) ?? true,
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'key_scale': keyScale,
        'key_scale_per_key': keyScalePerKey,
        'key_spacing': keySpacing,
        'dwell_time_ms': dwellTimeMs,
        'debounce_ms': debounceMs,
        'hint_level': hintLevel,
        'session_pacing': sessionPacing.toJson(),
        'progression_gate': progressionGate,
        'version': version,
      };

  AdaptationProfile copyWith({
    double? keyScale,
    Map<String, double>? keyScalePerKey,
    double? keySpacing,
    int? dwellTimeMs,
    int? debounceMs,
    Map<String, int>? hintLevel,
    SessionPacing? sessionPacing,
    bool? progressionGate,
    int? version,
  }) {
    return AdaptationProfile(
      keyScale: keyScale ?? this.keyScale,
      keyScalePerKey: keyScalePerKey ?? this.keyScalePerKey,
      keySpacing: keySpacing ?? this.keySpacing,
      dwellTimeMs: dwellTimeMs ?? this.dwellTimeMs,
      debounceMs: debounceMs ?? this.debounceMs,
      hintLevel: hintLevel ?? this.hintLevel,
      sessionPacing: sessionPacing ?? this.sessionPacing,
      progressionGate: progressionGate ?? this.progressionGate,
      version: version ?? this.version,
    );
  }

  static AdaptationProfile get defaults => const AdaptationProfile();
}

class SessionPacing {
  final bool suggestBreak;

  const SessionPacing({this.suggestBreak = false});

  factory SessionPacing.fromJson(Map<String, dynamic> json) {
    return SessionPacing(
      suggestBreak: (json['suggest_break'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {'suggest_break': suggestBreak};
}
