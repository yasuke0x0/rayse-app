import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../community/models/community_video.dart';
import '../../community/providers/community_provider.dart';
import '../../community/repository/community_video_repository.dart';
import '../models/challenge.dart';
import '../repository/challenge_repository.dart';

// Tier of a weekly challenge (derived from the linked skill's tier).
enum ChallengeTier { beginner, intermediate, advanced }

// User-selected tier in the multi-tier challenges view. Null = use the user's
// derived tier (highest mastered tier).
final selectedChallengeTierProvider =
    StateProvider<ChallengeTier?>((ref) => null);

final challengeRepositoryProvider =
    Provider<ChallengeRepository>((_) => ChallengeRepository());

// Admin: full challenge list (more than the user-facing limit)
final adminChallengesProvider = FutureProvider<List<Challenge>>((ref) async {
  return ref.read(challengeRepositoryProvider).fetchAllChallenges();
});

final challengesProvider = StreamProvider<List<Challenge>>((ref) {
  return Supabase.instance.client
      .from('challenges')
      .stream(primaryKey: ['id']).map((rows) {
    final challenges = rows
        .map((m) => Challenge.fromJson(Map<String, dynamic>.from(m)))
        .toList()
      ..sort((a, b) {
        final yearCmp = b.weekYear.compareTo(a.weekYear);
        return yearCmp != 0 ? yearCmp : b.weekNumber.compareTo(a.weekNumber);
      });
    return challenges;
  });
});

// Current week's active challenge
final activeChallengeProvider = Provider<Challenge?>((ref) {
  final challenges = ref.watch(challengesProvider).valueOrNull ?? [];
  final now = DateTime.now().toUtc();
  final week = CommunityVideoRepository.isoWeek(now);
  final year = now.year;
  return challenges
      .where((c) => c.weekNumber == week && c.weekYear == year)
      .firstOrNull;
});

// Leaderboard = approved community videos for that skill+week
final challengeLeaderboardProvider =
    FutureProvider.family<List<CommunityVideo>, String>(
        (ref, challengeId) async {
  final challenges = ref.watch(challengesProvider).valueOrNull ?? [];
  final challenge = challenges.where((c) => c.id == challengeId).firstOrNull;
  if (challenge == null) return [];
  return ref.read(communityVideoRepositoryProvider).fetchTopVideosForSkill(
        skillId: challenge.skillId,
        weekNumber: challenge.weekNumber,
        weekYear: challenge.weekYear,
        limit: 50,
      );
});

// Has the current user submitted a video for this challenge's skill+week?
final hasSubmittedChallengeProvider =
    FutureProvider.family<bool, String>((ref, challengeId) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return false;
  final challenges = ref.watch(challengesProvider).valueOrNull ?? [];
  final challenge = challenges.where((c) => c.id == challengeId).firstOrNull;
  if (challenge == null) return false;
  final myVideos = await ref
      .read(communityVideoRepositoryProvider)
      .fetchMyVideos(userId, challenge.skillId);
  return myVideos.any((v) =>
      v.isChallenge &&
      v.weekNumber == challenge.weekNumber &&
      v.weekYear == challenge.weekYear);
});

// Participant count for a challenge
final challengeParticipantCountProvider =
    FutureProvider.family<int, String>((ref, challengeId) async {
  final challenges = ref.watch(challengesProvider).valueOrNull ?? [];
  final challenge = challenges.where((c) => c.id == challengeId).firstOrNull;
  if (challenge == null) return 0;
  return ref.read(challengeRepositoryProvider).fetchParticipantCount(
        skillId: challenge.skillId,
        weekNumber: challenge.weekNumber,
        weekYear: challenge.weekYear,
      );
});

// The current user's placement in a challenge.
// Null = not entered or no approved video. Returns 1-indexed rank.
final myChallengePlacementProvider =
    FutureProvider.family<int?, String>((ref, challengeId) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return null;
  final leaderboard =
      await ref.watch(challengeLeaderboardProvider(challengeId).future);
  if (leaderboard.isEmpty) return null;
  final idx = leaderboard.indexWhere((v) => v.userId == userId);
  return idx == -1 ? null : idx + 1;
});

// The current user's aggregate challenge stats.
class MyChallengeStats {
  final int joined;
  final int totalFires;
  final int? bestPlacement; // null if no approved videos yet

  const MyChallengeStats({
    required this.joined,
    required this.totalFires,
    required this.bestPlacement,
  });
}

final myChallengeStatsProvider =
    FutureProvider<MyChallengeStats>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) {
    return const MyChallengeStats(
        joined: 0, totalFires: 0, bestPlacement: null);
  }

  final allVideos = await ref.watch(myAllVideosProvider.future);
  final challengeVideos = allVideos.where((v) => v.isChallenge).toList();

  // Joined = distinct (skill_id, week, year) tuples
  final joinedKeys = challengeVideos
      .map((v) => '${v.skillId}-${v.weekNumber}-${v.weekYear}')
      .toSet();

  // Fires = sum of scores on approved videos
  final totalFires = challengeVideos
      .where((v) => v.status == VideoStatus.approved)
      .fold<int>(0, (sum, v) => sum + v.score);

  // Best placement: scan known challenges for ones the user entered, fetch leaderboards
  final challenges = ref.watch(challengesProvider).valueOrNull ?? [];
  int? bestPlacement;
  final futures = <Future<int?>>[];
  for (final challenge in challenges) {
    final entered = challengeVideos.any((v) =>
        v.skillId == challenge.skillId &&
        v.weekNumber == challenge.weekNumber &&
        v.weekYear == challenge.weekYear &&
        v.status == VideoStatus.approved);
    if (!entered) continue;
    futures.add(
      ref.watch(challengeLeaderboardProvider(challenge.id).future).then(
        (leaderboard) {
          final idx = leaderboard.indexWhere((v) => v.userId == userId);
          return idx == -1 ? null : idx + 1;
        },
      ),
    );
  }
  final placements = await Future.wait(futures);
  for (final p in placements) {
    if (p == null) continue;
    if (bestPlacement == null || p < bestPlacement) bestPlacement = p;
  }

  return MyChallengeStats(
    joined: joinedKeys.length,
    totalFires: totalFires,
    bestPlacement: bestPlacement,
  );
});
