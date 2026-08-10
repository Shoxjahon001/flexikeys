library aac_home_screen;

import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
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
class AacHomeScreen extends StatefulWidget {
  const AacHomeScreen({super.key});

  @override
  State<AacHomeScreen> createState() => _AacHomeScreenState();
}

class _AacHomeScreenState extends State<AacHomeScreen> {
  AacLanguage _language = AacLanguage.en;

  static const Map<String, String> _title = {'en': 'My Voice', 'uz': 'Mening Ovozim', 'ru': 'Мой Голос'};

  // Mockup order: Daily, Feelings, Needs, People, Places — not the
  // AacCategory enum's declaration order (Daily, Needs, Feelings, ...).
  static const List<AacCategory> _homeCategories = [
    AacCategory.dailyActivities,
    AacCategory.feelings,
    AacCategory.needs,
    AacCategory.people,
    AacCategory.places,
  ];

  static const Map<AacCategory, Map<String, String>> _categoryLabels = {
    AacCategory.dailyActivities: {'en': 'Daily', 'uz': 'Kunlik ishlar', 'ru': 'Повседневные'},
    AacCategory.needs: {'en': 'Needs', 'uz': 'Ehtiyojlar', 'ru': 'Потребности'},
    AacCategory.feelings: {'en': 'Feelings', 'uz': "His-tuyg'ular", 'ru': 'Чувства'},
    AacCategory.people: {'en': 'People', 'uz': 'Odamlar', 'ru': 'Люди'},
    AacCategory.places: {'en': 'Places', 'uz': 'Joylar', 'ru': 'Места'},
  };

  static const Map<String, String> _myCardsLabel = {
    'en': 'My Cards',
    'uz': 'Mening kartochkalarim',
    'ru': 'Мои карточки',
  };

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

  String _categoryLabel(AacCategory category) =>
      _categoryLabels[category]?[_language.code] ??
      _categoryLabels[category]?['en'] ??
      category.name;

  void _openCategory(AacCategory category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AacCardGridScreen(
          category: category,
          categoryLabel: _categoryLabel(category),
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
    final myCardsLabel = _myCardsLabel[_language.code] ?? _myCardsLabel['en']!;

    return Scaffold(
      backgroundColor: aac.background,
      appBar: FkAppBar(
        title: _title[_language.code] ?? _title['en']!,
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
                ..._homeCategories.map((category) {
                  return AacCategoryTile(
                    category: category,
                    label: _categoryLabel(category),
                    glyph: aacGlyph(emojiForCategory(category)),
                    onTap: () => _openCategory(category),
                  );
                }),
                // "My Cards" isn't a real AacCategory, so there's no
                // aac.colorFor/tintFor entry for it — reuses Play's accent
                // (the category this tile visually replaces on Home) purely
                // for color, matching the mockup's 6th-tile pink without
                // adding a new color mapping for a non-vocabulary tile.
                AacCategoryTile(
                  category: AacCategory.play,
                  label: myCardsLabel,
                  glyph: aacGlyph('🗂️'),
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
