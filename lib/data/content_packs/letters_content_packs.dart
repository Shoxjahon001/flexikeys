import 'content_pack.dart';

// ---------------------------------------------------------------------------
// English pack — migrated verbatim from the pre-refactor
// lib/screens/game/letters_stage1_screen.dart's hardcoded `_letters` list
// (A-O, 15 letters). Content and order are unchanged in this migration —
// completing the English alphabet to A-Z is content work, deferred
// alongside the Russian pack (see PROGRESS.md).
// ---------------------------------------------------------------------------

const ContentPack _lettersEn = ContentPack(
  categoryId: 'letters',
  locale: 'en',
  title: 'Letters',
  questionCount: 15,
  ordered: true,
  nextLevelToUnlock: 'numbers',
  items: [
    ContentItem(id: 'en.letters.a', display: 'A', word: 'A'),
    ContentItem(id: 'en.letters.b', display: 'B', word: 'B'),
    ContentItem(id: 'en.letters.c', display: 'C', word: 'C'),
    ContentItem(id: 'en.letters.d', display: 'D', word: 'D'),
    ContentItem(id: 'en.letters.e', display: 'E', word: 'E'),
    ContentItem(id: 'en.letters.f', display: 'F', word: 'F'),
    ContentItem(id: 'en.letters.g', display: 'G', word: 'G'),
    ContentItem(id: 'en.letters.h', display: 'H', word: 'H'),
    ContentItem(id: 'en.letters.i', display: 'I', word: 'I'),
    ContentItem(id: 'en.letters.j', display: 'J', word: 'J'),
    ContentItem(id: 'en.letters.k', display: 'K', word: 'K'),
    ContentItem(id: 'en.letters.l', display: 'L', word: 'L'),
    ContentItem(id: 'en.letters.m', display: 'M', word: 'M'),
    ContentItem(id: 'en.letters.n', display: 'N', word: 'N'),
    ContentItem(id: 'en.letters.o', display: 'O', word: 'O'),
  ],
);

const Map<String, ContentPack> _lettersPacks = {'en': _lettersEn};

/// Locale-keyed content for the Letters category. Only `en` exists today —
/// `uz`/`ru` both resolve through [ContentPackResolver]'s fallback-to-`en`
/// path (loudly logged in debug) until locale-specific packs are added.
class LettersContentPacks {
  const LettersContentPacks._();

  static ContentPack resolve(String uiLocale) =>
      ContentPackResolver.resolve(_lettersPacks, uiLocale);
}
