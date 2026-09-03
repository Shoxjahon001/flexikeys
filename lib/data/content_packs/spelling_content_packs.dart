import 'package:flutter/material.dart';
import 'content_pack.dart';

const String _latinAlphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

/// All 33 letters of the modern Russian alphabet — the distractor pool for
/// every `ru` spelling pack below. Kept as one shared constant so it's
/// impossible for a `ru` pack's alphabet to drift out of sync or pick up a
/// stray Latin character (see the script-purity test in
/// test/data/content_packs/spelling_content_packs_test.dart).
const String _cyrillicAlphabet =
    'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ';

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
    alphabet: _latinAlphabet,
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
  'ru': ContentPack(
    categoryId: 'numbers',
    locale: 'ru',
    title: 'Числа',
    questionCount: 15,
    ordered: true,
    alphabet: _cyrillicAlphabet,
    nextLevelToUnlock: 'colors',
    items: [
      ContentItem(id: 'ru.numbers.1', display: '1', word: 'ОДИН'),
      ContentItem(id: 'ru.numbers.2', display: '2', word: 'ДВА'),
      ContentItem(id: 'ru.numbers.3', display: '3', word: 'ТРИ'),
      ContentItem(id: 'ru.numbers.4', display: '4', word: 'ЧЕТЫРЕ'),
      ContentItem(id: 'ru.numbers.5', display: '5', word: 'ПЯТЬ'),
      ContentItem(id: 'ru.numbers.6', display: '6', word: 'ШЕСТЬ'),
      ContentItem(id: 'ru.numbers.7', display: '7', word: 'СЕМЬ'),
      ContentItem(id: 'ru.numbers.8', display: '8', word: 'ВОСЕМЬ'),
      ContentItem(id: 'ru.numbers.9', display: '9', word: 'ДЕВЯТЬ'),
      ContentItem(id: 'ru.numbers.10', display: '10', word: 'ДЕСЯТЬ'),
      ContentItem(id: 'ru.numbers.11', display: '11', word: 'ОДИННАДЦАТЬ'),
      ContentItem(id: 'ru.numbers.12', display: '12', word: 'ДВЕНАДЦАТЬ'),
      ContentItem(id: 'ru.numbers.13', display: '13', word: 'ТРИНАДЦАТЬ'),
      ContentItem(id: 'ru.numbers.15', display: '15', word: 'ПЯТНАДЦАТЬ'),
      ContentItem(id: 'ru.numbers.20', display: '20', word: 'ДВАДЦАТЬ'),
    ],
  ),
};

const Map<String, ContentPack> _colorsPacks = {
  'en': ContentPack(
    categoryId: 'colors',
    locale: 'en',
    title: 'Colors',
    questionCount: 10,
    alphabet: _latinAlphabet,
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
  'ru': ContentPack(
    categoryId: 'colors',
    locale: 'ru',
    title: 'Цвета',
    questionCount: 10,
    alphabet: _cyrillicAlphabet,
    nextLevelToUnlock: 'fruits',
    items: [
      ContentItem(
          id: 'ru.colors.red',
          display: 'Красный',
          word: 'КРАСНЫЙ',
          tileColor: Color(0xFFE53935)),
      ContentItem(
          id: 'ru.colors.blue',
          display: 'Синий',
          word: 'СИНИЙ',
          tileColor: Color(0xFF1E88E5)),
      ContentItem(
          id: 'ru.colors.green',
          display: 'Зелёный',
          word: 'ЗЕЛЁНЫЙ',
          tileColor: Color(0xFF43A047)),
      ContentItem(
          id: 'ru.colors.yellow',
          display: 'Жёлтый',
          word: 'ЖЁЛТЫЙ',
          tileColor: Color(0xFFFDD835)),
      ContentItem(
          id: 'ru.colors.orange',
          display: 'Оранжевый',
          word: 'ОРАНЖЕВЫЙ',
          tileColor: Color(0xFFFF7043)),
      ContentItem(
          id: 'ru.colors.purple',
          display: 'Фиолетовый',
          word: 'ФИОЛЕТОВЫЙ',
          tileColor: Color(0xFF7B1FA2)),
      ContentItem(
          id: 'ru.colors.pink',
          display: 'Розовый',
          word: 'РОЗОВЫЙ',
          tileColor: Color(0xFFEC407A)),
      ContentItem(
          id: 'ru.colors.brown',
          display: 'Коричневый',
          word: 'КОРИЧНЕВЫЙ',
          tileColor: Color(0xFF795548)),
      ContentItem(
          id: 'ru.colors.black',
          display: 'Чёрный',
          word: 'ЧЁРНЫЙ',
          tileColor: Color(0xFF424242)),
      ContentItem(
          id: 'ru.colors.white',
          display: 'Белый',
          word: 'БЕЛЫЙ',
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
    alphabet: _latinAlphabet,
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
  'ru': ContentPack(
    categoryId: 'fruits',
    locale: 'ru',
    title: 'Фрукты',
    questionCount: 12,
    alphabet: _cyrillicAlphabet,
    nextLevelToUnlock: 'animals',
    items: [
      ContentItem(id: 'ru.fruits.apple', display: '🍎', word: 'ЯБЛОКО'),
      ContentItem(id: 'ru.fruits.banana', display: '🍌', word: 'БАНАН'),
      ContentItem(id: 'ru.fruits.grape', display: '🍇', word: 'ВИНОГРАД'),
      ContentItem(id: 'ru.fruits.orange', display: '🍊', word: 'АПЕЛЬСИН'),
      ContentItem(id: 'ru.fruits.melon', display: '🍈', word: 'ДЫНЯ'),
      ContentItem(id: 'ru.fruits.mango', display: '🥭', word: 'МАНГО'),
      ContentItem(id: 'ru.fruits.lemon', display: '🍋', word: 'ЛИМОН'),
      ContentItem(id: 'ru.fruits.pear', display: '🍐', word: 'ГРУША'),
      ContentItem(id: 'ru.fruits.peach', display: '🍑', word: 'ПЕРСИК'),
      ContentItem(id: 'ru.fruits.cherry', display: '🍒', word: 'ВИШНЯ'),
      ContentItem(id: 'ru.fruits.kiwi', display: '🥝', word: 'КИВИ'),
      ContentItem(id: 'ru.fruits.pineapple', display: '🍍', word: 'АНАНАС'),
    ],
  ),
};

const Map<String, ContentPack> _animalsPacks = {
  'en': ContentPack(
    categoryId: 'animals',
    locale: 'en',
    title: 'Animals',
    questionCount: 12,
    alphabet: _latinAlphabet,
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
  'ru': ContentPack(
    categoryId: 'animals',
    locale: 'ru',
    title: 'Животные',
    questionCount: 12,
    alphabet: _cyrillicAlphabet,
    nextLevelToUnlock: 'food',
    items: [
      ContentItem(id: 'ru.animals.cat', display: '🐱', word: 'КОШКА'),
      ContentItem(id: 'ru.animals.dog', display: '🐶', word: 'СОБАКА'),
      ContentItem(id: 'ru.animals.lion', display: '🦁', word: 'ЛЕВ'),
      ContentItem(id: 'ru.animals.hippo', display: '🦛', word: 'БЕГЕМОТ'),
      ContentItem(id: 'ru.animals.monkey', display: '🐒', word: 'ОБЕЗЬЯНА'),
      ContentItem(id: 'ru.animals.zebra', display: '🦓', word: 'ЗЕБРА'),
      ContentItem(id: 'ru.animals.rabbit', display: '🐰', word: 'КРОЛИК'),
      ContentItem(id: 'ru.animals.bear', display: '🐻', word: 'МЕДВЕДЬ'),
      ContentItem(id: 'ru.animals.fox', display: '🦊', word: 'ЛИСА'),
      ContentItem(id: 'ru.animals.tiger', display: '🐯', word: 'ТИГР'),
      ContentItem(id: 'ru.animals.cow', display: '🐮', word: 'КОРОВА'),
      ContentItem(id: 'ru.animals.wolf', display: '🐺', word: 'ВОЛК'),
    ],
  ),
};

const Map<String, ContentPack> _foodPacks = {
  'en': ContentPack(
    categoryId: 'food',
    locale: 'en',
    title: 'Food',
    questionCount: 10,
    alphabet: _latinAlphabet,
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
  'ru': ContentPack(
    categoryId: 'food',
    locale: 'ru',
    title: 'Еда',
    questionCount: 10,
    alphabet: _cyrillicAlphabet,
    nextLevelToUnlock: null,
    items: [
      ContentItem(id: 'ru.food.pizza', display: '🍕', word: 'ПИЦЦА'),
      ContentItem(id: 'ru.food.burger', display: '🍔', word: 'БУРГЕР'),
      ContentItem(id: 'ru.food.cake', display: '🎂', word: 'ТОРТ'),
      ContentItem(id: 'ru.food.juice', display: '🧃', word: 'СОК'),
      ContentItem(id: 'ru.food.taco', display: '🌮', word: 'ТАКО'),
      ContentItem(id: 'ru.food.donut', display: '🍩', word: 'ПОНЧИК'),
      ContentItem(id: 'ru.food.cookie', display: '🍪', word: 'ПЕЧЕНЬЕ'),
      ContentItem(id: 'ru.food.soup', display: '🍜', word: 'СУП'),
      ContentItem(id: 'ru.food.meat', display: '🥩', word: 'МЯСО'),
      ContentItem(id: 'ru.food.sushi', display: '🍣', word: 'СУШИ'),
    ],
  ),
};

/// Locale-keyed content for the 5 spelling-task categories (Numbers,
/// Colors, Fruits, Animals, Food). `uz` still resolves through
/// [ContentPackResolver]'s fallback-to-`en` path (loudly logged in debug)
/// until a uz pack is added.
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
