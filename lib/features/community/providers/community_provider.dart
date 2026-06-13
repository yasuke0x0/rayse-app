import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repository/community_video_repository.dart';
import '../models/community_video.dart';

final communityVideoRepositoryProvider = Provider<CommunityVideoRepository>(
  (_) => CommunityVideoRepository(),
);

// Profile of the current user
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

// Pending videos for admin panel — AsyncNotifier so we can refresh
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
