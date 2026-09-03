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
  });
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
