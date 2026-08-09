library aac_strings;

import '../domain/aac_card_def.dart';

/// Localized UI copy for child-facing AAC screens — CLAUDE.md: "Any
/// child-facing copy must exist in all three languages before merge."
/// Covers the handful of UI strings (tooltips, the Sentence Strip's empty
/// placeholder) that aren't vocabulary content and so don't come from
/// `shared/aac/*.json` — those already carry en/uz/ru per card (Phase 1).
class AacStrings {
  final String sentenceStripPlaceholder;
  final String speakTooltip;
  final String clearTooltip;
  final String buildSentenceTooltip;
  final String closeTooltip;
  final String replayTooltip;

  const AacStrings({
    required this.sentenceStripPlaceholder,
    required this.speakTooltip,
    required this.clearTooltip,
    required this.buildSentenceTooltip,
    required this.closeTooltip,
    required this.replayTooltip,
  });

  static const Map<AacLanguage, AacStrings> _all = {
    AacLanguage.en: AacStrings(
      sentenceStripPlaceholder: 'Tap cards to build a sentence',
      speakTooltip: 'Speak',
      clearTooltip: 'Clear',
      buildSentenceTooltip: 'Build a sentence',
      closeTooltip: 'Close',
      replayTooltip: 'Replay',
    ),
    AacLanguage.uz: AacStrings(
      sentenceStripPlaceholder: "Gap tuzish uchun kartalarni bosing",
      speakTooltip: 'Gapirish',
      clearTooltip: 'Tozalash',
      buildSentenceTooltip: 'Gap tuzish',
      closeTooltip: 'Yopish',
      replayTooltip: 'Qayta eshitish',
    ),
    AacLanguage.ru: AacStrings(
      sentenceStripPlaceholder:
          'Нажимайте карточки, чтобы составить предложение',
      speakTooltip: 'Сказать',
      clearTooltip: 'Очистить',
      buildSentenceTooltip: 'Составить предложение',
      closeTooltip: 'Закрыть',
      replayTooltip: 'Повторить',
    ),
  };

  static AacStrings of(AacLanguage language) =>
      _all[language] ?? _all[AacLanguage.en]!;
}
