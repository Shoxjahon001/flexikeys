import 'package:flutter/material.dart';

/// One traceable item (a letter, digit, or simple object outline) for
/// [TraceDrawingScreen]. Canvas coordinate system: (0,0) = top-left,
/// (1,1) = bottom-right; content sits between y≈0.15 (cap line) and
/// y≈0.87 (baseline), matching the original letters content.
class TraceItemDef {
  /// Spoken by TTS and shown in the instruction text (e.g. 'A', '7', 'Uy').
  /// The default/fallback for every locale without its own [ruLabel] — for
  /// letters and digits this is locale-independent (a fine-motor tracing
  /// exercise over universal glyph shapes, not curriculum vocabulary), so
  /// no translation is needed there.
  final String label;

  /// Russian translation of [label], for items whose label is a real word
  /// (objects) rather than a universal glyph (letters/digits, which have
  /// no [ruLabel] and fall back to [label] via [labelFor]).
  final String? ruLabel;

  /// Normalized 0–1 waypoints visited in order 1..n.
  final List<Offset> dots;

  /// Polyline segments that together form the item's skeleton (the ghost
  /// guide the child traces over).
  final List<List<Offset>> ghost;

  const TraceItemDef({
    required this.label,
    this.ruLabel,
    required this.dots,
    required this.ghost,
  });

  /// The label to show/speak for [locale] — [ruLabel] when [locale] is
  /// `'ru'` and set, otherwise [label] (today's behavior, unchanged).
  String labelFor(String locale) =>
      (locale == 'ru' && ruLabel != null) ? ruLabel! : label;
}

/// A small sub-task inside the Letters drawing section — 3-4 letters at a
/// time instead of all N in one sitting, so a session feels achievable and
/// each one earns its own reward. See [computeGroupSizes]/[buildLetterGroups].
class LetterGroup {
  /// Also used as the level-progress slug (e.g. 'letters_group_1',
  /// 'letters_group_ru_1').
  final String id;

  /// Shown on the group's card, e.g. 'A-D'.
  final String label;

  final List<TraceItemDef> items;

  const LetterGroup({required this.id, required this.label, required this.items});
}

/// The group-size split for [total] items: as many groups of 4 as
/// possible, front-loaded, with the remainder as groups of 3 — the same
/// scheme already used for English's 26 letters (`[4,4,4,4,4,3,3]`, 7
/// groups) and Russian's 33 (`[4,4,4,4,4,4,3,3,3]`, 9 groups), now derived
/// from the count instead of hardcoded per locale, so a locale's group
/// count is never hand-picked — it falls out of how many letters it has.
List<int> computeGroupSizes(int total) {
  for (int fours = total ~/ 4; fours >= 0; fours--) {
    final remainder = total - 4 * fours;
    if (remainder % 3 == 0) {
      final threes = remainder ~/ 3;
      return [
        for (var i = 0; i < fours; i++) 4,
        for (var i = 0; i < threes; i++) 3,
      ];
    }
  }
  throw ArgumentError('No 3/4-group split exists for $total items');
}

/// Splits [items] into [LetterGroup]s per [computeGroupSizes], in order,
/// no gaps or overlaps. [idPrefix] (e.g. `'letters_group'`) becomes each
/// group's `letters_group_N`-style progress slug.
List<LetterGroup> buildLetterGroups(List<TraceItemDef> items, String idPrefix) {
  final sizes = computeGroupSizes(items.length);
  final groups = <LetterGroup>[];
  var start = 0;
  for (var i = 0; i < sizes.length; i++) {
    final size = sizes[i];
    final slice = items.sublist(start, start + size);
    groups.add(LetterGroup(
      id: '${idPrefix}_${i + 1}',
      label: '${slice.first.label}-${slice.last.label}',
      items: slice,
    ));
    start += size;
  }
  return groups;
}