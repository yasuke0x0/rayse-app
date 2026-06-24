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
}
