library secure_token_store;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage for the child-session token and which child is active.
///
/// The parent's own session is now owned entirely by the Supabase SDK
/// (`Supabase.instance.client.auth`), which persists and refreshes it
/// itself. This store only keeps what Supabase doesn't know about: the
/// FastAPI-issued child-session token (see `ApiClient`/`TokenKind`) and the
/// locally active child id — must never live in SharedPreferences (child
/// data privacy — see CLAUDE.md).
class SecureTokenStore {
  SecureTokenStore._();
  static final SecureTokenStore instance = SecureTokenStore._();

  static const _storage = FlutterSecureStorage();

  static const _kActiveChildId = 'auth_active_child_id';
  static const _kChildToken = 'auth_child_token';

  Future<String?> getActiveChildId() => _storage.read(key: _kActiveChildId);
  Future<String?> getChildToken() => _storage.read(key: _kChildToken);

  Future<void> setActiveChildId(String value) =>
      _storage.write(key: _kActiveChildId, value: value);
  Future<void> setChildToken(String value) =>
      _storage.write(key: _kChildToken, value: value);

  Future<void> clearChildSelection() async {
    await _storage.delete(key: _kActiveChildId);
    await _storage.delete(key: _kChildToken);
  }

  Future<void> clearAll() => _storage.deleteAll();
}
