library reward_models;

/// Mirrors the backend CatalogItemOut schema.
class CatalogItem {
  final String id;
  final String kind;
  final String slug;
  final int? costCoins;
  final Map<String, dynamic>? unlockRule;
  final bool owned;

  const CatalogItem({
    required this.id,
    required this.kind,
    required this.slug,
    this.costCoins,
    this.unlockRule,
    required this.owned,
  });

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    return CatalogItem(
      id: json['id'] as String,
      kind: json['kind'] as String,
      slug: json['slug'] as String,
      costCoins: json['cost_coins'] as int?,
      unlockRule: json['unlock_rule'] as Map<String, dynamic>?,
      owned: (json['owned'] as bool?) ?? false,
    );
  }

  bool get isFree => costCoins == null || costCoins == 0;
  bool get isAccessory => kind == 'accessory';
  bool get isBadge => kind == 'badge';
  bool get isWorld => kind == 'world';
}

/// Wallet balance.
class Wallet {
  final int coins;
  final int stars;

  const Wallet({required this.coins, required this.stars});

  const Wallet.empty() : coins = 0, stars = 0;

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      coins: (json['coins'] as num?)?.toInt() ?? 0,
      stars: (json['stars'] as num?)?.toInt() ?? 0,
    );
  }

  Wallet withCoins(int delta) => Wallet(coins: coins + delta, stars: stars);
  Wallet withStars(int delta) => Wallet(coins: coins, stars: stars + delta);
}

/// The result of a successful redeem.
class RedeemResult {
  final String rewardId;
  final String slug;
  final String kind;

  const RedeemResult({
    required this.rewardId,
    required this.slug,
    required this.kind,
  });

  factory RedeemResult.fromJson(Map<String, dynamic> json) {
    return RedeemResult(
      rewardId: json['reward_id'] as String,
      slug: json['slug'] as String,
      kind: json['kind'] as String,
    );
  }
}

/// State held by [RewardsNotifier].
class RewardsState {
  final Wallet wallet;
  final List<CatalogItem> catalog;
  final bool loading;
  final String? error;

  const RewardsState({
    this.wallet = const Wallet.empty(),
    this.catalog = const [],
    this.loading = false,
    this.error,
  });

  RewardsState copyWith({
    Wallet? wallet,
    List<CatalogItem>? catalog,
    bool? loading,
    String? error,
  }) {
    return RewardsState(
      wallet: wallet ?? this.wallet,
      catalog: catalog ?? this.catalog,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}