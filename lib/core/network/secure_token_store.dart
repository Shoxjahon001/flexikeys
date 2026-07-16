library secure_token_store;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage for auth tokens.
///
/// Refresh tokens and child-session tokens must never live in
/// SharedPreferences (child data privacy — see CLAUDE.md).
class SecureTokenStore {
  SecureTokenStore._();
  static final SecureTokenStore instance = SecureTokenStore._();

  static const _storage = FlutterSecureStorage();

  static const _kAccessToken = 'auth_access_token';
  static const _kRefreshToken = 'auth_refresh_token';
  static const _kActiveChildId = 'auth_active_child_id';
  static const _kChildToken = 'auth_child_token';

  Future<String?> getAccessToken() => _storage.read(key: _kAccessToken);
  Future<String?> getRefreshToken() => _storage.read(key: _kRefreshToken);
  Future<String?> getActiveChildId() => _storage.read(key: _kActiveChildId);
  Future<String?> getChildToken() => _storage.read(key: _kChildToken);

  Future<void> setAccessToken(String value) =>
      _storage.write(key: _kAccessToken, value: value);
  Future<void> setRefreshToken(String value) =>
      _storage.write(key: _kRefreshToken, value: value);
  Future<void> setActiveChildId(String value) =>
      _storage.write(key: _kActiveChildId, value: value);
  Future<void> setChildToken(String value) =>
      _storage.write(key: _kChildToken, value: value);

  Future<void> setSession({
    required String accessToken,
    required String refreshToken,
  }) async {
    await setAccessToken(accessToken);
    await setRefreshToken(refreshToken);
  }

  Future<bool> hasParentSession() async =>
      (await getAccessToken()) != null && (await getRefreshToken()) != null;

  Future<void> clearChildSelection() async {
    await _storage.delete(key: _kActiveChildId);
    await _storage.delete(key: _kChildToken);
  }

  Future<void> clearAll() => _storage.deleteAll();
}
