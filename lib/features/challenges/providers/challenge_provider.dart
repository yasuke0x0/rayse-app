import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/challenge.dart';
import '../models/leaderboard_entry.dart';
import '../repository/challenge_repository.dart';

final challengeRepositoryProvider =
    Provider<ChallengeRepository>((_) => ChallengeRepository());

final challengesProvider = FutureProvider<List<Challenge>>((ref) {
  return ref.read(challengeRepositoryProvider).getChallenges();
});

final leaderboardProvider =
    FutureProvider.family<List<LeaderboardEntry>, String>((ref, challengeId) {
  return ref.read(challengeRepositoryProvider).getLeaderboard(challengeId);
});

// Tracks which challenge IDs the user has joined locally (until Supabase wired)
final joinedChallengesProvider =
    NotifierProvider<JoinedChallengesNotifier, Set<String>>(
        JoinedChallengesNotifier.new);

class JoinedChallengesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void join(String challengeId) => state = {...state, challengeId};
}
