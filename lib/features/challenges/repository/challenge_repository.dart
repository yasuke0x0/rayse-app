import '../../../core/services/supabase_service.dart';
import '../models/challenge.dart';

class ChallengeRepository {
  final _client = SupabaseService.client;

  Future<List<Challenge>> fetchChallenges() async {
    final data = await _client
        .from('challenges')
        .select()
        .order('week_year', ascending: false)
        .order('week_number', ascending: false)
        .limit(10);
    return (data as List)
        .map((m) => Challenge.fromJson(Map<String, dynamic>.from(m as Map)))
        .toList();
  }

  Future<int> fetchParticipantCount({
    required String skillId,
    required int weekNumber,
    required int weekYear,
  }) async {
    final data = await _client
        .from('community_videos')
        .select('id')
        .eq('is_challenge', true)
        .eq('skill_id', skillId)
        .eq('week_number', weekNumber)
        .eq('week_year', weekYear);
    return (data as List).length;
  }

  Future<List<Challenge>> fetchAllChallenges({int limit = 200}) async {
    final data = await _client
        .from('challenges')
        .select()
        .order('week_year', ascending: false)
        .order('week_number', ascending: false)
        .limit(limit);
    return (data as List)
        .map((m) => Challenge.fromJson(Map<String, dynamic>.from(m as Map)))
        .toList();
  }

  Future<void> createChallenge({
    required String skillId,
    required String title,
    required String description,
    required int weekNumber,
    required int weekYear,
    required int xpReward,
  }) async {
    await _client.from('challenges').insert({
      'skill_id': skillId,
      'title': title,
      'description': description,
      'week_number': weekNumber,
      'week_year': weekYear,
      'xp_reward': xpReward,
    });
  }

  Future<void> updateChallenge({
    required String id,
    required String skillId,
    required String title,
    required String description,
    required int weekNumber,
    required int weekYear,
    required int xpReward,
  }) async {
    await _client.from('challenges').update({
      'skill_id': skillId,
      'title': title,
      'description': description,
      'week_number': weekNumber,
      'week_year': weekYear,
      'xp_reward': xpReward,
    }).eq('id', id);
  }

  Future<void> deleteChallenge(String id) async {
    await _client.from('challenges').delete().eq('id', id);
  }

  // Admin-only: awards top 3 XP bonus + notifications, marks finalized
  Future<void> finalizeChallenge(String id) async {
    await _client.rpc('finalize_challenge', params: {'p_challenge_id': id});
  }

  // Fetch a single challenge by id (for deep-linking from notifications)
  Future<Challenge?> fetchChallengeById(String id) async {
    final data = await _client
        .from('challenges')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return Challenge.fromJson(Map<String, dynamic>.from(data));
  }
}
