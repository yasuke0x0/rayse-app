import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../community/models/community_video.dart';
import '../../community/providers/community_provider.dart';
import '../../community/repository/community_video_repository.dart';
import '../models/challenge.dart';
import '../repository/challenge_repository.dart';

final challengeRepositoryProvider =
    Provider<ChallengeRepository>((_) => ChallengeRepository());

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
