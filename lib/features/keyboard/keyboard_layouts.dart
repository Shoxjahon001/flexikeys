library keyboard_layouts;

/// A single key definition within a layout row.
class KeyDef {
  final String value;
  final double widthFactor; // relative to base key width (1.0 = normal)

  const KeyDef(this.value, {this.widthFactor = 1.0});
}

/// A full keyboard layout: ordered list of rows, each with KeyDefs.
class KeyboardLayout {
  final String language;
  final List<List<KeyDef>> rows;

  const KeyboardLayout({required this.language, required this.rows});
}

/// Returns a reduced layout for lesson mode — only [visibleKeys] + backspace.
KeyboardLayout lessonLayout(KeyboardLayout full, Set<String> visibleKeys) {
  final filteredRows = full.rows.map((row) {
    return row.where((k) => visibleKeys.contains(k.value) || k.value == '⌫').toList();
  }).where((row) => row.isNotEmpty).toList();

  return KeyboardLayout(language: full.language, rows: filteredRows);
}

// ── English QWERTY-lite ───────────────────────────────────────────────────────

const KeyboardLayout enLayout = KeyboardLayout(
  language: 'en',
  rows: [
    [
      KeyDef('q'), KeyDef('w'), KeyDef('e'), KeyDef('r'), KeyDef('t'),
      KeyDef('y'), KeyDef('u'), KeyDef('i'), KeyDef('o'), KeyDef('p'),
    ],
    [
      KeyDef('a'), KeyDef('s'), KeyDef('d'), KeyDef('f'), KeyDef('g'),
      KeyDef('h'), KeyDef('j'), KeyDef('k'), KeyDef('l'),
    ],
    [
      KeyDef('z'), KeyDef('x'), KeyDef('c'), KeyDef('v'), KeyDef('b'),
      KeyDef('n'), KeyDef('m'), KeyDef('⌫', widthFactor: 1.4),
    ],
  ],
);

// ── Uzbek Latin (includes o', g', sh, ch, ng as single keys) ─────────────────

const KeyboardLayout uzLayout = KeyboardLayout(
  language: 'uz',
  rows: [
    [
      KeyDef('q'), KeyDef('w'), KeyDef('e'), KeyDef('r'), KeyDef('t'),
      KeyDef('y'), KeyDef('u'), KeyDef('i'), KeyDef('o'), KeyDef('p'),
    ],
    [
      KeyDef('a'), KeyDef('s'), KeyDef('d'), KeyDef('f'), KeyDef('g'),
      KeyDef('h'), KeyDef('j'), KeyDef('k'), KeyDef('l'),
    ],
    [
      KeyDef("o'", widthFactor: 1.3), KeyDef("g'", widthFactor: 1.3),
      KeyDef('sh', widthFactor: 1.3), KeyDef('ch', widthFactor: 1.3),
      KeyDef('ng', widthFactor: 1.3),
    ],
    [
      KeyDef('z'), KeyDef('x'), KeyDef('v'), KeyDef('b'),
      KeyDef('n'), KeyDef('m'), KeyDef('⌫', widthFactor: 1.4),
    ],
  ],
);

// ── Russian ЙЦУКЕН-lite ───────────────────────────────────────────────────────

const KeyboardLayout ruLayout = KeyboardLayout(
  language: 'ru',
  rows: [
    [
      KeyDef('й'), KeyDef('ц'), KeyDef('у'), KeyDef('к'), KeyDef('е'),
      KeyDef('н'), KeyDef('г'), KeyDef('ш'), KeyDef('щ'), KeyDef('з'),
    ],
    [
      KeyDef('ф'), KeyDef('ы'), KeyDef('в'), KeyDef('а'), KeyDef('п'),
      KeyDef('р'), KeyDef('о'), KeyDef('л'), KeyDef('д'), KeyDef('ж'),
    ],
    [
      KeyDef('э'), KeyDef('я'), KeyDef('ч'), KeyDef('с'), KeyDef('м'),
      KeyDef('и'), KeyDef('т'), KeyDef('ь'), KeyDef('⌫', widthFactor: 1.4),
    ],
  ],
);

/// Returns the layout for [lang], defaulting to English.
KeyboardLayout layoutFor(String lang) {
  switch (lang) {
    case 'uz':
      return uzLayout;
    case 'ru':
      return ruLayout;
    default:
      return enLayout;
  }
}