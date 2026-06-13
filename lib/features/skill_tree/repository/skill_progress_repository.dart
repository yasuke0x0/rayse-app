import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';

class SkillProgressRepository {
  final SupabaseClient _client = SupabaseService.client;

  Future<List<Map<String, dynamic>>> fetchProgress(String userId) async {
    final data = await _client
        .from('user_skill_progress')
        .select('skill_id, sessions_completed, status')
        .eq('user_id', userId);
    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<void> upsertProgress({
    required String userId,
    required String skillId,
    required int sessionsCompleted,
    required String status,
  }) async {
    await _client.from('user_skill_progress').upsert(
      {
        'user_id': userId,
        'skill_id': skillId,
        'sessions_completed': sessionsCompleted,
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id,skill_id',
    );
  }

  Future<int> fetchXP(String userId) async {
    final data = await _client
        .from('user_xp')
        .select('total_xp')
        .eq('user_id', userId)
        .maybeSingle();
    return (data?['total_xp'] as int?) ?? 0;
  }

  Future<void> upsertXP({
    required String userId,
    required int totalXP,
  }) async {
    await _client.from('user_xp').upsert(
      {
        'user_id': userId,
        'total_xp': totalXP,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id',
    );
  }
}
