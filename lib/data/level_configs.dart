import 'package:flutter/material.dart';

class GameItem {
  final String id;
  final String display; // hint shown in the card (emoji / digit)
  final String label;   // the WORD the child must spell (e.g. "APPLE")
  final Color? tileColor; // non-null → show a solid color swatch as hint

  const GameItem({
    required this.id,
    required this.display,
    required this.label,
    this.tileColor,
  });

  /// The uppercase word to spell, derived from label
  String get word => label.toUpperCase();
}

class LevelConfig {
  final String id;
  final String title;
  final String instruction;
  final List<GameItem> items;
  final int questionCount;
  final String? nextLevelToUnlock;
  final int starsReward;

  const LevelConfig({
    required this.id,
    required this.title,
    required this.instruction,
    required this.items,
    required this.questionCount,
    this.nextLevelToUnlock,
    this.starsReward = 10,
  });
}

// ---------------------------------------------------------------------------
// All words verified to have ≤ 6 unique letters so they fit in a 2×3 grid
// ---------------------------------------------------------------------------

class LevelConfigs {
  // ─── Numbers ──────────────────────────────────────────────────────────────
  // display = digit, label = English word to spell
  static const numbers = LevelConfig(
    id: 'numbers',
    title: 'Numbers',
    instruction: 'Spell this number',
    questionCount: 15,
    nextLevelToUnlock: 'colors',
    items: [
      GameItem(id: '1',  display: '1',  label: 'ONE'),    // O,N,E  = 3
      GameItem(id: '2',  display: '2',  label: 'TWO'),    // T,W,O  = 3
      GameItem(id: '3',  display: '3',  label: 'THREE'),  // T,H,R,E= 4
      GameItem(id: '4',  display: '4',  label: 'FOUR'),   // F,O,U,R= 4
      GameItem(id: '5',  display: '5',  label: 'FIVE'),   // F,I,V,E= 4
      GameItem(id: '6',  display: '6',  label: 'SIX'),    // S,I,X  = 3
      GameItem(id: '7',  display: '7',  label: 'SEVEN'),  // S,E,V,N= 4
      GameItem(id: '8',  display: '8',  label: 'EIGHT'),  // E,I,G,H,T=5
      GameItem(id: '9',  display: '9',  label: 'NINE'),   // N,I,E  = 3
      GameItem(id: '10', display: '10', label: 'TEN'),    // T,E,N  = 3
      GameItem(id: '11', display: '11', label: 'ELEVEN'), // E,L,V,N= 4
      GameItem(id: '12', display: '12', label: 'TWELVE'), // T,W,E,L,V=5
      GameItem(id: '13', display: '13', label: 'THIRTEEN'), // T,H,I,R,E,N=6
      GameItem(id: '15', display: '15', label: 'FIFTEEN'), // F,I,T,E,N=5
      GameItem(id: '20', display: '20', label: 'TWENTY'), // T,W,E,N,Y=5
    ],
  );

  // ─── Colors ───────────────────────────────────────────────────────────────
  // display = color name (unused visually), tileColor = swatch shown as hint
  // label = English color name to spell
  static const colors = LevelConfig(
    id: 'colors',
    title: 'Colors',
    instruction: 'Spell this color',
    questionCount: 10,
    nextLevelToUnlock: 'fruits',
    items: [
      GameItem(id: 'red',    display: 'Red',    label: 'RED',    tileColor: Color(0xFFE53935)), // R,E,D=3
      GameItem(id: 'blue',   display: 'Blue',   label: 'BLUE',   tileColor: Color(0xFF1E88E5)), // B,L,U,E=4
      GameItem(id: 'green',  display: 'Green',  label: 'GREEN',  tileColor: Color(0xFF43A047)), // G,R,E,N=4
      GameItem(id: 'yellow', display: 'Yellow', label: 'YELLOW', tileColor: Color(0xFFFDD835)), // Y,E,L,O,W=5
      GameItem(id: 'orange', display: 'Orange', label: 'ORANGE', tileColor: Color(0xFFFF7043)), // O,R,A,N,G,E=6
      GameItem(id: 'purple', display: 'Purple', label: 'PURPLE', tileColor: Color(0xFF7B1FA2)), // P,U,R,L,E=5
      GameItem(id: 'pink',   display: 'Pink',   label: 'PINK',   tileColor: Color(0xFFEC407A)), // P,I,N,K=4
      GameItem(id: 'brown',  display: 'Brown',  label: 'BROWN',  tileColor: Color(0xFF795548)), // B,R,O,W,N=5
      GameItem(id: 'black',  display: 'Black',  label: 'BLACK',  tileColor: Color(0xFF424242)), // B,L,A,C,K=5
      GameItem(id: 'white',  display: 'White',  label: 'WHITE',  tileColor: Color(0xFFE0E0E0)), // W,H,I,T,E=5
    ],
  );

  // ─── Fruits ───────────────────────────────────────────────────────────────
  // display = emoji hint, label = English name to spell (all ≤ 6 unique letters)
  static const fruits = LevelConfig(
    id: 'fruits',
    title: 'Fruits',
    instruction: 'Spell this fruit',
    questionCount: 12,
    nextLevelToUnlock: 'animals',
    items: [
      GameItem(id: 'apple',     display: '🍎', label: 'APPLE'),    // A,P,L,E=4
      GameItem(id: 'banana',    display: '🍌', label: 'BANANA'),   // B,A,N=3
      GameItem(id: 'grape',     display: '🍇', label: 'GRAPE'),    // G,R,A,P,E=5
      GameItem(id: 'orange',    display: '🍊', label: 'ORANGE'),   // O,R,A,N,G,E=6
      GameItem(id: 'melon',     display: '🍈', label: 'MELON'),    // M,E,L,O,N=5
      GameItem(id: 'mango',     display: '🥭', label: 'MANGO'),    // M,A,N,G,O=5
      GameItem(id: 'lemon',     display: '🍋', label: 'LEMON'),    // L,E,M,O,N=5
      GameItem(id: 'pear',      display: '🍐', label: 'PEAR'),     // P,E,A,R=4
      GameItem(id: 'peach',     display: '🍑', label: 'PEACH'),    // P,E,A,C,H=5
      GameItem(id: 'cherry',    display: '🍒', label: 'CHERRY'),   // C,H,E,R,Y=5
      GameItem(id: 'kiwi',      display: '🥝', label: 'KIWI'),     // K,I,W=3
      GameItem(id: 'pineapple', display: '🍍', label: 'PINEAPPLE'), // P,I,N,E,A,L=6
    ],
  );

  // ─── Animals ──────────────────────────────────────────────────────────────
  static const animals = LevelConfig(
    id: 'animals',
    title: 'Animals',
    instruction: 'Spell this animal',
    questionCount: 12,
    nextLevelToUnlock: 'food',
    items: [
      GameItem(id: 'cat',    display: '🐱', label: 'CAT'),    // C,A,T=3
      GameItem(id: 'dog',    display: '🐶', label: 'DOG'),    // D,O,G=3
      GameItem(id: 'lion',   display: '🦁', label: 'LION'),   // L,I,O,N=4
      GameItem(id: 'hippo',  display: '🦛', label: 'HIPPO'),  // H,I,P,O=4
      GameItem(id: 'monkey', display: '🐒', label: 'MONKEY'), // M,O,N,K,E,Y=6
      GameItem(id: 'zebra',  display: '🦓', label: 'ZEBRA'),  // Z,E,B,R,A=5
      GameItem(id: 'rabbit', display: '🐰', label: 'RABBIT'), // R,A,B,I,T=5
      GameItem(id: 'bear',   display: '🐻', label: 'BEAR'),   // B,E,A,R=4
      GameItem(id: 'fox',    display: '🦊', label: 'FOX'),    // F,O,X=3
      GameItem(id: 'tiger',  display: '🐯', label: 'TIGER'),  // T,I,G,E,R=5
      GameItem(id: 'cow',    display: '🐮', label: 'COW'),    // C,O,W=3
      GameItem(id: 'wolf',   display: '🐺', label: 'WOLF'),   // W,O,L,F=4
    ],
  );

  // ─── Food ─────────────────────────────────────────────────────────────────
  static const food = LevelConfig(
    id: 'food',
    title: 'Food',
    instruction: 'Spell this food',
    questionCount: 10,
    nextLevelToUnlock: null,
    items: [
      GameItem(id: 'pizza',  display: '🍕', label: 'PIZZA'),  // P,I,Z,A=4
      GameItem(id: 'burger', display: '🍔', label: 'BURGER'), // B,U,R,G,E=5
      GameItem(id: 'cake',   display: '🎂', label: 'CAKE'),   // C,A,K,E=4
      GameItem(id: 'juice',  display: '🧃', label: 'JUICE'),  // J,U,I,C,E=5
      GameItem(id: 'taco',   display: '🌮', label: 'TACO'),   // T,A,C,O=4
      GameItem(id: 'donut',  display: '🍩', label: 'DONUT'),  // D,O,N,U,T=5
      GameItem(id: 'cookie', display: '🍪', label: 'COOKIE'), // C,O,K,I,E=5
      GameItem(id: 'soup',   display: '🍜', label: 'SOUP'),   // S,O,U,P=4
      GameItem(id: 'meat',   display: '🥩', label: 'MEAT'),   // M,E,A,T=4
      GameItem(id: 'sushi',  display: '🍣', label: 'SUSHI'),  // S,U,H,I=4
    ],
  );

  static LevelConfig? getById(String id) {
    switch (id) {
      case 'numbers': return numbers;
      case 'colors':  return colors;
      case 'fruits':  return fruits;
      case 'animals': return animals;
      case 'food':    return food;
      default:        return null;
    }
  }
}
