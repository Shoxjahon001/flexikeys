library aac_language;

import 'package:flutter/widgets.dart';

import '../domain/aac_card_def.dart';

/// The AAC module's active vocabulary language — the app's UI/interface
/// language (`Localizations.localeOf`), NOT the separate curriculum
/// learning language (`UserService.getLanguage`).
///
/// AAC is a communication tool, not curriculum: its spoken output has to
/// be in the language of the person the child is talking TO, and that's
/// the language the parent set as the interface language — see CLAUDE.md
/// "AAC voice follows UI language, not learning language" for the full
/// reasoning (this reverses an earlier, explicitly documented decision).
/// Curriculum/letters/shapes content is unaffected and stays on the
/// learning language.
///
/// Reading this via `Localizations.localeOf(context)` inside a widget's
/// `build()`/`didChangeDependencies()` makes it reactive for free — Flutter
/// rebuilds every descendant of `MaterialApp` when its `locale` changes
/// (see main.dart's `ValueListenableBuilder` over
/// `UserService.uiLanguageNotifier`), so a screen that re-derives this on
/// every build switches language immediately, even if it was already open
/// when the parent changed the setting. This is why AAC screens read this
/// instead of taking `language` as a one-shot constructor parameter.
AacLanguage aacLanguageOf(BuildContext context) {
  final code = Localizations.localeOf(context).languageCode;
  return AacLanguage.values.firstWhere(
    (l) => l.code == code,
    orElse: () => AacLanguage.en,
  );
}
