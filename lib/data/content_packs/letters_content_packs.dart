import 'content_pack.dart';

// ---------------------------------------------------------------------------
// English pack — the original pre-refactor A-O (15 letters, see git
// history) completed to the full A-Z alphabet, alongside adding the
// Russian pack (see PROGRESS.md for why this was deferred out of the
// pure-architecture migration).
// ---------------------------------------------------------------------------

const ContentPack _lettersEn = ContentPack(
  categoryId: 'letters',
  locale: 'en',
  title: 'Letters',
  questionCount: 26,
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
    ContentItem(id: 'en.letters.p', display: 'P', word: 'P'),
    ContentItem(id: 'en.letters.q', display: 'Q', word: 'Q'),
    ContentItem(id: 'en.letters.r', display: 'R', word: 'R'),
    ContentItem(id: 'en.letters.s', display: 'S', word: 'S'),
    ContentItem(id: 'en.letters.t', display: 'T', word: 'T'),
    ContentItem(id: 'en.letters.u', display: 'U', word: 'U'),
    ContentItem(id: 'en.letters.v', display: 'V', word: 'V'),
    ContentItem(id: 'en.letters.w', display: 'W', word: 'W'),
    ContentItem(id: 'en.letters.x', display: 'X', word: 'X'),
    ContentItem(id: 'en.letters.y', display: 'Y', word: 'Y'),
    ContentItem(id: 'en.letters.z', display: 'Z', word: 'Z'),
  ],
);

// ---------------------------------------------------------------------------
// Russian pack — all 33 letters of the modern Russian alphabet, in
// standard alphabetical order. Ids are transliterated letter *names*
// (ASCII, per the asset-filename constraint), not the Cyrillic glyphs
// themselves.
//
// Ь (soft sign) and Ъ (hard sign) have no standalone sound — [pronunciation]
// overrides what's spoken to their letter *name* ("мягкий знак" / "твёрдый
// знак") instead of trying to voice the glyph itself. Every other letter is
// spoken as itself (Ё included, distinct from Е, with its own "yo" sound).
// ---------------------------------------------------------------------------

const ContentPack _lettersRu = ContentPack(
  categoryId: 'letters',
  locale: 'ru',
  title: 'Буквы',
  questionCount: 33,
  ordered: true,
  nextLevelToUnlock: 'numbers',
  // 5, not the default 10 — this pack is presented as 9 separate groups
  // (see groupSizes below), each independently rewarded via
  // splitIntoGroups inheriting this value, matching the exact per-group
  // reward already used for the Drawing module's letter groups
  // (trace_drawing_screen.dart). The umbrella 'letters'/'letters_1'
  // completion once every group is done (letters_group_picker_screen.dart)
  // awards 0 additional stars — each group already paid out its own.
  starsReward: 5,
  // 33 letters is too long for one sitting — chunked into 9 groups of 3-4,
  // front-loading groups of 4 then 3, the same convention already proven
  // for English's 26 letters in lib/data/trace_items/letters_trace_data.dart
  // (kLetterGroups: [4,4,4,4,4,3,3]). English's own Letters pack has no
  // groupSizes — it stays a flat run, unchanged from today.
  groupSizes: [4, 4, 4, 4, 4, 4, 3, 3, 3],
  items: [
    ContentItem(id: 'ru.letters.a', display: 'А', word: 'А'),
    ContentItem(id: 'ru.letters.be', display: 'Б', word: 'Б'),
    ContentItem(id: 'ru.letters.ve', display: 'В', word: 'В'),
    ContentItem(id: 'ru.letters.ge', display: 'Г', word: 'Г'),
    ContentItem(id: 'ru.letters.de', display: 'Д', word: 'Д'),
    ContentItem(id: 'ru.letters.ye', display: 'Е', word: 'Е'),
    ContentItem(id: 'ru.letters.yo', display: 'Ё', word: 'Ё'),
    ContentItem(id: 'ru.letters.zhe', display: 'Ж', word: 'Ж'),
    ContentItem(id: 'ru.letters.ze', display: 'З', word: 'З'),
    ContentItem(id: 'ru.letters.i', display: 'И', word: 'И'),
    ContentItem(id: 'ru.letters.i_kratkoe', display: 'Й', word: 'Й'),
    ContentItem(id: 'ru.letters.ka', display: 'К', word: 'К'),
    ContentItem(id: 'ru.letters.el', display: 'Л', word: 'Л'),
    ContentItem(id: 'ru.letters.em', display: 'М', word: 'М'),
    ContentItem(id: 'ru.letters.en', display: 'Н', word: 'Н'),
    ContentItem(id: 'ru.letters.o', display: 'О', word: 'О'),
    ContentItem(id: 'ru.letters.pe', display: 'П', word: 'П'),
    ContentItem(id: 'ru.letters.er', display: 'Р', word: 'Р'),
    ContentItem(id: 'ru.letters.es', display: 'С', word: 'С'),
    ContentItem(id: 'ru.letters.te', display: 'Т', word: 'Т'),
    ContentItem(id: 'ru.letters.u', display: 'У', word: 'У'),
    ContentItem(id: 'ru.letters.ef', display: 'Ф', word: 'Ф'),
    ContentItem(id: 'ru.letters.kha', display: 'Х', word: 'Х'),
    ContentItem(id: 'ru.letters.tse', display: 'Ц', word: 'Ц'),
    ContentItem(id: 'ru.letters.che', display: 'Ч', word: 'Ч'),
    ContentItem(id: 'ru.letters.sha', display: 'Ш', word: 'Ш'),
    ContentItem(id: 'ru.letters.shcha', display: 'Щ', word: 'Щ'),
    ContentItem(
      id: 'ru.letters.tvyordy_znak',
      display: 'Ъ',
      word: 'Ъ',
      pronunciation: 'твёрдый знак',
    ),
    ContentItem(id: 'ru.letters.y', display: 'Ы', word: 'Ы'),
    ContentItem(
      id: 'ru.letters.myagky_znak',
      display: 'Ь',
      word: 'Ь',
      pronunciation: 'мягкий знак',
    ),
    ContentItem(id: 'ru.letters.e', display: 'Э', word: 'Э'),
    ContentItem(id: 'ru.letters.yu', display: 'Ю', word: 'Ю'),
    ContentItem(id: 'ru.letters.ya', display: 'Я', word: 'Я'),
  ],
);

const Map<String, ContentPack> _lettersPacks = {
  'en': _lettersEn,
  'ru': _lettersRu,
};

/// Locale-keyed content for the Letters category. `uz` still resolves
/// through [ContentPackResolver]'s fallback-to-`en` path (loudly logged in
/// debug) until a uz pack is added.
class LettersContentPacks {
  const LettersContentPacks._();

  static ContentPack resolve(String uiLocale) =>
      ContentPackResolver.resolve(_lettersPacks, uiLocale);
}
