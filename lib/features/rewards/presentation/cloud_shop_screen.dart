library cloud_shop_screen;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../application/rewards_provider.dart';
import '../domain/reward_models.dart';

/// Cloud Shop — the earnable reward store.
/// Nothing is purchasable with real money; all items are earned through play.
class CloudShopScreen extends ConsumerStatefulWidget {
  const CloudShopScreen({super.key});

  @override
  ConsumerState<CloudShopScreen> createState() => _CloudShopScreenState();
}

class _CloudShopScreenState extends ConsumerState<CloudShopScreen> {
  bool _celebrating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rewardsProvider.notifier).loadCatalog();
    });
  }

  Future<void> _redeem(CatalogItem item) async {
    if (item.owned) return;

    final notifier = ref.read(rewardsProvider.notifier);
    final result = await notifier.redeem(item.id);

    if (result != null && mounted) {
      setState(() => _celebrating = true);
      ref
          .read(mascotControllerProvider.notifier)
          .onLessonEvent(LessonEvent.levelComplete);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _celebrating = false);
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough coins')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rewardsState = ref.watch(rewardsProvider);

    return Scaffold(
      backgroundColor: FkColors.background,
      appBar: AppBar(
        backgroundColor: FkColors.background,
        elevation: 0,
        title: const Text('Cloud Shop', style: FkTextStyles.childHeadline),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: FkSpacing.sm),
            child: FkCoinCounter(value: rewardsState.wallet.coins),
          ),
        ],
      ),
      body: Stack(
        children: [
          rewardsState.loading
              ? const Center(child: CircularProgressIndicator())
              : _CatalogGrid(
                  items: rewardsState.catalog,
                  wallet: rewardsState.wallet,
                  onRedeem: _redeem,
                ),
          if (_celebrating)
            const Positioned.fill(
              child: _CelebrationOverlay(),
            ),
        ],
      ),
    );
  }
}

class _CatalogGrid extends StatelessWidget {
  final List<CatalogItem> items;
  final Wallet wallet;
  final void Function(CatalogItem) onRedeem;

  const _CatalogGrid({
    required this.items,
    required this.wallet,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'More items coming soon!',
          style: FkTextStyles.childBody,
        ),
      );
    }

    final accessories = items.where((i) => i.isAccessory).toList();
    final worlds = items.where((i) => i.isWorld).toList();
    final badges = items.where((i) => i.isBadge).toList();
    final others = items
        .where((i) => !i.isAccessory && !i.isWorld && !i.isBadge)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(FkSpacing.md),
      children: [
        if (accessories.isNotEmpty) ...[
          const _SectionHeader(title: 'Accessories'),
          _ItemGrid(items: accessories, wallet: wallet, onRedeem: onRedeem),
        ],
        if (worlds.isNotEmpty) ...[
          const _SectionHeader(title: 'Worlds'),
          _ItemGrid(items: worlds, wallet: wallet, onRedeem: onRedeem),
        ],
        if (others.isNotEmpty)
          _ItemGrid(items: others, wallet: wallet, onRedeem: onRedeem),
        if (badges.isNotEmpty) ...[
          const _SectionHeader(title: 'Badges'),
          _BadgeRow(badges: badges),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: FkSpacing.md,
        bottom: FkSpacing.xs,
      ),
      child: Text(title, style: FkTextStyles.childLabel),
    );
  }
}

class _ItemGrid extends StatelessWidget {
  final List<CatalogItem> items;
  final Wallet wallet;
  final void Function(CatalogItem) onRedeem;

  const _ItemGrid({
    required this.items,
    required this.wallet,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: FkSpacing.sm,
        mainAxisSpacing: FkSpacing.sm,
        childAspectRatio: 0.9,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _ShopItemCard(
        item: items[i],
        canAfford: wallet.coins >= (items[i].costCoins ?? 0),
        onRedeem: onRedeem,
      ),
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  final CatalogItem item;
  final bool canAfford;
  final void Function(CatalogItem) onRedeem;

  const _ShopItemCard({
    required this.item,
    required this.canAfford,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    return FkCard(
      child: Padding(
        padding: const EdgeInsets.all(FkSpacing.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Item icon placeholder
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: item.owned
                    ? FkColors.mint.withValues(alpha: 0.4)
                    : FkColors.lavender.withValues(alpha: 0.4),
                borderRadius: FkRadii.mdAll,
              ),
              child: Icon(
                item.owned ? Icons.check_circle_rounded : Icons.star_rounded,
                size: 36,
                color: item.owned ? FkColors.mint : FkColors.lavender,
              ),
            ),
            Text(
              _label(item.slug),
              style: FkTextStyles.childBody,
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
            if (item.owned)
              const Text('Owned', style: FkTextStyles.adultCaption)
            else if (item.isFree)
              const Text('Earn by playing',
                  style: FkTextStyles.adultCaption,
                  textAlign: TextAlign.center)
            else
              FkButton(
                label: '${item.costCoins} coins',
                onPressed: canAfford ? () => onRedeem(item) : null,
                size: FkButtonSize.adult,
              ),
          ],
        ),
      ),
    );
  }

  String _label(String slug) {
    return slug
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

class _BadgeRow extends StatelessWidget {
  final List<CatalogItem> badges;
  const _BadgeRow({required this.badges});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: badges.length,
        separatorBuilder: (_, __) => const SizedBox(width: FkSpacing.sm),
        itemBuilder: (_, i) {
          final badge = badges[i];
          return Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: badge.owned
                      ? FkColors.warmYellow.withValues(alpha: 0.5)
                      : FkColors.disabled.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.emoji_events_rounded,
                  size: 32,
                  color: badge.owned ? FkColors.warmYellow : FkColors.disabled,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _label(badge.slug),
                style: FkTextStyles.adultCaption,
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }

  String _label(String slug) {
    return slug
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

class _CelebrationOverlay extends StatelessWidget {
  const _CelebrationOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FkStarBurst(active: true),
            const SizedBox(height: FkSpacing.md),
            Text(
              'You got it!',
              style: FkTextStyles.childHeadline
                  .copyWith(color: FkColors.warmYellow),
            ),
          ],
        ),
      ),
    );
  }
}