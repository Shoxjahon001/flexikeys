// Exports every level-content item (Letters, Numbers, Colors, Fruits,
// Animals, Food — en + ru today) that needs a pronunciation audio asset
// into a JSON manifest at shared/level_content/audio_manifest.json, which
// tools/generate_level_audio.py then reads to actually call Azure TTS.
//
// This split exists because the level content itself lives in typed Dart
// (lib/data/content_packs/*.dart) — the single source of truth — while the
// generator that calls Azure is Python (matching tools/generate_aac_audio.py's
// proven pattern, reused rather than duplicated). The manifest is the one
// generated bridge between them; nothing hand-maintains it.
//
// Run via `flutter test` (not `dart run`) — this file imports
// package:flutter/material.dart transitively through the content-pack
// files, which plain `dart run` cannot compile outside the Flutter
// toolchain. The "No tests ran" trailer afterward is expected and
// harmless; this file has no `test()`/`testWidgets()` calls, it just runs
// its own `main()`.
//
//   flutter test tool/export_audio_manifest.dart
//
// [id] in the manifest is the ContentItem's own id with its locale prefix
// stripped (e.g. 'ru.letters.tvyordy_znak' -> 'letters.tvyordy_znak') —
// redundant to repeat inside a manifest section already keyed by locale.
// [path] is exactly where tools/generate_level_audio.py will write the
// synthesized file, and exactly where the app will look it up at runtime.
import 'dart:convert';
import 'dart:io';

import 'package:flexikeys/data/content_packs/content_pack.dart';
import 'package:flexikeys/data/content_packs/letters_content_packs.dart';
import 'package:flexikeys/data/content_packs/spelling_content_packs.dart';
import 'package:flexikeys/services/level_audio_player.dart';

const _spellingCategories = ['numbers', 'colors', 'fruits', 'animals', 'food'];
const _locales = ['en', 'ru'];

const _outputPath = 'shared/level_content/audio_manifest.json';

void main() {
  final manifest = <String, List<Map<String, String>>>{};

  for (final locale in _locales) {
    final entries = <Map<String, String>>[];
    entries.addAll(_entriesFor(LettersContentPacks.resolve(locale), locale));
    for (final categoryId in _spellingCategories) {
      final pack = SpellingContentPacks.resolve(categoryId, locale);
      if (pack == null || pack.locale != locale) continue; // no pack of its own for this locale
      entries.addAll(_entriesFor(pack, locale));
    }
    manifest[locale] = entries;
  }

  final file = File(_outputPath);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(manifest),
  );

  // ignore: avoid_print
  print('Wrote $_outputPath:');
  for (final locale in _locales) {
    // ignore: avoid_print
    print('  $locale: ${manifest[locale]!.length} items');
  }
}

List<Map<String, String>> _entriesFor(ContentPack pack, String locale) {
  final prefix = '$locale.';
  return [
    for (final item in pack.items)
      {
        'id': item.id.startsWith(prefix)
            ? item.id.substring(prefix.length)
            : item.id,
        'text': item.spokenText,
        // Reuses LevelAudioPlayer's own path-building logic rather than
        // reimplementing it here — the manifest this writes and the path
        // the app looks up at runtime must never be able to drift apart.
        'path': LevelAudioPlayer.assetPathFor(item, locale),
      },
  ];
}
