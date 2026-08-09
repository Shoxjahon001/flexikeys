library aac_progression;

/// The four "My Voice" progression levels. Levels 1-3 gate how much of the
/// vocabulary library is unlocked (by `AacCardDef.difficultyTier`); level 4
/// unlocks the Sentence Strip screen (docs/aac_design_system.md Phase 2.5),
/// which composes sentences from whatever vocabulary is already unlocked
/// rather than adding new cards.
enum AacLevel {
  level1(6),
  level2(12),
  level3(24),
  level4(null); // uncapped — see doc comment above and docs/aac_phase1_architecture.md

  const AacLevel(this.cardCeiling);

  /// Max number of difficulty-tier-eligible cards unlocked at this level, or
  /// `null` for "no additional cap" (level4: the spec's "Level 4 = sentence
  /// building" reads as a mode change, not a fourth vocabulary tier —
  /// capping it at 24 would leave the 13 tier-4 starter cards permanently
  /// unreachable, which can't be the intent).
  final int? cardCeiling;

  bool get unlocksSentenceBuilding => this == AacLevel.level4;
}

/// A child's current "My Voice" progression state.
///
/// Parents unlock levels manually from the AAC settings screen
/// (docs/aac_design_system.md Phase 4), or accept an AI suggestion
/// (Phase 3) — both paths call [copyWith]; there is no separate "auto"
/// state that applies itself.
///
/// Note on CLAUDE.md's "Parents never configure adaptation" rule: that rule
/// governs the *learning* adaptive engine (key size, dwell time, hint
/// level — accessibility tuning that must stay invisible/automatic). AAC
/// vocabulary pacing is a different kind of decision — closer to a
/// curriculum/communication-therapy choice (which words a child is ready
/// for) than an accessibility adaptation — which is why the original spec
/// has the parent (or a licensed therapist via the parent) drive it
/// directly rather than the engine tuning it silently. Flagging this
/// explicitly rather than deciding it silently — confirm this reading is
/// what you intended before Phase 4 builds the actual unlock UI.
class AacProgressionState {
  final AacLevel level;

  /// True once a parent has manually set the level at least once.
  final bool manuallySet;

  final DateTime updatedAt;

  const AacProgressionState({
    this.level = AacLevel.level1,
    this.manuallySet = false,
    required this.updatedAt,
  });

  AacProgressionState copyWith({
    AacLevel? level,
    bool? manuallySet,
    DateTime? updatedAt,
  }) {
    return AacProgressionState(
      level: level ?? this.level,
      manuallySet: manuallySet ?? this.manuallySet,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory AacProgressionState.fromJson(Map<String, dynamic> json) => AacProgressionState(
        level: AacLevel.values.byName(json['level'] as String),
        manuallySet: json['manually_set'] as bool? ?? false,
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'level': level.name,
        'manually_set': manuallySet,
        'updated_at': updatedAt.toIso8601String(),
      };
}
