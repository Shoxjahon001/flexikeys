library aac_card_def;

import '../../../design_system/aac/aac_theme.dart';

/// Supported vocabulary languages — matches the app's three learning
/// languages (see CLAUDE.md "Localization").
enum AacLanguage { en, uz, ru }

extension AacLanguageCode on AacLanguage {
  String get code => name;
}

Map<AacLanguage, String> _localizedMapFromJson(Map<String, dynamic> raw) {
  return {
    for (final lang in AacLanguage.values)
      if (raw[lang.code] != null) lang: raw[lang.code] as String,
  };
}

Map<String, dynamic> _localizedMapToJson(Map<AacLanguage, String> map) {
  return {for (final e in map.entries) e.key.code: e.value};
}

/// A direct card speaks its sentence immediately on tap. A branch card opens
/// a second "fringe" screen (see docs/aac_design_system.md Phase 2.4) and
/// only speaks once a fringe option is chosen — e.g. "Food" -> Apple/Banana/
/// Bread/Rice -> "I want banana."
enum AacCardKind { direct, branch }

/// One selectable option inside a branch card's fringe screen (e.g. "Apple"
/// under "Food", or "Head" under "Pain"). [fillValue] substitutes into the
/// parent card's `{noun}` sentence-template placeholder.
///
/// Naive template substitution reads naturally in English for the starter
/// vocabulary ("I want {noun}." -> "I want banana."), but uz/ru grammar
/// (case endings) may need per-combination sentence overrides for some
/// pairs — flagged as a content-authoring detail for whoever fills in the
/// uz/ru vocabulary JSON, not an architecture gap.
class AacFringeOption {
  final String id;
  final Map<AacLanguage, String> label;
  final Map<AacLanguage, String> fillValue;
  final String animationAsset;
  final Map<AacLanguage, String> audioAsset;

  const AacFringeOption({
    required this.id,
    required this.label,
    required this.fillValue,
    required this.animationAsset,
    required this.audioAsset,
  });

  factory AacFringeOption.fromJson(Map<String, dynamic> json) {
    return AacFringeOption(
      id: json['id'] as String,
      label: _localizedMapFromJson(json['label'] as Map<String, dynamic>),
      fillValue: _localizedMapFromJson(json['fill_value'] as Map<String, dynamic>),
      animationAsset: json['animation_asset'] as String,
      audioAsset: _localizedMapFromJson(json['audio_asset'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': _localizedMapToJson(label),
        'fill_value': _localizedMapToJson(fillValue),
        'animation_asset': animationAsset,
        'audio_asset': _localizedMapToJson(audioAsset),
      };
}

/// One AAC communication card — either a "core" direct card or a "branch"
/// card that opens a fringe-vocabulary sub-screen. See
/// docs/aac_design_system.md §2 for the visual anatomy this data drives.
class AacCardDef {
  final String id;
  final AacCategory category;
  final AacCardKind kind;
  final Map<AacLanguage, String> label;

  /// e.g. "I want {noun}." — `{noun}` is substituted from the tapped
  /// [AacFringeOption]'s fillValue for branch cards, or used as-is (no
  /// placeholder) for direct cards.
  final Map<AacLanguage, String> sentenceTemplate;

  final String animationAsset;
  final Map<AacLanguage, String> audioAsset;

  /// Branch cards only — the fringe-screen options.
  final List<AacFringeOption> fringeOptions;

  /// Parent-created custom cards only — a photo overriding [animationAsset]
  /// with a static image (see docs/aac_design_system.md Phase 4).
  final String? customPhotoPath;

  /// 1-4, matching the progression levels in `AacProgression`. Determines
  /// when this card is auto-unlocked.
  final int difficultyTier;

  final bool isCustom;

  const AacCardDef({
    required this.id,
    required this.category,
    required this.kind,
    required this.label,
    required this.sentenceTemplate,
    required this.animationAsset,
    required this.audioAsset,
    this.fringeOptions = const [],
    this.customPhotoPath,
    required this.difficultyTier,
    this.isCustom = false,
  }) : assert(
          kind == AacCardKind.direct || fringeOptions.length > 0,
          'branch cards must define at least one fringe option',
        );

  /// The spoken/displayed sentence for a direct card, or for a branch card
  /// once [chosenFringe] has been selected. Falls back to English if a
  /// translation is missing rather than showing an empty string.
  String sentenceFor(AacLanguage lang, {AacFringeOption? chosenFringe}) {
    final template = sentenceTemplate[lang] ?? sentenceTemplate[AacLanguage.en] ?? '';
    if (kind == AacCardKind.direct || chosenFringe == null) return template;
    final fill = chosenFringe.fillValue[lang] ?? chosenFringe.fillValue[AacLanguage.en] ?? '';
    return template.replaceAll('{noun}', fill);
  }

  factory AacCardDef.fromJson(Map<String, dynamic> json) {
    final kindStr = json['kind'] as String? ?? 'direct';
    return AacCardDef(
      id: json['id'] as String,
      category: AacCategory.values.byName(json['category'] as String),
      kind: kindStr == 'branch' ? AacCardKind.branch : AacCardKind.direct,
      label: _localizedMapFromJson(json['label'] as Map<String, dynamic>),
      sentenceTemplate:
          _localizedMapFromJson(json['sentence_template'] as Map<String, dynamic>),
      animationAsset: json['animation_asset'] as String,
      audioAsset: _localizedMapFromJson(json['audio_asset'] as Map<String, dynamic>),
      fringeOptions: (json['fringe_options'] as List<dynamic>? ?? const [])
          .map((e) => AacFringeOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      customPhotoPath: json['custom_photo_path'] as String?,
      difficultyTier: json['difficulty_tier'] as int,
      isCustom: json['is_custom'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.name,
        'kind': kind.name,
        'label': _localizedMapToJson(label),
        'sentence_template': _localizedMapToJson(sentenceTemplate),
        'animation_asset': animationAsset,
        'audio_asset': _localizedMapToJson(audioAsset),
        'fringe_options': fringeOptions.map((f) => f.toJson()).toList(),
        if (customPhotoPath != null) 'custom_photo_path': customPhotoPath,
        'difficulty_tier': difficultyTier,
        'is_custom': isCustom,
      };
}
