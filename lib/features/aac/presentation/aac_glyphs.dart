library aac_glyphs;

import 'dart:io';

import 'package:flutter/material.dart';

import '../../../design_system/aac/aac_theme.dart';
import '../../../design_system/fk_tokens.dart';
import '../domain/aac_card_def.dart';

/// Emoji glyph for every starter-vocabulary card and fringe option, keyed
/// by [AacCardDef.id]/[AacFringeOption.id]. Placeholder for the real
/// per-card illustration/Lottie asset — see [AacCard.glyph] doc comment.
/// Falls back to a neutral speech-bubble glyph for any id not listed here
/// (e.g. a future parent-authored custom card with no photo yet).
const Map<String, String> _cardEmoji = {
  // Daily activities
  'da_eat': '🍽️',
  'da_toilet': '🚽',
  'da_drink': '🥤',
  'da_brush_teeth': '🪥',
  'da_wash_hands': '🧼',
  'da_bath': '🛁',
  'da_sleep': '😴',
  // Needs
  'ne_water': '💧',
  'ne_help': '🤲',
  'ne_food': '🍲',
  'ne_food_apple': '🍎',
  'ne_food_banana': '🍌',
  'ne_food_bread': '🍞',
  'ne_food_rice': '🍚',
  'ne_hug': '🤗',
  'ne_blanket': '🧣',
  'ne_medicine': '💊',
  'ne_break': '⏸️',
  // Feelings
  'fe_pain': '🤕',
  'fe_pain_head': '🤕',
  'fe_pain_stomach': '🤢',
  'fe_pain_tooth': '🦷',
  'fe_pain_leg': '🦵',
  'fe_happy': '😄',
  'fe_sad': '😢',
  'fe_angry': '😠',
  'fe_scared': '😨',
  'fe_tired': '🥱',
  // People
  'pe_mom': '👩',
  'pe_dad': '👨',
  'pe_teacher': '🧑‍🏫',
  'pe_grandma': '👵',
  'pe_doctor': '🧑‍⚕️',
  // Places
  'pl_bathroom': '🚿',
  'pl_outside': '🌳',
  'pl_kitchen': '🍳',
  'pl_bedroom': '🛏️',
  'pl_school': '🏫',
  'pl_hospital': '🏥',
  // Play
  'pa_ball': '⚽',
  'pa_drawing': '🖍️',
  'pa_music': '🎵',
  'pa_tablet': '📱',
  'pa_book': '📖',
  'pa_toy': '🧸',
};

const String _fallbackEmoji = '💬';

const Map<AacCategory, String> _categoryEmoji = {
  AacCategory.dailyActivities: '🪥',
  AacCategory.needs: '🤲',
  AacCategory.feelings: '😊',
  AacCategory.people: '👪',
  AacCategory.places: '🏡',
  AacCategory.play: '🧸',
};

/// The emoji glyph for a vocabulary/fringe card id.
String emojiForCard(String id) => _cardEmoji[id] ?? _fallbackEmoji;

/// The emoji glyph for a Category Home tile.
String emojiForCategory(AacCategory category) =>
    _categoryEmoji[category] ?? _fallbackEmoji;

/// Wraps an emoji string as the [Widget] expected by [AacCard.glyph] /
/// [AacCategoryTile.glyph].
Widget aacGlyph(String emoji, {double size = 56}) =>
    Text(emoji, style: TextStyle(fontSize: size));

/// The glyph widget for an [AacCardDef] — a parent-provided photo
/// (`customPhotoPath`, Phase 4 Card Manager) when the card has one, the
/// emoji placeholder otherwise. Every card-rendering child/confirmation
/// screen should use this rather than `aacGlyph(emojiForCard(card.id))`
/// directly, so a custom card's own photo actually shows up wherever that
/// card appears.
Widget glyphForCard(AacCardDef card, {double size = 56}) {
  final path = card.customPhotoPath;
  if (path == null) return aacGlyph(emojiForCard(card.id), size: size);
  return ClipRRect(
    borderRadius: BorderRadius.circular(FkRadii.xs),
    child: Image.file(
      File(path),
      width: size * 1.4,
      height: size * 1.4,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => aacGlyph(emojiForCard(card.id), size: size),
    ),
  );
}
