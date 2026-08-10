library aac_home_screen;

import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../../services/user_service.dart';
import '../domain/aac_card_def.dart';
import 'aac_card_grid_screen.dart';
import 'aac_glyphs.dart';

/// "My Voice" Category Home — docs/aac_design_system.md §2.1/§3. The only
/// screen that shows all six category accents at once, by design (it *is*
/// the category picker). Six categories = the hard ceiling, not a starting
/// point.
class AacHomeScreen extends StatefulWidget {
  const AacHomeScreen({super.key});

  @override
  State<AacHomeScreen> createState() => _AacHomeScreenState();
}

class _AacHomeScreenState extends State<AacHomeScreen> {
  AacLanguage _language = AacLanguage.en;

  static const Map<String, String> _title = {'en': 'My Voice', 'uz': 'Mening Ovozim', 'ru': 'Мой Голос'};

  static const Map<AacCategory, Map<String, String>> _categoryLabels = {
    AacCategory.dailyActivities: {'en': 'Daily', 'uz': 'Kunlik ishlar', 'ru': 'Повседневные'},
    AacCategory.needs: {'en': 'Needs', 'uz': 'Ehtiyojlar', 'ru': 'Потребности'},
    AacCategory.feelings: {'en': 'Feelings', 'uz': "His-tuyg'ular", 'ru': 'Чувства'},
    AacCategory.people: {'en': 'People', 'uz': 'Odamlar', 'ru': 'Люди'},
    AacCategory.places: {'en': 'Places', 'uz': 'Joylar', 'ru': 'Места'},
    AacCategory.play: {'en': 'Play', 'uz': "O'yin", 'ru': 'Игра'},
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

  @override
  Widget build(BuildContext context) {
    final aac = AacTheme.of(context);

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
              children: AacCategory.values.map((category) {
                return AacCategoryTile(
                  category: category,
                  label: _categoryLabel(category),
                  glyph: aacGlyph(emojiForCategory(category)),
                  onTap: () => _openCategory(category),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
