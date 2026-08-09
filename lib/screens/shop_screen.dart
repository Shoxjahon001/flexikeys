import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../services/user_service.dart';
import '../services/tts_service.dart';
import '../design_system/fk_tokens.dart';

class ShopItem {
  final String id;
  final String emoji;
  final int price;
  ShopItem(this.id, this.emoji, this.price);
}

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final _items = [
    ShopItem('dino', '🦕', 50),
    ShopItem('fries', '🍟', 50),
    ShopItem('star', '⭐', 50),
    ShopItem('bunny', '🐰', 50),
    ShopItem('bear', '🧸', 50),
    ShopItem('icecream', '🍦', 50),
    ShopItem('robot', '🤖', 50),
    ShopItem('rainbow', '🌈', 50),
  ];

  List<String> _owned = ['dino'];
  String _selected = 'dino';
  String _name = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final owned = await UserService.getOwnedItems();
    final selected = await UserService.getSelectedItem();
    final name = await UserService.getName();
    if (mounted) {
      setState(() {
        _owned = owned;
        _selected = selected;
        _name = name;
      });
    }
  }

  /// Switch the active avatar back to an already-owned item — no stars
  /// spent, just re-equipping something bought earlier.
  Future<void> _equip(ShopItem item) async {
    await UserService.setSelectedItem(item.id);
    if (!mounted) return;
    setState(() => _selected = item.id);
  }

  Future<void> _buy(ShopItem item) async {
    final ok = await UserService.spendStars(item.price);
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.notEnoughStarsSnackbar,
              style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w700, color: FkColors.ink)),
          backgroundColor: FkColors.attention,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    await UserService.addOwnedItem(item.id);
    await UserService.setSelectedItem(item.id);
    if (!mounted) return;
    TtsService.instance.speakFunny(AppLocalizations.of(context)!.gotItPraise);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: appGradientBg,
      child: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Text(
              AppLocalizations.of(context)!.shopTitle,
              style: GoogleFonts.nunito(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: _items.length,
                itemBuilder: (context, i) => _buildCard(_items[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFD6E8), Color(0xFFD6C8FF)],
                    ),
                  ),
                  child: ValueListenableBuilder<String>(
                    valueListenable: UserService.avatarNotifier,
                    builder: (_, emoji, __) => Center(
                        child:
                            Text(emoji, style: const TextStyle(fontSize: 26))),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _name,
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: UserService.starsNotifier,
                  builder: (_, stars, __) => Text(
                    '$stars',
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.star_rounded,
                    color: AppTheme.starYellow, size: 26),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(ShopItem item) {
    final owned = _owned.contains(item.id);
    final selected = _selected == item.id;

    // Three states: not owned yet (buy), owned but not worn (tap to equip),
    // owned and currently worn (shown as active, nothing to do).
    final t = AppLocalizations.of(context)!;
    final Color barColor =
        selected ? const Color(0xFF52C96A) : AppTheme.buttonBlue;
    final String label = selected
        ? t.itemSelectedLabel
        : owned
            ? t.itemEquipLabel
            : '${item.price}⭐';
    final VoidCallback? onTap =
        selected ? null : (owned ? () => _equip(item) : () => _buy(item));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: selected
            ? Border.all(color: const Color(0xFF52C96A), width: 2.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Center(
                  child: Text(item.emoji, style: const TextStyle(fontSize: 64)),
                ),
                if (selected)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(Icons.check_circle_rounded,
                        color: Color(0xFF52C96A), size: 22),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
