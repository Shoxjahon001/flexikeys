library api_client;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'secure_token_store.dart';

/// Base URL convention already used by `parent_provider.dart` /
/// `teacher_provider.dart` — override at build time with
/// `--dart-define=API_BASE_URL=...`.
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000/api/v1',
);

/// Which bearer token a request should carry. Parent-role endpoints
/// (/children, parent dashboards, teacher dashboards, AAC, telemetry,
/// adaptive sync) use the parent's Supabase access token — this backend
/// verifies it directly rather than issuing its own; child-facing endpoints
/// (adaptive, sessions) use the short-lived, backend-issued child-session
/// token.
enum TokenKind { parentAccess, childSession }

/// Thin wrapper around [http.Client] that attaches the right bearer token
/// and retries once on 401 — refreshing the Supabase session, or reissuing
/// the child-session token via `/children/{id}/session`, before retrying.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  final http.Client _client = http.Client();
  final SecureTokenStore _store = SecureTokenStore.instance;

  Uri _uri(String path) => Uri.parse('$kApiBaseUrl$path');

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<http.Response> get(
    String path, {
    TokenKind auth = TokenKind.parentAccess,
  }) {
    return _sendAuthed(
      auth,
      (token) => _client
          .get(_uri(path), headers: _headers(token))
          .timeout(const Duration(seconds: 10)),
    );
  }

  Future<http.Response> post(
    String path, {
    TokenKind auth = TokenKind.parentAccess,
    Object? body,
  }) {
    return _sendAuthed(
      auth,
      (token) => _client
          .post(
            _uri(path),
            headers: _headers(token),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 10)),
    );
  }

  Future<http.Response> patch(
    String path, {
    TokenKind auth = TokenKind.parentAccess,
    Object? body,
  }) {
    return _sendAuthed(
      auth,
      (token) => _client
          .patch(
            _uri(path),
            headers: _headers(token),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 10)),
    );
  }

  Future<http.Response> put(
    String path, {
    TokenKind auth = TokenKind.parentAccess,
    Object? body,
  }) {
    return _sendAuthed(
      auth,
      (token) => _client
          .put(
            _uri(path),
            headers: _headers(token),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 10)),
    );
  }

  Future<http.Response> _sendAuthed(
    TokenKind kind,
    Future<http.Response> Function(String? token) send,
  ) async {
    final token = await _tokenFor(kind);
    final resp = await send(token);
    if (resp.statusCode != 401) return resp;

    final refreshed = await _refresh(kind);
    if (!refreshed) return resp;

    return send(await _tokenFor(kind));
  }

  Future<String?> _tokenFor(TokenKind kind) {
    switch (kind) {
      case TokenKind.parentAccess:
        return Future.value(sb.Supabase.instance.client.auth.currentSession?.accessToken);
      case TokenKind.childSession:
        return _store.getChildToken();
    }
  }

  Future<bool> _refresh(TokenKind kind) {
    switch (kind) {
      case TokenKind.parentAccess:
        return _refreshParentAccess();
      case TokenKind.childSession:
        return _refreshChildSession();
    }
  }

  /// The Supabase SDK already refreshes proactively before expiry; a 401
  /// here usually means the session was revoked elsewhere. Ask it to
  /// refresh once — if that fails, there's nothing more this client can do.
  Future<bool> _refreshParentAccess() async {
    try {
      final resp = await sb.Supabase.instance.client.auth.refreshSession();
      return resp.session != null;
    } catch (_) {
      return false;
    }
  }

  /// Child-session tokens are reissued by the parent access token, so this
  /// falls back to refreshing the parent session first if needed.
  Future<bool> _refreshChildSession() async {
    final childId = await _store.getActiveChildId();
    if (childId == null) return false;

    try {
      var resp = await _postChildSession(childId, await _tokenFor(TokenKind.parentAccess));
      if (resp.statusCode == 401) {
        if (!await _refreshParentAccess()) return false;
        resp = await _postChildSession(childId, await _tokenFor(TokenKind.parentAccess));
      }
      if (resp.statusCode != 200) return false;

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      await _store.setChildToken(data['child_token'] as String);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<http.Response> _postChildSession(String childId, String? parentToken) {
    return _client
        .post(_uri('/children/$childId/session'), headers: _headers(parentToken))
        .timeout(const Duration(seconds: 10));
  }
}
