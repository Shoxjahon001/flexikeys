import 'package:flutter/material.dart';
import 'content_pack.dart';

// ---------------------------------------------------------------------------
// English packs — migrated verbatim from the pre-refactor
// lib/data/level_configs.dart (LevelConfig/GameItem). Content, ordering,
// item counts, and ids are unchanged; only the types/field names changed
// (label -> word, already uppercase) and each item's id is now
// locale-scoped ('en.<category>.<id>') per ContentItem's contract.
//
// All words verified to have ≤ 6 unique letters so they fit in a 2×3 grid.
// ---------------------------------------------------------------------------

const Map<String, ContentPack> _numbersPacks = {
  'en': ContentPack(
    categoryId: 'numbers',
    locale: 'en',
    title: 'Numbers',
    questionCount: 15,
    ordered: true,
    alphabet: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
    nextLevelToUnlock: 'colors',
    items: [
      ContentItem(id: 'en.numbers.1', display: '1', word: 'ONE'),
      ContentItem(id: 'en.numbers.2', display: '2', word: 'TWO'),
      ContentItem(id: 'en.numbers.3', display: '3', word: 'THREE'),
      ContentItem(id: 'en.numbers.4', display: '4', word: 'FOUR'),
      ContentItem(id: 'en.numbers.5', display: '5', word: 'FIVE'),
      ContentItem(id: 'en.numbers.6', display: '6', word: 'SIX'),
      ContentItem(id: 'en.numbers.7', display: '7', word: 'SEVEN'),
      ContentItem(id: 'en.numbers.8', display: '8', word: 'EIGHT'),
      ContentItem(id: 'en.numbers.9', display: '9', word: 'NINE'),
      ContentItem(id: 'en.numbers.10', display: '10', word: 'TEN'),
      ContentItem(id: 'en.numbers.11', display: '11', word: 'ELEVEN'),
      ContentItem(id: 'en.numbers.12', display: '12', word: 'TWELVE'),
      ContentItem(id: 'en.numbers.13', display: '13', word: 'THIRTEEN'),
      ContentItem(id: 'en.numbers.15', display: '15', word: 'FIFTEEN'),
      ContentItem(id: 'en.numbers.20', display: '20', word: 'TWENTY'),
    ],
  ),
};

const Map<String, ContentPack> _colorsPacks = {
  'en': ContentPack(
    categoryId: 'colors',
    locale: 'en',
    title: 'Colors',
    questionCount: 10,
    alphabet: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
    nextLevelToUnlock: 'fruits',
    items: [
      ContentItem(
          id: 'en.colors.red',
          display: 'Red',
          word: 'RED',
          tileColor: Color(0xFFE53935)),
      ContentItem(
          id: 'en.colors.blue',
          display: 'Blue',
          word: 'BLUE',
          tileColor: Color(0xFF1E88E5)),
      ContentItem(
          id: 'en.colors.green',
          display: 'Green',
          word: 'GREEN',
          tileColor: Color(0xFF43A047)),
      ContentItem(
          id: 'en.colors.yellow',
          display: 'Yellow',
          word: 'YELLOW',
          tileColor: Color(0xFFFDD835)),
      ContentItem(
          id: 'en.colors.orange',
          display: 'Orange',
          word: 'ORANGE',
          tileColor: Color(0xFFFF7043)),
      ContentItem(
          id: 'en.colors.purple',
          display: 'Purple',
          word: 'PURPLE',
          tileColor: Color(0xFF7B1FA2)),
      ContentItem(
          id: 'en.colors.pink',
          display: 'Pink',
          word: 'PINK',
          tileColor: Color(0xFFEC407A)),
      ContentItem(
          id: 'en.colors.brown',
          display: 'Brown',
          word: 'BROWN',
          tileColor: Color(0xFF795548)),
      ContentItem(
          id: 'en.colors.black',
          display: 'Black',
          word: 'BLACK',
          tileColor: Color(0xFF424242)),
      ContentItem(
          id: 'en.colors.white',
          display: 'White',
          word: 'WHITE',
          tileColor: Color(0xFFE0E0E0)),
    ],
  ),
};

const Map<String, ContentPack> _fruitsPacks = {
  'en': ContentPack(
    categoryId: 'fruits',
    locale: 'en',
    title: 'Fruits',
    questionCount: 12,
    alphabet: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
    nextLevelToUnlock: 'animals',
    items: [
      ContentItem(id: 'en.fruits.apple', display: '🍎', word: 'APPLE'),
      ContentItem(id: 'en.fruits.banana', display: '🍌', word: 'BANANA'),
      ContentItem(id: 'en.fruits.grape', display: '🍇', word: 'GRAPE'),
      ContentItem(id: 'en.fruits.orange', display: '🍊', word: 'ORANGE'),
      ContentItem(id: 'en.fruits.melon', display: '🍈', word: 'MELON'),
      ContentItem(id: 'en.fruits.mango', display: '🥭', word: 'MANGO'),
      ContentItem(id: 'en.fruits.lemon', display: '🍋', word: 'LEMON'),
      ContentItem(id: 'en.fruits.pear', display: '🍐', word: 'PEAR'),
      ContentItem(id: 'en.fruits.peach', display: '🍑', word: 'PEACH'),
      ContentItem(id: 'en.fruits.cherry', display: '🍒', word: 'CHERRY'),
      ContentItem(id: 'en.fruits.kiwi', display: '🥝', word: 'KIWI'),
      ContentItem(
          id: 'en.fruits.pineapple', display: '🍍', word: 'PINEAPPLE'),
    ],
  ),
};

const Map<String, ContentPack> _animalsPacks = {
  'en': ContentPack(
    categoryId: 'animals',
    locale: 'en',
    title: 'Animals',
    questionCount: 12,
    alphabet: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
    nextLevelToUnlock: 'food',
    items: [
      ContentItem(id: 'en.animals.cat', display: '🐱', word: 'CAT'),
      ContentItem(id: 'en.animals.dog', display: '🐶', word: 'DOG'),
      ContentItem(id: 'en.animals.lion', display: '🦁', word: 'LION'),
      ContentItem(id: 'en.animals.hippo', display: '🦛', word: 'HIPPO'),
      ContentItem(id: 'en.animals.monkey', display: '🐒', word: 'MONKEY'),
      ContentItem(id: 'en.animals.zebra', display: '🦓', word: 'ZEBRA'),
      ContentItem(id: 'en.animals.rabbit', display: '🐰', word: 'RABBIT'),
      ContentItem(id: 'en.animals.bear', display: '🐻', word: 'BEAR'),
      ContentItem(id: 'en.animals.fox', display: '🦊', word: 'FOX'),
      ContentItem(id: 'en.animals.tiger', display: '🐯', word: 'TIGER'),
      ContentItem(id: 'en.animals.cow', display: '🐮', word: 'COW'),
      ContentItem(id: 'en.animals.wolf', display: '🐺', word: 'WOLF'),
    ],
  ),
};

const Map<String, ContentPack> _foodPacks = {
  'en': ContentPack(
    categoryId: 'food',
    locale: 'en',
    title: 'Food',
    questionCount: 10,
    alphabet: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
    nextLevelToUnlock: null,
    items: [
      ContentItem(id: 'en.food.pizza', display: '🍕', word: 'PIZZA'),
      ContentItem(id: 'en.food.burger', display: '🍔', word: 'BURGER'),
      ContentItem(id: 'en.food.cake', display: '🎂', word: 'CAKE'),
      ContentItem(id: 'en.food.juice', display: '🧃', word: 'JUICE'),
      ContentItem(id: 'en.food.taco', display: '🌮', word: 'TACO'),
      ContentItem(id: 'en.food.donut', display: '🍩', word: 'DONUT'),
      ContentItem(id: 'en.food.cookie', display: '🍪', word: 'COOKIE'),
      ContentItem(id: 'en.food.soup', display: '🍜', word: 'SOUP'),
      ContentItem(id: 'en.food.meat', display: '🥩', word: 'MEAT'),
      ContentItem(id: 'en.food.sushi', display: '🍣', word: 'SUSHI'),
    ],
  ),
};

/// Locale-keyed content for the 5 spelling-task categories (Numbers,
/// Colors, Fruits, Animals, Food). Only `en` exists today — `uz`/`ru` both
/// resolve through [ContentPackResolver]'s fallback-to-`en` path (loudly
/// logged in debug) until locale-specific packs are added.
class SpellingContentPacks {
  const SpellingContentPacks._();

  static Map<String, ContentPack>? localesFor(String categoryId) {
    switch (categoryId) {
      case 'numbers':
        return _numbersPacks;
      case 'colors':
        return _colorsPacks;
      case 'fruits':
        return _fruitsPacks;
      case 'animals':
        return _animalsPacks;
      case 'food':
        return _foodPacks;
      default:
        return null;
    }
  }

  /// Resolves the [categoryId] pack for [uiLocale], falling back to `en`.
  /// Returns null only if [categoryId] itself is unknown.
  static ContentPack? resolve(String categoryId, String uiLocale) {
    final locales = localesFor(categoryId);
    if (locales == null) return null;
    return ContentPackResolver.resolve(locales, uiLocale);
  }
}
