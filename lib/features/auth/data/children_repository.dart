library children_repository;

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../core/network/api_client.dart';
import '../domain/auth_models.dart';

/// Supabase-backed CRUD for child profiles under the current parent.
///
/// Also mirrors each created child into the FastAPI backend's own
/// `children` table (same id) — that backend still owns child-session
/// minting, consent records, adaptive engine data, AAC and telemetry, all
/// keyed by a local child row. See CLAUDE.md's adaptive-engine notes.
class ChildrenRepository {
  ChildrenRepository._();
  static final ChildrenRepository instance = ChildrenRepository._();

  final sb.SupabaseClient _client = sb.Supabase.instance.client;

  Future<List<ChildProfile>> list() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final rows = await _client
        .from('children')
        .select()
        .eq('parent_id', userId)
        .order('created_at');
    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(ChildProfile.fromJson)
        .toList();
  }

  Future<ChildProfile> create(ChildCreateData data) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Not authenticated');
    }
    final row = await _client
        .from('children')
        .insert({
          'parent_id': userId,
          'display_name': data.displayName,
          'learning_language': data.learningLanguage,
          'ui_language': data.uiLanguage,
          if (data.birthYear != null) 'birth_year': data.birthYear,
          if (data.avatarId != null) 'avatar_id': data.avatarId,
        })
        .select()
        .single();
    final child = ChildProfile.fromJson(row);

    await ApiClient.instance.post('/children', body: {
      ...data.toJson(),
      'id': child.id,
    });
    await ApiClient.instance.post(
      '/children/${child.id}/consent',
      body: {'consent_type': 'coppa_parent_consent'},
    );
    await ApiClient.instance.post(
      '/children/${child.id}/consent',
      body: {'consent_type': 'data_processing'},
    );

    return child;
  }
}
