library auth_controller;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/secure_token_store.dart';
import '../../../services/progress/progress_repository.dart';
import '../../../services/sync/sync_service.dart';
import '../../../services/telemetry/telemetry_service.dart';
import '../domain/auth_models.dart';

enum AuthStatus {
  bootstrapping,
  unauthenticated,
  authenticatedNoChild,
  authenticatedWithChild,
}

class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final List<ChildProfile> children;
  final ChildProfile? activeChild;
  final bool loading;
  final String? error;

  const AuthState({
    this.status = AuthStatus.bootstrapping,
    this.user,
    this.children = const [],
    this.activeChild,
    this.loading = false,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    List<ChildProfile>? children,
    ChildProfile? activeChild,
    bool? loading,
    String? error,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        children: children ?? this.children,
        activeChild: activeChild ?? this.activeChild,
        loading: loading ?? this.loading,
        error: error,
      );
}

class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(const AuthState()) {
    _bootstrap();
  }

  final ApiClient _api = ApiClient.instance;
  final SecureTokenStore _store = SecureTokenStore.instance;

  Future<void> _bootstrap() async {
    if (!await _store.hasParentSession()) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }
    try {
      final resp = await _api.get('/me');
      if (resp.statusCode != 200) {
        // Server actively rejected the session (expired/invalid) — clear it.
        await _store.clearAll();
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return;
      }
      final user = AppUser.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
      await loadChildren();
      state = state.copyWith(user: user);
      await _restoreActiveChild();
    } catch (_) {
      // Network unreachable (offline, backend down, wrong host on a
      // physical device, etc.) — this is not the same as an invalid
      // session, so keep the stored tokens for next launch instead of
      // signing the user out. The child-facing app still works locally;
      // only parent/AI-dashboard features stay unavailable this session.
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> _restoreActiveChild() async {
    final childId = await _store.getActiveChildId();
    if (childId == null) {
      state = state.copyWith(status: AuthStatus.authenticatedNoChild);
      return;
    }
    ChildProfile? child;
    for (final c in state.children) {
      if (c.id == childId) child = c;
    }
    if (child == null) {
      state = state.copyWith(status: AuthStatus.authenticatedNoChild);
      return;
    }
    await selectChild(child);
  }

  Future<bool> register(String email, String password, {String locale = 'en'}) {
    return _authenticate(
      '/auth/register',
      {'email': email, 'password': password, 'role': 'parent', 'locale': locale},
    );
  }

  Future<bool> login(String email, String password) {
    return _authenticate('/auth/login', {'email': email, 'password': password});
  }

  Future<bool> _authenticate(String path, Map<String, dynamic> body) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final resp = await _api.post(path, body: body);
      if (resp.statusCode != 200 && resp.statusCode != 201) {
        state = state.copyWith(loading: false, error: _errorFrom(resp));
        return false;
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      await _store.setSession(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
      );
      final meResp = await _api.get('/me');
      final user = AppUser.fromJson(jsonDecode(meResp.body) as Map<String, dynamic>);
      await loadChildren();
      state = state.copyWith(
        status: AuthStatus.authenticatedNoChild,
        user: user,
        loading: false,
      );
      return true;
    } catch (_) {
      state = state.copyWith(loading: false, error: 'network_error');
      return false;
    }
  }

  String _errorFrom(dynamic resp) {
    try {
      final data = jsonDecode(resp.body as String) as Map<String, dynamic>;
      return (data['detail'] as String?) ?? 'unknown_error';
    } catch (_) {
      return 'unknown_error';
    }
  }

  Future<void> loadChildren() async {
    final resp = await _api.get('/children');
    if (resp.statusCode != 200) return;
    final list = jsonDecode(resp.body) as List<dynamic>;
    state = state.copyWith(
      children: list.cast<Map<String, dynamic>>().map(ChildProfile.fromJson).toList(),
    );
  }

  Future<ChildProfile?> createChild(ChildCreateData data) async {
    final resp = await _api.post('/children', body: data.toJson());
    if (resp.statusCode != 201) {
      state = state.copyWith(error: _errorFrom(resp));
      return null;
    }
    final child = ChildProfile.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
    await loadChildren();
    // Parent explicitly created the profile just now — record required consents.
    await _api.post(
      '/children/${child.id}/consent',
      body: {'consent_type': 'coppa_parent_consent'},
    );
    await _api.post(
      '/children/${child.id}/consent',
      body: {'consent_type': 'data_processing'},
    );
    return child;
  }

  Future<bool> selectChild(ChildProfile child) async {
    final resp = await _api.post('/children/${child.id}/session');
    if (resp.statusCode != 200) {
      state = state.copyWith(error: _errorFrom(resp));
      return false;
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    await _store.setActiveChildId(child.id);
    await _store.setChildToken(data['child_token'] as String);

    await SyncService.instance.init(childId: child.id, language: child.learningLanguage);
    await TelemetryService.instance.init(childId: child.id, language: child.learningLanguage);
    // Fire-and-forget: reconcile local game progress with the backend now
    // that a child session is active. Never blocks entering gameplay.
    unawaited(ProgressRepository.instance.sync());

    state = state.copyWith(
      status: AuthStatus.authenticatedWithChild,
      activeChild: child,
    );
    return true;
  }

  Future<void> switchChild() async {
    await TelemetryService.instance.dispose();
    await _store.clearChildSelection();
    state = state.copyWith(
      status: AuthStatus.authenticatedNoChild,
      activeChild: null,
    );
  }

  Future<void> logout() async {
    await TelemetryService.instance.dispose();
    final refreshToken = await _store.getRefreshToken();
    if (refreshToken != null) {
      try {
        await _api.post('/auth/logout', body: {'refresh_token': refreshToken});
      } catch (_) {
        // Best-effort — proceed with local sign-out regardless.
      }
    }
    await _store.clearAll();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (_) => AuthController(),
);
