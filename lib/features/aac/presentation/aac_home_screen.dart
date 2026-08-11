library aac_home_screen;

import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/user_service.dart';
import '../domain/aac_card_def.dart';
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
/// The screen title, category names, and "My Cards" label are UI CHROME —
/// they follow the app's interface language (AppLocalizations), same as
/// every other screen, and update immediately when it changes. This is
/// deliberately different from the actual vocabulary CARDS inside each
/// category (Water, Help, Happy, ...), which stay on the independent
/// LEARNING language ([_language] below) per CLAUDE.md's "UI language and
/// learning language are independent settings" — a category folder name
/// is navigation furniture, not curriculum content to be learned.
class AacHomeScreen extends StatefulWidget {
  const AacHomeScreen({super.key});

  @override
  State<AacHomeScreen> createState() => _AacHomeScreenState();
}

class _AacHomeScreenState extends State<AacHomeScreen> {
  AacLanguage _language = AacLanguage.en;

  // Mockup order: Daily, Feelings, Needs, People, Places — not the
  // AacCategory enum's declaration order (Daily, Needs, Feelings, ...).
  static const List<AacCategory> _homeCategories = [
    AacCategory.dailyActivities,
    AacCategory.feelings,
    AacCategory.needs,
    AacCategory.people,
    AacCategory.places,
  ];

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final code = await UserService.getLanguage();
    final lang = AacLanguage.values.firstWhere(
      (l) => l.code == code,
      orElse: () => AacLanguage.en,
    );
    if (mounted) setState(() => _language = lang);
  }

  String _categoryLabel(AacCategory category, AppLocalizations t) =>
      switch (category) {
        AacCategory.dailyActivities => t.aacCategoryDaily,
        AacCategory.needs => t.aacCategoryNeeds,
        AacCategory.feelings => t.aacCategoryFeelings,
        AacCategory.people => t.aacCategoryPeople,
        AacCategory.places => t.aacCategoryPlaces,
        AacCategory.play => category.name,
      };

  void _openCategory(AacCategory category, AppLocalizations t) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AacCardGridScreen(
          category: category,
          categoryLabel: _categoryLabel(category, t),
          language: _language,
        ),
      ),
    );
  }

  /// Same parent gate the main app shell already uses for Profile
  /// (main_shell.dart) — a child tapping "My Cards" must not reach the
  /// create/edit/delete form directly.
  void _openMyCards() {
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
                    onTap: () => _openCategory(category, t),
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
                  onTap: _openMyCards,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
