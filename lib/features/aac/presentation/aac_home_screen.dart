library aac_home_screen;

import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../../l10n/app_localizations.dart';
import 'aac_card_grid_screen.dart';
import 'aac_glyphs.dart';
import 'parent/aac_card_manager_screen.dart';

/// "My Voice" Category Home — docs/aac_design_system.md §2.1/§3. Pixel-
/// matched to the reference mockup: 5 vocabulary categories in the
/// mockup's exact order (Daily/Feelings/Needs/People/Places) plus a 6th
/// "My Cards" tile — a navigation shortcut into the existing parent-gated
/// card manager, not a 6th vocabulary category. `AacCategory.play` (Ball/
/// Drawing/Music/Tablet/Book/Toy) is unchanged in the data model — its
/// content isn't deleted, it's just not one of the 6 home tiles anymore,
/// matching what the mockup actually shows. Six tiles = the hard ceiling,
/// not a starting point.
///
/// The screen title, category names, "My Cards" label, AND the vocabulary
/// language of the categories themselves all follow the app's interface
/// language now (see [aacLanguageOf]) — AAC is a communication tool, not
/// curriculum, so its output must match the language of the person the
/// child is talking to. This reverses an earlier decision where AAC
/// content followed the separate curriculum learning language; see
/// CLAUDE.md "AAC voice follows UI language" for the full reasoning.
class AacHomeScreen extends StatelessWidget {
  const AacHomeScreen({super.key});

  // Mockup order: Daily, Feelings, Needs, People, Places — not the
  // AacCategory enum's declaration order (Daily, Needs, Feelings, ...).
  static const List<AacCategory> _homeCategories = [
    AacCategory.dailyActivities,
    AacCategory.feelings,
    AacCategory.needs,
    AacCategory.people,
    AacCategory.places,
  ];

  String _categoryLabel(AacCategory category, AppLocalizations t) =>
      switch (category) {
        AacCategory.dailyActivities => t.aacCategoryDaily,
        AacCategory.needs => t.aacCategoryNeeds,
        AacCategory.feelings => t.aacCategoryFeelings,
        AacCategory.people => t.aacCategoryPeople,
        AacCategory.places => t.aacCategoryPlaces,
        AacCategory.play => category.name,
      };

  void _openCategory(BuildContext context, AacCategory category, AppLocalizations t) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AacCardGridScreen(
          category: category,
          categoryLabel: _categoryLabel(category, t),
        ),
      ),
    );
  }

  /// Same parent gate the main app shell already uses for Profile
  /// (main_shell.dart) — a child tapping "My Cards" must not reach the
  /// create/edit/delete form directly.
  void _openMyCards(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FkParentGate(
          onUnlocked: () {},
          child: const AacCardManagerScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aac = AacTheme.of(context);
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: aac.background,
      appBar: FkAppBar(
        title: t.navVoiceTab,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Wrap(
              spacing: AacSizes.gridGapAdvanced,
              runSpacing: AacSizes.gridGapAdvanced,
              alignment: WrapAlignment.center,
              children: [
                // Glyph sized proportionally to the tile (default
                // AacCategoryTile.size = AacSizes.cardMax = 160) — aacGlyph's
                // own default (56) doesn't scale with the tile, so it read
                // small/sparse inside the much bigger accent-colored area.
                ..._homeCategories.map((category) {
                  return AacCategoryTile(
                    category: category,
                    label: _categoryLabel(category, t),
                    glyph: aacGlyph(emojiForCategory(category),
                        size: AacSizes.cardMax * 0.5),
                    onTap: () => _openCategory(context, category, t),
                  );
                }),
                // "My Cards" isn't a real AacCategory, so there's no
                // aac.colorFor/tintFor entry for it — reuses Play's accent
                // (the category this tile visually replaces on Home) purely
                // for color, matching the mockup's 6th-tile pink without
                // adding a new color mapping for a non-vocabulary tile.
                AacCategoryTile(
                  category: AacCategory.play,
                  label: t.aacMyCardsLabel,
                  glyph: aacGlyph('🗂️', size: AacSizes.cardMax * 0.5),
                  onTap: () => _openMyCards(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
