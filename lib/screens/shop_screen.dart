import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/user_service.dart';

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

  int _stars = 0;
  List<String> _owned = ['dino'];
  String _name = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stars = await UserService.getStars();
    final owned = await UserService.getOwnedItems();
    final name = await UserService.getName();
    if (mounted) {
      setState(() {
        _stars = stars;
        _owned = owned;
        _name = name;
      });
    }
  }

  Future<void> _buy(ShopItem item) async {
    final ok = await UserService.spendStars(item.price);
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Not enough stars!',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          backgroundColor: const Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    await UserService.addOwnedItem(item.id);
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
              'Shop',
              style: GoogleFonts.nunito(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                  child: const Center(
                      child: Text('☁️', style: TextStyle(fontSize: 26))),
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
                Text(
                  '$_stars',
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
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
            child: Center(
              child: Text(item.emoji, style: const TextStyle(fontSize: 64)),
            ),
          ),
          GestureDetector(
            onTap: owned ? null : () => _buy(item),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: owned ? const Color(0xFF52C96A) : AppTheme.buttonBlue,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Center(
                child: Text(
                  owned ? 'owned' : '${item.price}⭐',
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
