import '../data/mock_challenges.dart';
import '../models/challenge.dart';
import '../models/leaderboard_entry.dart';

class ChallengeRepository {
  Future<List<Challenge>> getChallenges() async {
    // TODO: replace with Supabase query
    // return supabase.from('challenges').select().then(...)
    await Future.delayed(const Duration(milliseconds: 300));
    return mockChallenges;
  }

  Future<List<LeaderboardEntry>> getLeaderboard(String challengeId) async {
    // TODO: replace with Supabase query
    await Future.delayed(const Duration(milliseconds: 200));
    return mockLeaderboard;
  }

  Future<void> joinChallenge(String challengeId, String userId) async {
    // TODO: upsert into challenge_participants
  }

  Future<void> submitEntry({
    required String challengeId,
    required String userId,
    required int score,
  }) async {
    // TODO: upsert into challenge_entries
  }
}
