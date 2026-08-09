library follow_up_suggestions;

import '../../../l10n/app_localizations.dart';

/// Topic keywords per group, in all three interface languages — the starter
/// prompt chips this matches against (see assistant_screen.dart) are
/// localized, so an English-only keyword list would silently stop matching
/// the moment a chip is tapped in Uzbek or Russian. Free-typed prompts in a
/// language/phrasing not covered here still fall through to the default
/// set — this stays a heuristic layer, not a translation engine.
const _weekSummaryWords = [
  'week',
  'summary',
  'hafta',
  'xulosa',
  'недел',
  'сводк'
];
const _practiceWords = [
  'practice',
  'activit',
  'goal',
  'mashq',
  'faoliyat',
  'maqsad',
  'практик',
  'занят',
  'цел',
];
const _skillWords = [
  'letter',
  'hard',
  'weak',
  'strength',
  'harf',
  'qiyin',
  'kuchsiz',
  'kuchli',
  'букв',
  'сложн',
  'слаб',
  'сильн',
];
const _adaptWords = [
  'adapt',
  'keyboard',
  'moslash',
  'klaviatura',
  'адапт',
  'клавиатур'
];
const _motivateWords = [
  'motivat',
  "rag'batlantir",
  'undash',
  'мотивир',
  'поощр',
];

/// Static, topic-keyed follow-up prompts shown as chips after an assistant
/// reply. This is a heuristic suggestion layer — keyword-matched against the
/// user's own prompt, not model-generated — so tapping one just sends
/// another real question through the same grounded `/ai-assistant/chat`
/// pipeline; nothing here is fabricated content.
List<String> followUpSuggestions(AppLocalizations t, String lastUserPrompt) {
  final p = lastUserPrompt.toLowerCase();

  if (_weekSummaryWords.any(p.contains)) {
    return [
      t.followUpCompareLastWeek,
      t.followUpAnyConcerns,
      t.followUpWhatPracticeNext
    ];
  }
  if (_practiceWords.any(p.contains)) {
    return [t.followUpWhyActivities, t.followUpHowLongPractice];
  }
  if (_skillWords.any(p.contains)) {
    return [t.followUpHowHelpAtHome, t.followUpIsNormalAge];
  }
  if (_adaptWords.any(p.contains)) {
    return [t.followUpWhyChanged, t.followUpWhatElseAdapted];
  }
  if (_motivateWords.any(p.contains)) {
    return [t.followUpHowEncourage, t.followUpBreakSchedule];
  }
  return [t.followUpWhatPracticeToday, t.followUpHowChildOverall];
}
