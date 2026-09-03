import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// One teachable item inside a locale-specific [ContentPack] — a single
/// letter, number, or spelling word.
///
/// [id] is stable and locale-scoped (e.g. `'en.animals.zebra'`), used for
/// audio lookup and progress persistence — never derived from list
/// position. Locales don't all have the same item count (Russian's 33-letter
/// alphabet vs. English's 26), so a positional key would silently misalign
/// across locales; a stable id can't.
@immutable
class ContentItem {
  final String id;

  /// Hint shown on the card — emoji, digit, or (for colors) unused, since a
  /// color swatch is drawn from [ContentPack] item [tileColor] instead.
  final String display;

  /// The word (or single letter) the child spells/taps, already in this
  /// pack's locale and uppercase.
  final String word;

  final Color? tileColor;

  /// Overrides what's spoken for TTS when it must differ from [word] — the
  /// only known case today is Cyrillic Ь/Ъ, which have no standalone letter
  /// sound and are spoken by their letter *name* instead (e.g. "мягкий
  /// знак"). Null (every other item) means "speak [word] as-is".
  final String? pronunciation;

  const ContentItem({
    required this.id,
    required this.display,
    required this.word,
    this.tileColor,
    this.pronunciation,
  });

  /// The text actually passed to TTS.
  String get spokenText => pronunciation ?? word;
}

/// One category's content for one locale (e.g. "animals" in `ru`).
///
/// Mirrors the shape of the pre-refactor `LevelConfig`/`GameItem` pair
/// (see git history of lib/data/level_configs.dart) so migrating existing
/// English content across is a rename, not a redesign.
@immutable
class ContentPack {
  final String categoryId;
  final String locale;
  final String title;
  final List<ContentItem> items;
  final int questionCount;

  /// When true, items are shown in the original list order (no shuffle) —
  /// e.g. numbers must stay in numeric order.
  final bool ordered;

  /// Distractor letter pool for spelling tasks, e.g. the Latin alphabet for
  /// `en`/`uz`, the Cyrillic alphabet for `ru`. Empty for the `letters`
  /// category, whose own item list already doubles as its distractor pool.
  final String alphabet;

  final String? nextLevelToUnlock;
  final int starsReward;

  /// When set, this pack should be presented as a sequence of small groups
  /// rather than one flat run — each entry is one group's item count, in
  /// presentation order, summing to `items.length` (e.g. `[4,4,4,3]` for a
  /// 15-item pack chunked into 3 groups of 4 and one of 3). Null (every
  /// pack except a large Letters alphabet) means "no grouping — present as
  /// one flat run", today's behavior for every existing pack. See
  /// [splitIntoGroups].
  final List<int>? groupSizes;

  /// When true, items are presented sorted by [ContentItem.word] length
  /// ascending (ties broken by original list position, deterministically —
  /// never random) instead of [ordered]'s fixed-vs-shuffled choice, so a
  /// word-spelling category ramps up in difficulty. False (default)
  /// preserves [ordered]'s existing meaning unchanged. Category authors
  /// should leave this false for any category with its own inherent order
  /// (e.g. Numbers, which must stay numeric — use [ordered] for that).
  final bool lengthSort;

  /// When true, the spelling-task keyboard's key count is driven by each
  /// answer's own unique-letter count via [keyCountFor] (see
  /// keyboard_key_count.dart), and its distractor shuffle is seeded
  /// deterministically per [ContentItem.id] (a retry/relaunch always shows
  /// the same board for the same item). False (default) preserves today's
  /// exact position-based sizing (`GenericGameScreen._gridSize`) and
  /// unseeded per-session shuffle — switching this to true is an
  /// observable behavior change, so it must stay false for every existing
  /// `en`/`uz` pack per the hard "EN/UZ byte-for-byte identical" rule.
  final bool answerDrivenKeyCount;

  const ContentPack({
    required this.categoryId,
    required this.locale,
    required this.title,
    required this.items,
    required this.questionCount,
    this.ordered = false,
    this.alphabet = '',
    this.nextLevelToUnlock,
    this.starsReward = 10,
    this.groupSizes,
    this.lengthSort = false,
    this.answerDrivenKeyCount = false,
  });
}

/// Splits [pack] into small [ContentPack] groups per [ContentPack.groupSizes]
/// — each a real, independently-usable `ContentPack` (same category/locale/
/// alphabet, its own stable id/title so it can be progress-tracked on its
/// own) covering a contiguous slice of [pack]'s items, in order. The task
/// screen that consumes a group's pack (e.g. `LettersStage1Screen`) needs
/// no awareness that grouping exists at all — a group is just a shorter
/// [ContentPack], not a new concept the task screen has to understand.
///
/// Group [ContentItem.id]s are reused verbatim from the parent pack (no new
/// ids minted), but each group pack's own [ContentPack.categoryId] is
/// suffixed with the group index (e.g. `letters_ru_group_3`) — this is the
/// stable slug a group-picker screen persists completion/unlock state
/// under, deliberately distinct from both the parent's own `categoryId`
/// (`letters`) and the unrelated Drawing-module `letters_group_N` slugs.
List<ContentPack> splitIntoGroups(ContentPack pack) {
  final sizes = pack.groupSizes;
  assert(sizes != null, 'splitIntoGroups requires pack.groupSizes to be set');
  assert(
    (sizes ?? const []).fold<int>(0, (a, b) => a + b) == pack.items.length,
    'groupSizes must sum to items.length',
  );
  final groups = <ContentPack>[];
  var start = 0;
  for (var i = 0; i < sizes!.length; i++) {
    final size = sizes[i];
    final slice = pack.items.sublist(start, start + size);
    groups.add(ContentPack(
      categoryId: '${pack.categoryId}_${pack.locale}_group_${i + 1}',
      locale: pack.locale,
      title: '${slice.first.display}-${slice.last.display}',
      items: slice,
      questionCount: slice.length,
      ordered: true,
      alphabet: pack.alphabet,
      starsReward: pack.starsReward,
    ));
    start += size;
  }
  return groups;
}

/// Resolves which locale's [ContentPack] a category should use for the
/// current UI language, falling back to `en` (and logging loudly in debug)
/// when the requested locale has no pack yet.
///
/// A silent fallback would ship English words to a non-English-speaking
/// child with no visible sign anything was wrong — exactly the failure mode
/// this exists to prevent, so the fallback is intentionally noisy rather
/// than quietly "working".
class ContentPackResolver {
  const ContentPackResolver._();

  static ContentPack resolve(
    Map<String, ContentPack> packsByLocale,
    String uiLocale,
  ) {
    final requested = packsByLocale[uiLocale];
    if (requested != null) return requested;

    final fallback = packsByLocale['en'];
    assert(
      fallback != null,
      'Every category must define an "en" ContentPack as the fallback.',
    );

    if (kDebugMode) {
      debugPrint(
        '[ContentPackResolver] No "$uiLocale" pack for category '
        '"${fallback!.categoryId}" — falling back to "en". This ships '
        'English content to a "$uiLocale" UI-language session.',
      );
    }
    return fallback ?? packsByLocale.values.first;
  }
}

/// Orders [pack]'s items for one play session, per the pack's own
/// [ContentPack.lengthSort]/[ContentPack.ordered] fields:
///  - `lengthSort: true` — shortest [ContentItem.word] first, ties broken
///    by original list position (decorated explicitly rather than relying
///    on [List.sort]'s stability, which Dart does not guarantee) — a
///    deterministic difficulty ramp, never random, so a retry/relaunch
///    always sees the same order.
///  - `lengthSort: false, ordered: true` — original list order unchanged
///    (e.g. Numbers, which must stay numeric).
///  - `lengthSort: false, ordered: false` — shuffled using [rng] (today's
///    behavior for every pre-Phase-2b category).
List<ContentItem> orderItemsForSession(ContentPack pack, Random rng) {
  final list = List<ContentItem>.from(pack.items);
  if (pack.lengthSort) {
    final indexed = list.asMap().entries.toList()
      ..sort((a, b) {
        final byLength = a.value.word.length.compareTo(b.value.word.length);
        return byLength != 0 ? byLength : a.key.compareTo(b.key);
      });
    return indexed.map((e) => e.value).toList();
  }
  if (!pack.ordered) list.shuffle(rng);
  return list;
}
