library rewards_provider;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/reward_models.dart';

const _walletCacheKey = 'rewards_wallet_v1';
const _catalogCacheKey = 'rewards_catalog_v1';

/// Riverpod notifier for wallet + catalog state.
///
/// Coins/stars are granted **optimistically** on item completion so the
/// child sees the reward immediately. Server reconciliation happens on
/// next online sync — server wins, but never claws back visibly.
class RewardsNotifier extends StateNotifier<RewardsState> {
  RewardsNotifier() : super(const RewardsState()) {
    _loadFromCache();
  }

  String? _endpointBase;
  String? _authToken;

  void init({required String endpointBase, required String authToken}) {
    _endpointBase = endpointBase;
    _authToken = authToken;
  }

  // ── Optimistic local operations ───────────────────────────────────────────

  /// Grant coins immediately (optimistic, synced later).
  Future<void> earnOptimistic({required int coins, required int stars}) async {
    state = state.copyWith(
      wallet: state.wallet
          .withCoins(coins)
          .withStars(stars),
    );
    await _persistWalletCache();
  }

  // ── Remote operations ─────────────────────────────────────────────────────

  Future<void> loadWallet() async {
    if (_endpointBase == null) return;
    try {
      final resp = await http
          .get(
            Uri.parse('$_endpointBase/rewards/wallet'),
            headers: _authHeaders,
          )
          .timeout(const Duration(seconds: 5));

      if (resp.statusCode == 200) {
        final wallet = Wallet.fromJson(
          jsonDecode(resp.body) as Map<String, dynamic>,
        );
        state = state.copyWith(wallet: wallet);
        await _persistWalletCache();
      }
    } catch (_) {
      // Remain on cached / optimistic balance
    }
  }

  Future<void> loadCatalog() async {
    state = state.copyWith(loading: true, error: null);
    if (_endpointBase == null) {
      state = state.copyWith(loading: false);
      return;
    }
    try {
      final resp = await http
          .get(
            Uri.parse('$_endpointBase/rewards/catalog'),
            headers: _authHeaders,
          )
          .timeout(const Duration(seconds: 5));

      if (resp.statusCode == 200) {
        final items = (jsonDecode(resp.body) as List)
            .map((e) => CatalogItem.fromJson(e as Map<String, dynamic>))
            .toList();
        state = state.copyWith(catalog: items, loading: false);
        await _persistCatalogCache();
      } else {
        state = state.copyWith(loading: false, error: 'catalog_load_failed');
      }
    } catch (_) {
      state = state.copyWith(loading: false);
      await _loadCatalogFromCache();
    }
  }

  /// Redeem a shop item. Returns null on failure.
  Future<RedeemResult?> redeem(String rewardId) async {
    if (_endpointBase == null) return null;
    try {
      final resp = await http
          .post(
            Uri.parse('$_endpointBase/rewards/$rewardId/redeem'),
            headers: {
              ..._authHeaders,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'child_id': ''}), // child_id from JWT claims
          )
          .timeout(const Duration(seconds: 8));

      if (resp.statusCode == 200) {
        final result = RedeemResult.fromJson(
          jsonDecode(resp.body) as Map<String, dynamic>,
        );
        // Deduct coins locally
        final item = state.catalog.where((c) => c.id == rewardId).firstOrNull;
        if (item?.costCoins != null) {
          state = state.copyWith(
            wallet: state.wallet.withCoins(-(item!.costCoins!)),
          );
        }
        // Refresh catalog to show owned = true
        await loadCatalog();
        return result;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Cache ─────────────────────────────────────────────────────────────────

  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final walletRaw = prefs.getString(_walletCacheKey);
    final catalogRaw = prefs.getString(_catalogCacheKey);

    if (walletRaw != null) {
      try {
        final wallet = Wallet.fromJson(
          jsonDecode(walletRaw) as Map<String, dynamic>,
        );
        state = state.copyWith(wallet: wallet);
      } catch (_) {}
    }

    if (catalogRaw != null) {
      try {
        final items = (jsonDecode(catalogRaw) as List)
            .map((e) => CatalogItem.fromJson(e as Map<String, dynamic>))
            .toList();
        state = state.copyWith(catalog: items);
      } catch (_) {}
    }
  }

  Future<void> _loadCatalogFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_catalogCacheKey);
    if (raw == null) return;
    try {
      final items = (jsonDecode(raw) as List)
          .map((e) => CatalogItem.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(catalog: items);
    } catch (_) {}
  }

  Future<void> _persistWalletCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _walletCacheKey,
      jsonEncode({'coins': state.wallet.coins, 'stars': state.wallet.stars}),
    );
  }

  Future<void> _persistCatalogCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _catalogCacheKey,
      jsonEncode(
        state.catalog
            .map((c) => {
                  'id': c.id,
                  'kind': c.kind,
                  'slug': c.slug,
                  'cost_coins': c.costCoins,
                  'unlock_rule': c.unlockRule,
                  'owned': c.owned,
                })
            .toList(),
      ),
    );
  }

  Map<String, String> get _authHeaders => {
        'Authorization': 'Bearer ${_authToken ?? ''}',
        'Accept': 'application/json',
      };
}

final rewardsProvider =
    StateNotifierProvider<RewardsNotifier, RewardsState>(
  (_) => RewardsNotifier(),
);