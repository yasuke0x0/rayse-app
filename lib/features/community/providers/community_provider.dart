import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repository/community_video_repository.dart';
import '../repository/user_repository.dart';
import '../models/community_video.dart';

final communityVideoRepositoryProvider = Provider<CommunityVideoRepository>(
  (_) => CommunityVideoRepository(),
);

// ─── Profile of the current user ──────────────────────────────────────────────

final profileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return null;
  final data = await Supabase.instance.client
      .from('profiles')
      .select()
      .eq('id', userId)
      .maybeSingle();
  return data;
});

// Is the current user a creator (Samy)?
final isCreatorProvider = FutureProvider<bool>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  return profile?['is_creator'] == true;
});

// ─── Pending videos for admin panel ───────────────────────────────────────────

class PendingVideosNotifier extends AsyncNotifier<List<CommunityVideo>> {
  @override
  Future<List<CommunityVideo>> build() async {
    return ref.read(communityVideoRepositoryProvider).fetchPendingVideos();
  }

  Future<void> approve(String id, {bool samyApproved = false}) async {
    await ref
        .read(communityVideoRepositoryProvider)
        .approveVideo(id, samyApproved: samyApproved);
    ref.invalidateSelf();
  }

  Future<void> reject(String id) async {
    await ref.read(communityVideoRepositoryProvider).rejectVideo(id);
    ref.invalidateSelf();
  }
}

final pendingVideosProvider =
    AsyncNotifierProvider<PendingVideosNotifier, List<CommunityVideo>>(
  PendingVideosNotifier.new,
);

// ─── User management (admin) ──────────────────────────────────────────────────

final userRepositoryProvider = Provider<UserRepository>(
  (_) => UserRepository(),
);

class AllUsersNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    return ref.read(userRepositoryProvider).fetchAllUsers();
  }

  Future<void> updateRole(
    String userId, {
    bool? isPremium,
    bool? isCreator,
  }) async {
    await ref
        .read(userRepositoryProvider)
        .updateUserRole(userId, isPremium: isPremium, isCreator: isCreator);
    ref.invalidateSelf();
  }

  Future<void> ban(String userId) async {
    await ref.read(userRepositoryProvider).banUser(userId);
    ref.invalidateSelf();
  }

  Future<void> unban(String userId) async {
    await ref.read(userRepositoryProvider).unbanUser(userId);
    ref.invalidateSelf();
  }
}

final allUsersProvider =
    AsyncNotifierProvider<AllUsersNotifier, List<Map<String, dynamic>>>(
  AllUsersNotifier.new,
);

// User videos for admin detail view (all statuses)
final adminUserVideosProvider =
    FutureProvider.family<List<CommunityVideo>, String>((ref, userId) async {
  return ref.read(userRepositoryProvider).fetchUserVideos(userId);
});

// User XP for admin detail view
final adminUserXPProvider =
    FutureProvider.family<int, String>((ref, userId) async {
  return ref.read(userRepositoryProvider).fetchUserXP(userId);
});

// ─── My total submissions count ───────────────────────────────────────────────

final myTotalSubmissionsProvider = FutureProvider<int>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return 0;
  return ref
      .read(communityVideoRepositoryProvider)
      .fetchMyTotalSubmissions(userId);
});

// ─── My submissions for a specific skill ──────────────────────────────────────

final mySkillVideosProvider =
    FutureProvider.family<List<CommunityVideo>, String>((ref, skillId) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];
  return ref
      .read(communityVideoRepositoryProvider)
      .fetchMyVideos(userId, skillId);
});

// ─── Top 3 community videos for a skill this week ─────────────────────────────

final topSkillVideosProvider =
    FutureProvider.family<List<CommunityVideo>, String>((ref, skillId) async {
  final now = DateTime.now().toUtc();
  return ref.read(communityVideoRepositoryProvider).fetchTopVideosForSkill(
        skillId: skillId,
        weekNumber: CommunityVideoRepository.isoWeek(now),
        weekYear: now.year,
      );
});

// ─── Approved videos (family by week) ─────────────────────────────────────────

class ApprovedVideosNotifier
    extends FamilyAsyncNotifier<List<CommunityVideo>, (int, int)> {
  @override
  Future<List<CommunityVideo>> build((int, int) arg) async {
    final (weekNumber, weekYear) = arg;
    return ref
        .read(communityVideoRepositoryProvider)
        .fetchApprovedVideos(weekNumber: weekNumber, weekYear: weekYear);
  }

  void updateScore(String videoId, bool reacted) {
    state.whenData((videos) {
      state = AsyncData([
        for (final v in videos)
          if (v.id == videoId)
            v.copyWith(score: (v.score + (reacted ? 1 : -1)).clamp(0, 9999))
          else
            v,
      ]);
    });
  }
}

final approvedVideosProvider = AsyncNotifierProvider.family<
    ApprovedVideosNotifier, List<CommunityVideo>, (int, int)>(
  ApprovedVideosNotifier.new,
);

// ─── My reactions (video IDs I've fired) ──────────────────────────────────────

class MyReactionsNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return {};
    return ref
        .read(communityVideoRepositoryProvider)
        .fetchMyReactions(userId);
  }

  Future<void> toggle(String videoId, (int, int) weekKey) async {
    final current = state.valueOrNull ?? {};
    final adding = !current.contains(videoId);

    // Optimistic updates
    state = AsyncData(
      adding
          ? {...current, videoId}
          : current.where((id) => id != videoId).toSet(),
    );
    ref.read(approvedVideosProvider(weekKey).notifier).updateScore(videoId, adding);

    try {
      await ref
          .read(communityVideoRepositoryProvider)
          .toggleReaction(videoId);
    } catch (_) {
      // Revert
      state = AsyncData(current);
      ref
          .read(approvedVideosProvider(weekKey).notifier)
          .updateScore(videoId, !adding);
    }
  }
}

final myReactionsProvider =
    AsyncNotifierProvider<MyReactionsNotifier, Set<String>>(
  MyReactionsNotifier.new,
);
