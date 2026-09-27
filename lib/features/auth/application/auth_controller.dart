library auth_controller;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../core/network/api_client.dart';
import '../../../core/network/secure_token_store.dart';
import '../../../services/progress/progress_repository.dart';
import '../../../services/sync/sync_service.dart';
import '../../../services/telemetry/telemetry_service.dart';
import '../data/children_repository.dart';
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

  final sb.SupabaseClient _supabase = sb.Supabase.instance.client;
  final SecureTokenStore _store = SecureTokenStore.instance;
  final ChildrenRepository _childrenRepo = ChildrenRepository.instance;

  Future<void> _bootstrap() async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }
    try {
      final user = await _fetchProfile(session.user.id);
      await loadChildren();
      state = state.copyWith(user: user);
      await _restoreActiveChild();
    } catch (_) {
      // Network unreachable (offline, Supabase down, etc.) — this is not
      // the same as an invalid session, so keep it for next launch instead
      // of signing the user out. The child-facing app still works locally;
      // only parent/AI-dashboard features stay unavailable this session.
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<AppUser> _fetchProfile(String userId) async {
    final row = await _supabase.from('profiles').select().eq('id', userId).single();
    return AppUser.fromJson(row);
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

  Future<bool> register(String email, String password, {String locale = 'en'}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final resp = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'locale': locale},
      );
      if (resp.session == null || resp.user == null) {
        // Supabase project has "Confirm email" enabled — the account was
        // created but can't be used until the parent verifies their email.
        state = state.copyWith(loading: false, error: 'email_confirmation_required');
        return false;
      }
      final user = await _fetchProfile(resp.user!.id);
      await loadChildren();
      state = state.copyWith(
        status: AuthStatus.authenticatedNoChild,
        user: user,
        loading: false,
      );
      return true;
    } on sb.AuthException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(loading: false, error: 'network_error');
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final resp = await _supabase.auth.signInWithPassword(email: email, password: password);
      if (resp.user == null) {
        state = state.copyWith(loading: false, error: 'unknown_error');
        return false;
      }
      final user = await _fetchProfile(resp.user!.id);
      await loadChildren();
      state = state.copyWith(
        status: AuthStatus.authenticatedNoChild,
        user: user,
        loading: false,
      );
      return true;
    } on sb.AuthException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
      return false;
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
    try {
      final list = await _childrenRepo.list();
      state = state.copyWith(children: list);
    } catch (_) {
      // Offline — keep whatever children are already cached in state.
    }
  }

  Future<ChildProfile?> createChild(ChildCreateData data) async {
    try {
      final child = await _childrenRepo.create(data);
      await loadChildren();
      return child;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<bool> selectChild(ChildProfile child) async {
    // Backend still mints a short-lived child-session token (see
    // ApiClient/TokenKind.childSession) for adaptive/AAC/telemetry calls —
    // now authorized by the Supabase parent access token instead of the
    // old FastAPI-issued one.
    final resp = await ApiClient.instance.post('/children/${child.id}/session');
    if (resp.statusCode != 200) {
      state = state.copyWith(error: _errorFrom(resp));
      return false;
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    await _store.setActiveChildId(child.id);
    await _store.setChildToken(data['child_token'] as String);

    await SyncService.instance.init(childId: child.id, language: child.learningLanguage);
    await TelemetryService.instance.init(childId: child.id, language: child.learningLanguage);
    // Fire-and-forget: reconcile local game progress with Supabase now that
    // a child session is active. Never blocks entering gameplay.
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
    try {
      await _supabase.auth.signOut();
    } catch (_) {
      // Best-effort — proceed with local sign-out regardless.
    }
    await _store.clearAll();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (_) => AuthController(),
);
